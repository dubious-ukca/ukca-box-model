#!/usr/bin/env python3
"""Generate ukca_internal_dump_mod: dumps of the internal UKCA config and state.

The generated module reads UKCA's own record of how it is configured and what
it is about to run on, and writes it with box_dump_mod. It never wraps or
replaces UKCA API calls: a box model driver keeps calling UKCA exactly as
before and adds a few dump calls alongside, guarded by ukca_dump_on():

    call ukca_setup(...)
    call photol_setup(...)
    if (ukca_dump_on()) call dump_ukca_internal_config()

    call ukca_set_environment(...)      ! however many calls
    if (ukca_dump_on()) call dump_ukca_step_in(<ukca_step inputs>)
    call ukca_step(...)
    if (ukca_dump_on()) call dump_ukca_step_out(tracer_data, ntp_data)

dump_ukca_step_in takes the same arguments as the ukca_step call it precedes
(except the error and diagnostic arguments).

Dumping is switched on at run time by the environment variable UKCA_DUMP_FILE
(see box_dump_mod). What is dumped:

  ukca_config        every value returned by ukca_get_config (values UKCA does
                     not set are dumped as the NOT_SET values below)
  photol_config      every value returned by photol_get_config
  ukca_constants     public variables of ukca_config_constants_mod
  photol_constants   public variables of photol_constants_mod
  ukca_varlists      tracer, NTP and environment field names, in UKCA order
  ukca_environment   public variables of ukca_environment_fields_mod, i.e.
                     every environment field exactly as ukca_step will see it
  ukca_step:in       every ukca_step input (tracers, NTP, times, levels)
  ukca_step:out      the tracer and NTP arrays returned by ukca_step

The variable lists are read from the UKCA source, so regenerate after any
UKCA upgrade:

    tools/gen_ukca_internal_dump.py --ukca-src ukca/src --out-dir src
"""

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

MAX_LINE = 79   # fortitude S001 (line-length = 80) allows 79
MODULE = "ukca_internal_dump_mod"

# Supported ranks for each type (must match the specifics in box_dump_mod).
SUPPORTED_RANKS = {
    "real": range(0, 5),
    "integer": range(0, 4),
    "logical": range(0, 4),
    "character": range(0, 2),
}

# Values given to every get_config output before the call, so that any output
# UKCA does not set (e.g. fastjx_prescutoff in ukca_get_config at um13.9) is
# dumped identically by every build instead of as uninitialised memory. The
# integer value is the same for 4- and 8-byte default integers.
NOT_SET = {
    "real": "-huge({name})",
    "integer": "-2147483647",
    "logical": ".false.",
}

# Arguments of the get_config routines that are not configuration values.
ERROR_ARGS = {"error_code", "error_message", "error_routine"}


@dataclass
class Var:
    name: str
    type: str          # real / integer / logical / character
    attrs: list        # e.g. ["ALLOCATABLE", "OPTIONAL", "INTENT(OUT)"]
    dims: str          # e.g. "(:)" or ""

    def has(self, attr):
        return any(a.upper().replace(" ", "") == attr for a in self.attrs)

    @property
    def rank(self):
        return 0 if not self.dims else len(split_top(self.dims[1:-1]))

    @property
    def allocatable(self):
        return self.has("ALLOCATABLE")

    @property
    def pointer(self):
        return self.has("POINTER")


# -----------------------------------------------------------------------------
# Fortran parsing (just enough for UKCA's declaration style)
# -----------------------------------------------------------------------------

