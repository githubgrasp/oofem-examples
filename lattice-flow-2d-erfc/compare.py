#!/usr/bin/env python3
"""
Extract (y, p) profiles from this run's VTU output at selected time steps
and compute the corresponding 1D finite-slab analytical solution for
verification.

Outputs (written next to this script):
  profile_<step>.dat       x y p   (per lattice node, sorted by y)
  analytical_<step>.dat    y p     (analytical curve on a fine grid)

Problem: 1D linear diffusion in a slab of height H, prescribed p=1 at y=0,
no-flux at y=H, zero initial pressure. Diffusivity D = k/(vis·c). All
parameters here must match control.in.
"""
import math
import os
import sys
import xml.etree.ElementTree as ET

# Must match control.in
K = 1.0e-4
VIS = 1.0
C = 1.0
D = K / (VIS * C)
H = 0.1
DELTAT = 0.05
STEPS = (10, 30, 60, 100)
NTERMS = 200


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


def analytical(y, t):
    """Finite-slab 1D diffusion, p(0,t)=1, p_y(H,t)=0, p(y,0)=0."""
    if t <= 0.0:
        return 1.0 if y <= 0.0 else 0.0
    s = 0.0
    for n in range(NTERMS):
        lam = (2 * n + 1) * math.pi / (2.0 * H)
        s += (4.0 / ((2 * n + 1) * math.pi)) * math.sin(lam * y) * math.exp(
            -lam * lam * D * t
        )
    return 1.0 - s


def main():
    here = os.path.dirname(os.path.abspath(__file__))

    for step in STEPS:
        vtu = os.path.join(here, f"oofem.out.m0.{step}.vtu")
        if not os.path.exists(vtu):
            print(f"WARNING: {vtu} missing", file=sys.stderr)
            continue
        nodes = sorted(parse_vtu(vtu), key=lambda r: r[1])
        with open(os.path.join(here, f"profile_{step}.dat"), "w") as f:
            f.write("# x y p\n")
            for x, y, p in nodes:
                f.write(f"{x:.6e} {y:.6e} {p:.6e}\n")

    ygrid = [i * H / 200 for i in range(201)]
    for step in STEPS:
        t = step * DELTAT
        with open(os.path.join(here, f"analytical_{step}.dat"), "w") as f:
            f.write(f"# y p (t={t} s)\n")
            for y in ygrid:
                f.write(f"{y:.6e} {analytical(y, t):.6e}\n")


if __name__ == "__main__":
    main()
