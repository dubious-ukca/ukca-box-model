#!/usr/bin/env python3
"""Compare new box model tracers with the old (UM) box model's tracer_out.hex.

The old box model writes tracer_out.hex: the raw bits of every tracer at
every timestep (timestep 0 = initial values). This script takes the new box
model's tracers from a UKCA dump (see src/box_dump.F90), converts them to the
same hex representation, matches tracers by name and reports how many are
bit-identical. Because it uses the old model's own output, it is independent
of the dump code in the old model.

    tools/compare_tracer_hex.py OLD_TRACER_OUT_HEX NEW_UKCA_DUMP

Timestep 0 is taken from ukca_step:in of step 1; timestep n from
ukca_step:out of step n. Only timesteps present in both are compared.

Note: the old box keeps H2O in q, not in its tracer array, so its H2O column
holds tracer_nullval (e.g. 1e-15) and will not match.

Exit status is 0 if every matched value is identical, 1 otherwise.
"""

import argparse
import struct
import sys


def load_hex(path):
    """{(timestep, tracer name): 16-digit upper-case hex}."""
    lines = open(path).read().splitlines()
    names = [x.strip() for x in lines[1].lstrip("#").split(",")][1:]
    names = [n for n in names if n]
    values = {}
    for line in lines:
        if line.startswith("#") or not line.strip():
            continue
        fields = [x.strip() for x in line.split(",") if x.strip()]
        for name, h in zip(names, fields[1:]):
            values[(int(fields[0]), name)] = h.upper()
    return names, values


def load_dump(path):
    """{(timestep, tracer name): 16-digit upper-case hex} from a UKCA dump."""
    names, raw = {}, {}
    for line in open(path):
        if line.startswith("#") or not line.strip():
            continue
        step, section, name, index, value = line.split(None, 4)
        step, value = int(step), value.strip()
        if section == "ukca_varlists" and name == "tracer_names":
            names[int(index.strip("()"))] = value.strip('"')
        elif name == "tracer_data" and (
                section == "ukca_step:out"
                or (section == "ukca_step:in" and step == 1)):
            tracer = int(index.strip("()").split(",")[-1])
            timestep = step if section == "ukca_step:out" else 0
            fields = value.split()
            if len(fields) == 2:
                # "<decimal> <hex>": the dump already has the bits
                raw[(timestep, tracer)] = fields[1].upper()
            else:
                bits = struct.unpack("<Q", struct.pack("<d", float(value)))[0]
                raw[(timestep, tracer)] = "%016X" % bits
    return {(t, names[i]): h for (t, i), h in raw.items()}


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("old_hex", help="old box model tracer_out.hex")
    p.add_argument("new_dump", help="new box model UKCA dump")
    p.add_argument("--max-show", type=int, default=10,
                   help="differences to list (default 10)")
    args = p.parse_args()

    names, old = load_hex(args.old_hex)
    new = load_dump(args.new_dump)
    common = sorted(k for k in old if k in new)
    differ = [k for k in common if old[k] != new[k]]
    steps = sorted({k[0] for k in common})

    print(f"old: {len(names)} tracers, timesteps {min(k[0] for k in old)}-"
          f"{max(k[0] for k in old)}")
    print(f"compared {len(common)} values (timesteps {steps[0]}-{steps[-1]})"
          f": identical {len(common) - len(differ)}, differ {len(differ)}")
    by_tracer = sorted({k[1] for k in differ})
    if by_tracer:
        print(f"tracers that differ: {', '.join(by_tracer)}")
    for k in differ[:args.max_show]:
        print(f"   step {k[0]:3d} {k[1]:12s} old={old[k]} new={new[k]}")
    unmatched = sorted({k[1] for k in old if k not in new})
    if unmatched:
        print(f"old tracers not found in new dump: {', '.join(unmatched)}")
    sys.exit(0 if not differ else 1)


if __name__ == "__main__":
    main()