def strip_comment(line):
    """Remove a trailing ! comment, ignoring ! inside quotes."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == "!":
            return line[:i]
    return line


def statements(text):
    """Yield complete (continuation-joined, comment-free) statements."""
    buf = ""
    for raw in text.splitlines():
        line = strip_comment(raw).rstrip()
        if not line.strip():
            continue
        stripped = line.lstrip()
        if buf and stripped.startswith("&"):
            stripped = stripped[1:]
        if stripped.endswith("&"):
            buf += stripped[:-1] + " "
            continue
        yield (buf + stripped).strip()
        buf = ""


def split_top(text):
    """Split on commas that are not inside parentheses."""
    parts, depth, cur = [], 0, ""
    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


DECL_RE = re.compile(
    r"^(INTEGER|REAL|LOGICAL|CHARACTER)\s*(\([^:]*?\))?\s*((?:,[^:]*)?)::(.*)$",
    re.I)


def parse_decl(stmt):
    """Return [Var, ...] for a type declaration statement, else []."""
    m = DECL_RE.match(stmt)
    if not m:
        return []
    typ, _, attrs, entities = m.groups()
    attrs = [a.strip() for a in split_top(attrs.lstrip(","))]
    out = []
    for ent in split_top(entities):
        em = re.match(r"([A-Za-z_]\w*)\s*(\([^=]*\))?\s*(=.*)?$", ent)
        if em:
            out.append(Var(em.group(1).lower(), typ.lower(), attrs,
                           (em.group(2) or "").replace(" ", "")))
    return out


def routine_args(path, name):
    """Dummy arguments of SUBROUTINE name, in argument order."""
    stmts = list(statements(Path(path).read_text()))
    start = next((i for i, s in enumerate(stmts)
                  if re.match(rf"SUBROUTINE\s+{name}\s*\(", s, re.I)), None)
    if start is None:
        sys.exit(f"SUBROUTINE {name} not found in {path}")
    names = [a.strip().lower() for a in
             re.search(r"\((.*)\)", stmts[start]).group(1).split(",")]
    decls = {}
    for s in stmts[start + 1:]:
        if re.match(rf"END\s+SUBROUTINE\s+{name}\b", s, re.I):
            break
        for v in parse_decl(s):
            if v.name in names:
                decls[v.name] = v
    missing = [n for n in names if n not in decls]
    if missing:
        sys.exit(f"{name}: no declaration found for {missing}")
    return [decls[n] for n in names]


def public_module_vars(path):
    """Public, non-PARAMETER variables declared in a module's spec part."""
    default_public = True
    explicit = {}
    found = []
    in_type = False
    for s in statements(Path(path).read_text()):
        u = s.upper()
        if re.match(r"CONTAINS\b", u) or re.match(r"END\s+MODULE\b", u):
            break
        if re.match(r"TYPE\s*(,|::|\s+[A-Z_])", u) and "(" not in u.split(
                "::")[0].replace("TYPE,", ""):
            in_type = True
        if in_type:
            if re.match(r"END\s*TYPE\b", u):
                in_type = False
            continue
        if u in ("PUBLIC", "PRIVATE"):
            default_public = (u == "PUBLIC")
            continue
        m = re.match(r"(PUBLIC|PRIVATE)\s*(::)?\s*([A-Z_].*)$", u)
        if m and not DECL_RE.match(s):
            for n in split_top(m.group(3)):
                explicit[n.strip().lower()] = (m.group(1) == "PUBLIC")
            continue
        for v in parse_decl(s):
            if not v.has("PARAMETER"):
                found.append(v)
    out = []
    for v in found:
        if v.has("PUBLIC"):
            public = True
        elif v.has("PRIVATE"):
            public = False
        else:
            public = explicit.get(v.name, default_public)
        if public:
            check_rank(v, path)
            out.append(v)
    return out


def check_rank(v, where):
    if v.rank not in SUPPORTED_RANKS[v.type]:
        sys.exit(f"{where}: {v.name} is {v.type} rank {v.rank}, which "
                 "box_dump_mod does not support")


# -----------------------------------------------------------------------------
# Code generation
# -----------------------------------------------------------------------------

def item_list(first, items, indent, last=""):
    """'first &' then one item per line, comma-separated, ending with last."""
    pad = " " * indent
    lines = [f"{first}&"]
    for i, item in enumerate(items):
        if i < len(items) - 1:
            lines.append(f"{pad}{item}, &")
        else:
            lines.append(f"{pad}{item}{last}")
    return lines


