#!/usr/bin/env python3
"""Sketch: make a new box model run directory from an old-box Rose suite.

    tools/rose2box.py SUITE_DIR OUT_DIR
    tools/rose2box.py ~/roses/u-ee345 runs/u-ee345 && scripts/run_box_model.sh -C runs/u-ee345

Reads SUITE_DIR/app/ukca/rose-app.conf and the files it names in
SUITE_DIR/app/ukca/file/, and writes namelist.nml, env_namelist.nml,
initial_tracers.txt, initial_ntp.txt and jrate.txt to OUT_DIR.

The box namelist variables are listed from src/box_config.F90. They are taken from the Rose namelists when the name is the
same, or through RENAMES / derived values below. Anything not found is left
out, so the new box model uses its own default.
"""
import re
import sys
from pathlib import Path

# new-box name -> (rose namelist, rose name)
RENAMES = {
    "i_photol_scheme": ("run_ukca", "i_ukca_photol"),
    "i_solcylc_type": ("run_ukca", "i_ukca_solcyc"),
    "solcylc_start_year": ("run_ukca", "i_ukca_solcyc_start_year"),
    "l_cal360": ("nlstcall", "lcal360"),
    "l_timer": ("nlstcall", "ltimer"),
    "l_zon_av_ozone": ("run_ozone", "zon_av_ozone"),
    "l_chem_environ_gas_scalars": ("run_ukca", "l_ukca_set_trace_gases"),
    "timestep": ("run_ukca", "chem_timestep"),
}
# Rose namelists searched, in order, for a variable of the same name
SEARCH = ["run_ukca", "temp_fixes", "run_convection", "run_radiation",
          "gen_phys_inputs", "nlstcall", "run_dust", "run_aerosol"]
CHEM_STRAT = {51, 52, 59}  # strattrop, strat, cristrat: photolysis l_strat_chem
PHOTOL_OFF = 0
# environment fields the old box driver sets to zero
OLD_BOX_ZERO_ENV = {
    "core_environment": {"conv_cloud_base": "0", "conv_cloud_top": "0",
                         "cloud_frac": "0.0", "ls_rain3d": "0.0", "ls_snow3d": "0.0"},
    "photolysis_environment": {"conv_cloud_lwp": "0.0", "conv_cloud_amount": "0.0",
                               "area_cloud_fraction": "0.0"},
    "aerosol_environment": {"cloud_liq_frac": "0.0"},
}


def read_rose_conf(path):
    """Return {section: {key: value}}, skipping !!-ignored items."""
    conf, section, key = {}, None, None
    for line in Path(path).read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^\[(!*)(.*)\]$", line.strip())
        if m:
            section = None if m.group(1) else m.group(2)
            if section is not None:
                conf.setdefault(section, {})
            key = None
            continue
        if section is None:
            continue
        if line.startswith("=") and key:            # continuation line
            conf[section][key] += line[1:]
            continue
        if line.startswith("!"):
            key = None
            continue
        k, _, v = line.partition("=")
        key = k.strip()
        conf[section][key] = v.strip()
    return conf


def read_box_namelists(box_config_f90):
    """Return {group: [variables]} from the namelist statements in box_config.F90."""
    src = Path(box_config_f90).read_text()
    src = re.sub(r"&\s*\n\s*", " ", src)            # join continuation lines
    groups = {}
    for m in re.finditer(r"namelist\s*/(\w+)/\s*([^\n]*)", src, re.I):
        groups[m.group(1)] = [v.strip().lower() for v in m.group(2).split(",")]
    return groups


def read_fortran_namelist(text, group):
    """Return {name: value string} for one &group in an old-box file."""
    m = re.search(rf"&{group}\b(.*?)^\s*/", text, re.I | re.S | re.M)
    out = {}
    for line in m.group(1).splitlines():
        line = line.split("!")[0].strip()
        if "=" in line:
            k, _, v = line.partition("=")
            out[k.strip().lower()] = v.strip()
    return out


def read_value_name(path):
    """Old-box '<value> <name>' files -> list of (name, value)."""
    pairs = []
    for line in Path(path).read_text().splitlines():
        parts = line.split()
        if len(parts) >= 2:
            pairs.append((parts[1], parts[0]))
    return pairs


