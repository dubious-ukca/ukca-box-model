#!/usr/bin/env python3
"""Compare two UKCA dump files (see src/box_dump.F90).

Each dump line is "<step> <section> <name> <index> <value>". Lines are matched
on (step, section, name, index), so the order the two box models wrote them
in does not matter.

For each step and section the report gives how many values are the same,
how many differ, and how many exist in only one dump, then lists the
differing names with an example value from each dump. Only steps present in
both dumps are compared, so a short run can be compared with a long one.

    tools/compare_dumps.py OLD_DUMP NEW_DUMP              # setup + first diverging step
    tools/compare_dumps.py OLD_DUMP NEW_DUMP --steps 0-3  # chosen steps
    tools/compare_dumps.py OLD_DUMP NEW_DUMP --all        # every common step
    tools/compare_dumps.py OLD_DUMP NEW_DUMP --ignore eta_theta_levels \
        --ignore ukca_config:l_ukca_h2o_feedback          # skip known differences

--ignore takes a name, or section:name, and may be repeated. Ignored values
are left out of the comparison entirely and listed in the report header.

A real is written as "<decimal> <hex>" (17 significant digits, then the 16
hex digits of its bits). When both dumps have the hex, reals are compared on
it; otherwise on the decimal, which is also exact (17 digits round-trip a
double), so older dumps without hex still compare. A differing real is shown
with its distance in units in the last place (ulp): 1 ulp is the smallest
possible difference.

Exit status is 0 if every compared value is identical, 1 otherwise.
"""

import argparse
import re
import struct
import sys
from collections import OrderedDict, defaultdict

# a real value: decimal, then optionally the 16 hex digits of its bits
REAL_RE = re.compile(r"^(\S+)(?: ([0-9A-F]{16}))?$")


def real_parts(value):
    """(decimal, hex or None) for a real value, else None."""
    m = REAL_RE.match(value)
    if not m:
        return None
    try:
        float(m.group(1))
    except ValueError:
        return None
    return m.group(1), m.group(2)


def bits_of(value):
    """The 64 bits of a real value, from its hex if present."""
    dec, hex_bits = real_parts(value)
    if hex_bits:
        return int(hex_bits, 16)
    return struct.unpack("<Q", struct.pack("<d", float(dec)))[0]


def same_value(a, b):
    """True if two dump values are identical (on hex when both have it)."""
    ra, rb = real_parts(a), real_parts(b)
    if ra and rb:
        if ra[1] and rb[1]:
            return ra[1] == rb[1]
        return ra[0] == rb[0]
    return a == b


def ulp_distance(a, b):
    """Number of representable doubles between two reals, or None."""
    if not (real_parts(a) and real_parts(b)):
        return None

    def ordered(bits):
        # map the bits to integers that sort in the same order as the reals
        return bits if bits < 1 << 63 else (1 << 63) - bits

    return abs(ordered(bits_of(a)) - ordered(bits_of(b)))


def load(path, ignore=()):
    """{step: OrderedDict{(section, name, index): value}}, minus ignored."""
    steps = defaultdict(OrderedDict)
    with open(path) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            step, section, name, index, value = line.split(None, 4)
            if name in ignore or f"{section}:{name}" in ignore:
                continue
            steps[int(step)][(section, name, index)] = value.strip()
    return steps


def compare_step(old, new):
    """{section: (same, [differing keys], [only old keys], [only new keys])}."""
    sections = OrderedDict()
    for key in list(old) + [k for k in new if k not in old]:
        sections.setdefault(key[0], ([], [], [], []))
    for key, value in old.items():
        same, diff, only_old, _ = sections[key[0]]
        if key not in new:
            only_old.append(key)
        elif same_value(new[key], value):
            same.append(key)
        else:
            diff.append(key)
    for key in new:
        if key not in old:
            sections[key[0]][3].append(key)
    return {s: (len(v[0]), v[1], v[2], v[3]) for s, v in sections.items()}


def is_identical(result):
    return all(not d and not o and not n for _, d, o, n in result.values())


def report_step(step, result, old, new, max_names):
    status = "IDENTICAL" if is_identical(result) else "DIFFERS"
    print(f"== step {step}: {status}")
    for section, (same, diff, only_old, only_new) in result.items():
        print(f"   {section:20s} same={same:6d} differ={len(diff):6d} "
              f"only_old={len(only_old):4d} only_new={len(only_new):4d}")
        by_name = OrderedDict()
        for key in diff:
            by_name.setdefault(key[1], []).append(key)
        for name, keys in list(by_name.items())[:max_names]:
            k = keys[0]
            n_ulp = ulp_distance(old[k], new[k])
            print(f"      {name:30s} {len(keys):5d} differ, e.g. {k[2]:12s}"
                  f" old={old[k]:26s} new={new[k]}"
                  + (f" ({n_ulp} ulp)" if n_ulp is not None else ""))
        if len(by_name) > max_names:
            print(f"      ... {len(by_name) - max_names} more names")
        for label, keys in (("only in old", only_old), ("only in new",
                                                        only_new)):
            names = list(OrderedDict.fromkeys(k[1] for k in keys))
            if names:
                print(f"      {label}: {', '.join(names[:max_names])}"
                      + (" ..." if len(names) > max_names else ""))


def parse_steps(text):
    out = set()
    for part in text.split(","):
        if "-" in part:
            a, b = part.split("-")
            out.update(range(int(a), int(b) + 1))
        else:
            out.add(int(part))
    return out


def main():
    p = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="\n".join(__doc__.splitlines()[2:]))
    p.add_argument("old", help="reference dump (e.g. the old box model)")
    p.add_argument("new", help="dump to check (e.g. the new box model)")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--steps", help="steps to report, e.g. 0-3 or 0,5,10")
    g.add_argument("--all", action="store_true", help="report every step")
    p.add_argument("--ignore", action="append", default=[],
                   metavar="[SECTION:]NAME",
                   help="leave out a known difference (repeatable)")
    p.add_argument("--max-names", type=int, default=20,
                   help="differing names listed per section (default 20)")
    args = p.parse_args()

    old, new = load(args.old, args.ignore), load(args.new, args.ignore)
    common = sorted(set(old) & set(new))
    results = {s: compare_step(old[s], new[s]) for s in common}
    first_diff = next((s for s in common if not is_identical(results[s])),
                      None)

    print(f"old: {args.old} (steps {min(old)}-{max(old)})")
    print(f"new: {args.new} (steps {min(new)}-{max(new)})")
    if args.ignore:
        print(f"ignoring: {', '.join(args.ignore)}")
    print(f"comparing {len(common)} common steps; "
          + ("all identical" if first_diff is None
             else f"first difference at step {first_diff}"))
    n_identical = sum(is_identical(results[s]) for s in common)
    print(f"identical steps: {n_identical}/{len(common)}")
    print()

    if args.all:
        show = common
    elif args.steps:
        show = [s for s in common if s in parse_steps(args.steps)]
    else:
        show = [s for s in common if s == 0 or s == first_diff]
    for s in show:
        report_step(s, results[s], old[s], new[s], args.max_names)

    sys.exit(0 if first_diff is None else 1)


if __name__ == "__main__":
    main()