def fit(line):
    """Break a too-long 'call x(a, b)' line after its first argument."""
    if len(line) <= MAX_LINE:
        return [line]
    indent = len(line) - len(line.lstrip())
    head, rest = line.split(", ", 1)
    return [f"{head}, &", " " * (indent + 2) + rest]


def dump_var(v, ind, name=None):
    """Lines dumping one variable, guarding ALLOCATED / ASSOCIATED."""
    lines = []
    for line in _dump_var(v, ind, name):
        lines += fit(line)
    return lines


def _dump_var(v, ind, name=None):
    pad = " " * ind
    label = f"'{name or v.name}'"
    call = f"call dump({label}, {v.name})"
    if v.allocatable or v.pointer:
        test = "allocated" if v.allocatable else "associated"
        marker = "<unallocated>" if v.allocatable else "<unassociated>"
        return [pad + l for l in [
            f"if ({test}({v.name})) then",
            f"  {call}",
            "else",
            f"  call dump_marker({label}, '{marker}')",
            "end if"]]
    return [pad + call]


def local_decl(v):
    """Declaration of a local to receive an INTENT(OUT) argument."""
    attrs = [a for a in v.attrs
             if not re.match(r"(OPTIONAL|INTENT|TARGET)", a, re.I)]
    spec = v.type + ("".join(f", {a.lower()}" for a in attrs))
    return f"    {spec} :: {v.name}{v.dims}"


def gen_get_config(sub, api_module, routine, args):
    """Subroutine calling a get_config routine and dumping every output."""
    values = [a for a in args if a.name not in ERROR_ARGS]
    for a in values:
        check_rank(a, routine)
    has_error_code = any(a.name == "error_code" for a in args)
    out = [f"  subroutine {sub}()",
           f"    !! Dump every value returned by {routine}.",
           "",
           f"    use {api_module}, only: {routine}",
           ""]
    out += [local_decl(a) for a in values]
    if has_error_code:
        out.append("    integer :: error_code")
    out += ["",
            "    ! Fixed values for anything UKCA does not set (see NOT_SET in",
            "    ! tools/gen_ukca_internal_dump.py)"]
    for a in values:
        if a.rank == 0 and not a.allocatable:
            out.append(f"    {a.name} = " + NOT_SET[a.type].format(name=a.name))
    out.append("")
    call_args = [f"{a.name}={a.name}" for a in values]
    if has_error_code:
        call_args.append("error_code=error_code")
    out += item_list(f"    call {routine}(", call_args, 6, last=")")
    out.append("")
    if has_error_code:
        out += ["    if (error_code /= 0) then",
                "      call dump('error_code', error_code)",
                "      return",
                "    end if"]
    for a in values:
        out += dump_var(a, 4)
    out += ["", f"  end subroutine {sub}", ""]
    return out


def gen_module_vars(sub, module, variables, what):
    """Subroutine dumping the public variables of a UKCA module."""
    out = [f"  subroutine {sub}()",
           f"    !! Dump the public variables of {module}:",
           f"    !! {what}.",
           ""]
    out += item_list(f"    use {module}, only: ", [v.name for v in variables],
                     6)
    out.append("")
    for v in variables:
        out += dump_var(v, 4)
    out += ["", f"  end subroutine {sub}", ""]
    return out


