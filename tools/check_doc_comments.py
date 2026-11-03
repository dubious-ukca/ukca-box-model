#!/usr/bin/env python3
"""Check Fortran doc comments follow the project (FORD) convention.

Two rules:

1. Every variable declaration has a `!>` comment on the line(s) immediately
   before it: module variables, derived type components, procedure arguments
   and local variables alike. A declaration is any type declaration
   statement with `::` (integer, real, logical, character, complex,
   type(...), class(...), procedure(...)). Blank lines in between are
   allowed (FORD accepts them).

2. Every `module`, `program`, `subroutine` and `function` has a `!!`
   docstring straight after its opening statement (Python style). Blank
   lines in between are allowed, but nothing else: the docstring comes
   before any `use` statement. Procedures inside `interface` blocks are
   skipped.

    tools/check_doc_comments.py src/box_ntp.F90 src/box_tracers.F90
    tools/check_doc_comments.py src/*.F90

Lists each problem as file:line: description. Exit status is 0 if
everything is documented, 1 otherwise.
"""

import re
import sys

DECL_RE = re.compile(
    r"^\s*(integer|real|logical|character|complex|double\s+precision|"
    r"type\s*\(|class\s*\(|procedure\s*\()[^!]*::\s*(.*)$", re.I)


def split_names(entities):
    """Variable names from the entity list of a declaration."""
    depth, cur, names = 0, "", []
    for ch in entities:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            names.append(cur)
            cur = ""
        else:
            cur += ch
    names.append(cur)
    out = []
    for n in names:
        m = re.match(r"\s*([A-Za-z_]\w*)", n)
        if m:
            out.append(m.group(1))
    return out


UNIT_RE = re.compile(
    r"^\s*(?:(?:pure|impure|elemental|recursive|module)\s+)*"
    r"(?:(?:integer|real|logical|character|complex|double\s+precision|"
    r"type\s*\([^)]*\))(?:\s*\([^)]*\))?\s+)?"
    r"(subroutine|function)\s+([A-Za-z_]\w*)", re.I)
MODULE_RE = re.compile(r"^\s*(module|program)\s+(?!procedure\b)([A-Za-z_]\w*)\s*$",
                       re.I)


def check_docstrings(path):
    """Units (module/program/subroutine/function) missing a `!!` docstring."""
    lines = open(path, errors="ignore").read().splitlines()
    missing = []
    in_interface = 0
    for i, line in enumerate(lines):
        code = line.split("!")[0].strip()
        if re.match(r"^(abstract\s+)?interface\b", code, re.I):
            in_interface += 1
            continue
        if re.match(r"^end\s*interface\b", code, re.I):
            in_interface -= 1
            continue
        if in_interface or re.match(r"^end\b", code, re.I):
            continue
        m = UNIT_RE.match(code) or MODULE_RE.match(code)
        if not m:
            continue
        # skip over continuation lines of the opening statement
        j = i
        while lines[j].split("!")[0].rstrip().endswith("&") and \
                j + 1 < len(lines):
            j += 1
        k = j + 1
        while k < len(lines) and not lines[k].strip():
            k += 1
        if k >= len(lines) or not lines[k].lstrip().startswith("!!"):
            missing.append((i + 1, f"{m.group(1).lower()} {m.group(2)}: "
                            "no `!!` docstring after the opening statement"))
    return missing


def check(path):
    lines = open(path, errors="ignore").read().splitlines()
    missing = []
    continued = False
    for i, line in enumerate(lines):
        code = line.split("!")[0].rstrip()
        is_continuation = continued
        continued = code.endswith("&")
        if is_continuation:
            continue
        m = DECL_RE.match(code)
        if not m:
            continue
        # join continuation lines to get the full entity list
        stmt, j = code, i
        while stmt.rstrip().endswith("&") and j + 1 < len(lines):
            j += 1
            stmt = stmt.rstrip()[:-1] + " " + lines[j].split("!")[0].strip(
                ).lstrip("&")
        names = split_names(DECL_RE.match(stmt).group(2))
        k = i - 1
        while k >= 0 and not lines[k].strip():
            k -= 1
        if k < 0 or not lines[k].lstrip().startswith("!>"):
            missing.append((i + 1, ", ".join(names) + ": no `!>` comment"))
    return missing


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    total = 0
    for path in sys.argv[1:]:
        missing = sorted(check(path) + check_docstrings(path))
        total += len(missing)
        for line, what in missing:
            print(f"{path}:{line}: {what}")
    print(f"{total} documentation problem(s) in {len(sys.argv) - 1} "
          "file(s)", file=sys.stderr)
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
