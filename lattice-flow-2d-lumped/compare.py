#!/usr/bin/env python3
"""
Extract pressure profiles (y, p) from the lumped/ and consistent/ VTU output
at selected time steps. Writes per variant per step:

  lumped/profile_<step>.dat            x y p     (per node, sorted by y)
  lumped/profile_<step>_binned.dat     y p_mean  (binned mean for clean lines)
  consistent/profile_<step>.dat        x y p
  consistent/profile_<step>_binned.dat y p_mean

No analytical reference is computed — there is no closed form for the
van Genuchten unsaturated case used by this example.
"""
import os
import sys
import xml.etree.ElementTree as ET

# Steps selected to bracket the consistent-mass overshoot regime
# (peak around step 50, decays by ~step 200).
STEPS = (10, 30, 50, 80)

# y-bin width for the binned profiles (must be coarser than the lattice
# mesh diameter `#@diam = 0.002` so each bin contains several nodes).
BIN_WIDTH = 0.002
DOMAIN_HEIGHT = 0.1


def parse_vtu(path):
    """Return [(x, y, p), ...] for one ASCII vtkxmllattice VTU."""
    root = ET.parse(path).getroot()
    ns = root.tag.split("}")[0] + "}" if root.tag.startswith("{") else ""
    points = root.find(f".//{ns}Points/{ns}DataArray")
    pdata = next(
        (
            d
            for d in root.findall(f".//{ns}PointData/{ns}DataArray")
            if d.get("Name") == "PressureVector"
        ),
        None,
    )
    if pdata is None:
        raise RuntimeError(f"PressureVector not in {path}")
    xyz = list(map(float, points.text.split()))
    p = list(map(float, pdata.text.split()))
    return [(xyz[3 * i], xyz[3 * i + 1], p[i]) for i in range(len(p))]


def bin_by_y(nodes, bin_width=BIN_WIDTH, height=DOMAIN_HEIGHT):
    """Return [(y_centre, p_mean, p_max)] aggregating nodes by horizontal bands.

    p_max is what we want to plot for the lumped-vs-consistent comparison:
    the consistent-mass overshoot lives at only a few nodes per band, so
    a mean would average it out. The maximum envelope makes it visible.
    """
    n_bins = max(1, int(round(height / bin_width)))
    sums = [0.0] * n_bins
    counts = [0] * n_bins
    maxs = [float("-inf")] * n_bins
    for _x, y, p in nodes:
        idx = min(n_bins - 1, max(0, int(y / bin_width)))
        sums[idx] += p
        counts[idx] += 1
        if p > maxs[idx]:
            maxs[idx] = p
    out = []
    for i in range(n_bins):
        if counts[i] > 0:
            out.append(((i + 0.5) * bin_width, sums[i] / counts[i], maxs[i]))
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    for sub in ("lumped", "consistent"):
        for step in STEPS:
            vtu = os.path.join(here, sub, f"oofem.out.m0.{step}.vtu")
            if not os.path.exists(vtu):
                print(f"WARNING: {vtu} missing", file=sys.stderr)
                continue
            nodes = sorted(parse_vtu(vtu), key=lambda r: r[1])
            with open(os.path.join(here, sub, f"profile_{step}.dat"), "w") as f:
                f.write("# x y p\n")
                for x, y, p in nodes:
                    f.write(f"{x:.6e} {y:.6e} {p:.6e}\n")
            with open(
                os.path.join(here, sub, f"profile_{step}_binned.dat"), "w"
            ) as f:
                f.write("# y_centre p_mean p_max\n")
                for y, pmean, pmax in bin_by_y(nodes):
                    f.write(f"{y:.6e} {pmean:.6e} {pmax:.6e}\n")


if __name__ == "__main__":
    main()