HAND_WRITTEN = '''  function ukca_dump_on() result(is_on)
    !! True if dumping is switched on, i.e. UKCA_DUMP_FILE is set. The dump
    !! file is opened on the first call.
    logical :: is_on
    call dump_open_from_env()
    is_on = dump_is_open()
  end function ukca_dump_on

  subroutine dump_ukca_internal_config()
    !! Dump the internal UKCA config. Call once, after ukca_setup and
    !! photol_setup. Labelled step 0.
    call dump_section('ukca_config', 0)
    call dump_ukca_get_config()
    call dump_section('photol_config', 0)
    call dump_photol_get_config()
    call dump_section('ukca_constants', 0)
    call dump_ukca_config_constants()
    call dump_section('photol_constants', 0)
    call dump_photol_constants()
    call dump_section('ukca_varlists', 0)
    call dump_ukca_varlists()
  end subroutine dump_ukca_internal_config

  subroutine dump_ukca_step_in_1d_domain(timestep_number, current_time, &
      tracer_data, ntp_data, r_theta_levels, r_rho_levels, previous_time, &
      eta_theta_levels)
    !! Dump the UKCA environment and every input to a ukca_step call (1D
    !! domain). Call immediately before ukca_step, with the same arguments
    !! (excluding the error and diagnostic arguments).
    integer, intent(in) :: timestep_number
    integer, intent(in) :: current_time(7)
    real, allocatable, intent(in) :: tracer_data(:,:)
    real, allocatable, intent(in) :: ntp_data(:,:)
    real, intent(in) :: r_theta_levels(:,:,0:)
    real, intent(in) :: r_rho_levels(:,:,:)
    integer, optional, intent(in) :: previous_time(7)
    real, allocatable, optional, intent(in) :: eta_theta_levels(:)
    call dump_step_start()
    call dump_allocated_2d('tracer_data', tracer_data)
    call dump_allocated_2d('ntp_data', ntp_data)
    call dump_step_args(timestep_number, current_time, r_theta_levels, &
      r_rho_levels, previous_time, eta_theta_levels)
  end subroutine dump_ukca_step_in_1d_domain

  subroutine dump_ukca_step_in_3d_domain(timestep_number, current_time, &
      tracer_data, ntp_data, r_theta_levels, r_rho_levels, previous_time, &
      eta_theta_levels)
    !! Dump the UKCA environment and every input to a ukca_step call (3D
    !! domain). Call immediately before ukca_step, with the same arguments
    !! (excluding the error and diagnostic arguments).
    integer, intent(in) :: timestep_number
    integer, intent(in) :: current_time(7)
    real, allocatable, intent(in) :: tracer_data(:,:,:,:)
    real, allocatable, intent(in) :: ntp_data(:,:,:,:)
    real, intent(in) :: r_theta_levels(:,:,0:)
    real, intent(in) :: r_rho_levels(:,:,:)
    integer, optional, intent(in) :: previous_time(7)
    real, allocatable, optional, intent(in) :: eta_theta_levels(:)
    call dump_step_start()
    call dump_allocated_4d('tracer_data', tracer_data)
    call dump_allocated_4d('ntp_data', ntp_data)
    call dump_step_args(timestep_number, current_time, r_theta_levels, &
      r_rho_levels, previous_time, eta_theta_levels)
  end subroutine dump_ukca_step_in_3d_domain

  subroutine dump_step_start()
    !! Start a new step: dump the environment UKCA holds, then open the
    !! ukca_step:in section.
    n_steps = n_steps + 1
    call dump_section('ukca_environment', n_steps)
    call dump_ukca_environment()
    call dump_section('ukca_step:in', n_steps)
  end subroutine dump_step_start

  subroutine dump_step_args(timestep_number, current_time, r_theta_levels, &
      r_rho_levels, previous_time, eta_theta_levels)
    !! Dump the non-tracer ukca_step inputs. r_theta_levels is dumped with
    !! 1-based indices (its vertical index starts at 0 in UKCA).
    integer, intent(in) :: timestep_number
    integer, intent(in) :: current_time(7)
    real, intent(in) :: r_theta_levels(:,:,0:)
    real, intent(in) :: r_rho_levels(:,:,:)
    integer, optional, intent(in) :: previous_time(7)
    real, allocatable, optional, intent(in) :: eta_theta_levels(:)
    call dump('timestep_number', timestep_number)
    call dump('current_time', current_time)
    call dump('r_theta_levels', r_theta_levels)
    call dump('r_rho_levels', r_rho_levels)
    if (present(previous_time)) then
      call dump('previous_time', previous_time)
    else
      call dump_marker('previous_time', '<absent>')
    end if
    if (present(eta_theta_levels)) then
      if (allocated(eta_theta_levels)) then
        call dump('eta_theta_levels', eta_theta_levels)
      else
        call dump_marker('eta_theta_levels', '<unallocated>')
      end if
    else
      call dump_marker('eta_theta_levels', '<absent>')
    end if
  end subroutine dump_step_args

  subroutine dump_ukca_step_out_1d_domain(tracer_data, ntp_data)
    !! Dump the tracers returned by a ukca_step call (1D domain). Call
    !! immediately after ukca_step.
    real, allocatable, intent(in) :: tracer_data(:,:)
    real, allocatable, intent(in) :: ntp_data(:,:)
    call dump_section('ukca_step:out', n_steps)
    call dump_allocated_2d('tracer_data', tracer_data)
    call dump_allocated_2d('ntp_data', ntp_data)
  end subroutine dump_ukca_step_out_1d_domain

  subroutine dump_ukca_step_out_3d_domain(tracer_data, ntp_data)
    !! Dump the tracers returned by a ukca_step call (3D domain). Call
    !! immediately after ukca_step.
    real, allocatable, intent(in) :: tracer_data(:,:,:,:)
    real, allocatable, intent(in) :: ntp_data(:,:,:,:)
    call dump_section('ukca_step:out', n_steps)
    call dump_allocated_4d('tracer_data', tracer_data)
    call dump_allocated_4d('ntp_data', ntp_data)
  end subroutine dump_ukca_step_out_3d_domain

  subroutine dump_allocated_2d(name, value)
    character(len=*), intent(in) :: name
    real, allocatable, intent(in) :: value(:,:)
    if (allocated(value)) then
      call dump(name, value)
    else
      call dump_marker(name, '<unallocated>')
    end if
  end subroutine dump_allocated_2d

  subroutine dump_allocated_4d(name, value)
    character(len=*), intent(in) :: name
    real, allocatable, intent(in) :: value(:,:,:,:)
    if (allocated(value)) then
      call dump(name, value)
    else
      call dump_marker(name, '<unallocated>')
    end if
  end subroutine dump_allocated_4d

  subroutine dump_ukca_varlists()
    !! Dump the tracer, NTP and environment field names, in UKCA order.
    use ukca_api_mod, only: &
      ukca_maxlen_fieldname, &
      ukca_get_tracer_varlist, &
      ukca_get_ntp_varlist, &
      ukca_get_environment_varlist
    character(len=ukca_maxlen_fieldname), pointer :: names(:)
    integer :: error_code

    names => null()
    call ukca_get_tracer_varlist(names, error_code)
    call dump_names('tracer_names', names, error_code)
    names => null()
    call ukca_get_ntp_varlist(names, error_code)
    call dump_names('ntp_names', names, error_code)
    names => null()
    call ukca_get_environment_varlist(names, error_code)
    call dump_names('environment_names', names, error_code)
  end subroutine dump_ukca_varlists

  subroutine dump_names(label, names, error_code)
    character(len=*), intent(in) :: label
    character(len=*), pointer, intent(in) :: names(:)
    integer, intent(in) :: error_code
    if (error_code /= 0) then
      call dump(label // '%error_code', error_code)
    else if (associated(names)) then
      call dump(label, names)
    else
      call dump_marker(label, '<unassociated>')
    end if
  end subroutine dump_names
'''