def main(suite, out, box_config_f90=Path(__file__).resolve().parents[1] / "src" / "box_config.F90"):
    suite, out = Path(suite), Path(out)
    app = suite / "app" / "ukca"
    conf = read_rose_conf(app / "rose-app.conf")
    nl = {k.removeprefix("namelist:"): v for k, v in conf.items()}
    opts = {k: v.strip("'") for k, v in nl["nlstcall_box_options"].items()}
    files = app / "file"
    out.mkdir(parents=True, exist_ok=True)

    # --- derived values -----------------------------------------------------
    i_chem = int(nl["run_ukca"]["i_ukca_chem"])
    i_photol = int(nl["run_ukca"]["i_ukca_photol"])
    secs = int(nl["nlstcgen"]["secs_per_periodim"])
    steps = int(nl["nlstcgen"]["steps_per_periodim"])
    y, mo, d, h, mi, s = (int(x) for x in nl["nlstcall"]["model_basis_time"].split(","))
    ry, rmo, rd, rh, rmi, rs = (int(x) for x in nl["nlstcall"]["run_target_end"].split(","))
    month = 30 if nl["nlstcall"]["lcal360"] == ".true." else None
    if (ry or rmo) and month is None:
        sys.exit("run_target_end in years/months needs a 360-day calendar")
    duration = ((ry * 12 + rmo) * 30 + rd) * 86400 + rh * 3600 + rmi * 60 + rs
    derived = {
        "model_duration": str(duration),
        "start_year": str(y), "start_month": str(mo), "start_day": str(d),
        "start_hour": str(h), "start_minute": str(mi), "start_second": str(s),
        "l_use_photolysis": ".true." if i_photol != PHOTOL_OFF else ".false.",
        "l_strat_chem": ".true." if i_chem in CHEM_STRAT else ".false.",
        "l_offline_photol": ".true." if opts.get("photol_jrate_in_filename") else ".false.",
        # the old box always copies the H2O tracer into q; the new box only
        # does so with this on (see the bit-for-bit register)
        "l_ukca_h2o_feedback": ".true.",
    }
    model_ts = secs // steps
    if int(nl["run_ukca"]["chem_timestep"]) != model_ts:
        print(f"note: chem_timestep {nl['run_ukca']['chem_timestep']} != model timestep {model_ts}")

    # --- namelist.nml -------------------------------------------------------
    groups = read_box_namelists(box_config_f90)
    lines, unset = [], {}
    for group, names in groups.items():
        if group in ("constants",):
            continue
        body = []
        for name in names:
            if name in derived:
                value = derived[name]
            elif name in RENAMES:
                sec, key = RENAMES[name]
                value = nl.get(sec, {}).get(key)
            else:
                value = next((nl[s][name] for s in SEARCH
                              if s in nl and name in nl[s]), None)
            if value is None or value == "":
                unset.setdefault(group, []).append(name)
                continue
            body.append(f"{name}={value}")
        if group.lower() == "io":
            body = ['initial_tracer_file="initial_tracers.txt"',
                    'initial_ntp_file="initial_ntp.txt"',
                    'environment_data_file="env_namelist.nml"']
            if derived["l_offline_photol"] == ".true.":
                body.append('offline_photol_rates_file="jrate.txt"')
        lines += [f"&{group}"] + body + ["&end", ""]
    (out / "namelist.nml").write_text("\n".join(lines))

    # --- env_namelist.nml ---------------------------------------------------
    box_nml = (files / opts["ukca_box_nml"]).read_text()
    env = {k.removesuffix("_1"): v for k, v in
           read_fortran_namelist(box_nml, "ENVIRONMENT_PARS").items()}
    surf_albedo = env.pop("surf_albedo", None)
    # fields the old box sets to zero rather than reading from nml_box_*
    for k, v in OLD_BOX_ZERO_ENV["core_environment"].items():
        env.setdefault(k, v)
    oxid = read_fortran_namelist(box_nml, "OFFLINE_OXIDANT_MMR")
    rad, ukca = nl["run_radiation"], nl["run_ukca"]
    env_lines = ["&core_environment"] + [f"  {k} = {v}" for k, v in env.items()] + ["&end", ""]
    env_lines += ["&offlinechem_environment"] + \
        [f"  {k}_offline = {v}" for k, v in sorted(oxid.items())] + ["&end", ""]
    env_lines += ["&prescribed_conc_environment",
                  f"  atmospheric_co2 = {rad['co2_mmr']}",
                  f"  atmospheric_n2 = {ukca['ukca_n2mmr']}",
                  f"  atmospheric_o2 = {rad['o2mmr']}", "&end", ""]
    phot = dict(OLD_BOX_ZERO_ENV["photolysis_environment"])
    if surf_albedo is not None:
        phot["surf_albedo"] = surf_albedo
    env_lines += ["&photolysis_environment"] + [f"  {k} = {v}" for k, v in phot.items()] + ["&end", ""]
    env_lines += ["&aerosol_environment"] + \
        [f"  {k} = {v}" for k, v in OLD_BOX_ZERO_ENV["aerosol_environment"].items()] + ["&end", ""]
    (out / "env_namelist.nml").write_text("\n".join(env_lines))

    # --- tracers, NTP, j-rates ----------------------------------------------
    null = opts.get("tracer_nullval", "1e-15")
    tracers = dict(read_value_name(files / opts["tracer_in_filename"]))
    # the old box always copies q into the H2O tracer
    tracers.setdefault("H2O", env.get("q", null))
    write_list(out / "initial_tracers.txt", "Chemistry initial conditions", null, tracers)
    # the old box sets every NTP to tracer_nullval (chem_ntp_pars has no effect)
    write_list(out / "initial_ntp.txt", "Initial non-transported prognostic variables",
               null, {})
    if derived["l_offline_photol"] == ".true.":
        write_list(out / "jrate.txt", "Photolysis rate file", "0.0",
                   dict(read_value_name(files / opts["photol_jrate_in_filename"])))

    print(f"wrote {out}")
    for group, names in unset.items():
        print(f"  &{group}: {len(names)} not in the suite, box default used")


def write_list(path, title, default, items):
    text = [f"# {title}", "", f"DEFAULT {default}", ""]
    text += [f"{k} {v}" for k, v in items.items()]
    path.write_text("\n".join(text) + "\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:3])