def module_text(src, desc):
    ukca_cfg = routine_args(
        src / "control/core/interface/ukca_config_specification_mod.F90",
        "ukca_get_config")
    photol_cfg = routine_args(
        src / "control/photolysis/interface/"
        "photol_config_specification_mod.F90", "photol_get_config")
    ukca_const = public_module_vars(
        src / "control/core/interface/ukca_config_constants_mod.F90")
    photol_const = public_module_vars(
        src / "control/photolysis/interface/photol_constants_mod.F90")
    env = public_module_vars(
        src / "control/core/interface/ukca_environment_fields_mod.F90")

    out = [f"module {MODULE}",
           "",
           "  !! GENERATED FILE - DO NOT EDIT.",
           "  !! Generated by tools/gen_ukca_internal_dump.py from UKCA",
           f"  !! {desc}.",
           "  !! Regenerate after any UKCA upgrade.",
           "  !!",
           "  !! Dumps the internal UKCA config and state with box_dump_mod,",
           "  !! read directly from UKCA. It never calls ukca_setup,",
           "  !! ukca_set_environment or ukca_step. A driver adds:",
           "  !!",
           "  !!   if (ukca_dump_on()) call dump_ukca_internal_config()",
           "  !!     after ukca_setup and photol_setup",
           "  !!   if (ukca_dump_on()) call dump_ukca_step_in(<ukca_step args>)",
           "  !!     immediately before ukca_step",
           "  !!   if (ukca_dump_on()) call dump_ukca_step_out(tracers, ntp)",
           "  !!     immediately after ukca_step",
           "  !!",
           "  !! See tools/gen_ukca_internal_dump.py for what is dumped.",
           ""]
    out += item_list("  use box_dump_mod, only: ",
                     ["dump", "dump_marker", "dump_section",
                      "dump_open_from_env", "dump_is_open"], 4)
    out += ["",
            "  implicit none",
            "",
            "  private",
            ""]
    out += item_list("  public :: ",
                     ["ukca_dump_on", "dump_ukca_internal_config",
                      "dump_ukca_step_in", "dump_ukca_step_out"], 4)
    for kind in ("in", "out"):
        out += ["", f"  interface dump_ukca_step_{kind}"]
        out += item_list("    module procedure ",
                         [f"dump_ukca_step_{kind}_1d_domain",
                          f"dump_ukca_step_{kind}_3d_domain"], 6)
        out.append(f"  end interface dump_ukca_step_{kind}")
    out += ["",
            "  !> number of ukca_step calls dumped so far",
            "  integer :: n_steps = 0",
            "",
            "contains",
            ""]
    out += HAND_WRITTEN.splitlines() + [""]
    out += gen_get_config("dump_ukca_get_config", "ukca_api_mod",
                          "ukca_get_config", ukca_cfg)
    out += gen_get_config("dump_photol_get_config",
                          "photol_config_specification_mod",
                          "photol_get_config", photol_cfg)
    out += gen_module_vars("dump_ukca_config_constants",
                           "ukca_config_constants_mod", ukca_const,
                           "constants used by UKCA")
    out += gen_module_vars("dump_photol_constants", "photol_constants_mod",
                           photol_const, "constants used by photolysis")
    out += gen_module_vars("dump_ukca_environment",
                           "ukca_environment_fields_mod", env,
                           "environment fields")
    out += [f"end module {MODULE}"]
    return out, {"ukca_get_config": len(ukca_cfg),
                 "photol_get_config": len(photol_cfg),
                 "ukca_config_constants_mod": len(ukca_const),
                 "photol_constants_mod": len(photol_const),
                 "ukca_environment_fields_mod": len(env)}


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--ukca-src", type=Path, default=Path("ukca/src"),
                   help="UKCA src directory (default: ukca/src)")
    p.add_argument("--out-dir", type=Path, default=Path("src"),
                   help="directory to write the module to (default: src)")
    args = p.parse_args()

    try:
        tags = subprocess.run(
            ["git", "-C", str(args.ukca_src), "tag", "--points-at", "HEAD"],
            capture_output=True, text=True, check=True).stdout.split()
        commit = subprocess.run(
            ["git", "-C", str(args.ukca_src), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, check=True).stdout.strip()
        desc = f"{'/'.join(tags) or 'untagged'} ({commit})"
    except (subprocess.CalledProcessError, FileNotFoundError):
        desc = str(args.ukca_src)

    lines, counts = module_text(args.ukca_src, desc)
    too_long = [n + 1 for n, l in enumerate(lines) if len(l) > MAX_LINE]
    if too_long:
        sys.exit(f"lines longer than {MAX_LINE}: {too_long[:5]}")
    path = args.out_dir / f"{MODULE.replace('_mod', '')}.F90"
    path.write_text("\n".join(lines) + "\n")
    print(f"wrote {path}")
    for what, n in counts.items():
        print(f"  {what}: {n} values")


if __name__ == "__main__":
    main()
