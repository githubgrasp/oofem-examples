#!/usr/bin/env python3
"""
Single-case post-processing for the fluid-pressurised thick-walled cylinder.
Compares the lattice radial displacement with the analytical poroelastic
solution of Grassl, Fahy, Gallipoli & Wheeler (2015), JMPS 75, 104-118 (A.22).

Reads:  control.in (Biot coefficient), oofem.sm.in (geometry), oofem.sm.out (u).
Writes: lattice.dat   raw per-node (r/ri, u_r/ri)   -- honest scatter, normalised
        analytic.dat  analytical curve (r/ri, u_r/ri)

The analytical curve solves the 2x2 system for the integration constants C1, C2
of the ODE solution (A.15) under the stress BCs (A.18): sigma_rm = (1-b) Pfi at
r=ri, sigma_rm = 0 at r=ro -- numerically identical to (A.22) but transcription-safe.
"""
import re, math

# --- geometry / material (match mesh.in, control.in, control.tm.in) ---
ri, ro = 0.008, 0.025      # inner / outer radius [m]
Pfi    = -1.0e6            # inner fluid pressure [Pa]  (compression negative)
Ec     = 30.0e9            # continuum Young's modulus [Pa]  (lattice input E)
nu     = 0.0              # Poisson's ratio  (a1 = 1.0)

rbo  = ro / ri
pbar = Pfi / Ec
lnro = math.log(rbo)


def read_bio():
    for ln in open("control.in"):
        m = re.search(r'\bbio\s+([0-9.eE+-]+)', ln)
        if m:
            return float(m.group(1))
    raise SystemExit("compare.py: 'bio' not found in control.in")


def analytic(b):
    S = b * pbar * (1.0 - nu**2) / lnro
    A = 0.5 * b * pbar / lnro
    a11, a12 = -1.0 / (1.0 + nu),            1.0 / (1.0 - nu)
    a21, a22 = -1.0 / ((1.0 + nu) * rbo**2), 1.0 / (1.0 - nu)
    r1 = (1.0 - b) * pbar - A * ((1.0 + nu) * math.log(1.0) + 1.0)
    r2 = 0.0              - A * ((1.0 + nu) * math.log(rbo) + 1.0)
    det = a11 * a22 - a12 * a21
    C1 = (r1 * a22 - a12 * r2) / det
    C2 = (a11 * r2 - r1 * a21) / det
    return lambda r: (0.5 * S * (r / ri) * math.log(r / ri)
                      + C1 / (r / ri) + C2 * (r / ri)) * ri


def read_coords(path):
    coords = {}
    for ln in open(path):
        m = re.match(r'\s*node\s+(\d+)\s+coords\s+2\s+(\S+)\s+(\S+)', ln)
        if m:
            coords[int(m.group(1))] = (float(m.group(2)), float(m.group(3)))
    return coords


def read_last_step(path):
    disp, cur = {}, None
    for ln in open(path):
        if re.search(r'Output for time', ln):
            disp, cur = {}, None
        m = re.match(r'\s*Node\s+(\d+)\s*\(', ln)
        if m:
            cur = int(m.group(1)); disp[cur] = {}
        m2 = re.match(r'\s*dof\s+(\d+)\s+d\s+(\S+)', ln)
        if m2 and cur is not None:
            disp[cur][int(m2.group(1))] = float(m2.group(2))
    return disp


b = read_bio()
coords = read_coords("oofem.sm.in")
disp = read_last_step("oofem.sm.out")

rows = []
for n, (x, y) in coords.items():
    if n not in disp or not disp[n]:
        continue
    r = math.hypot(x, y)
    if r <= 0:
        continue
    ur = (disp[n].get(1, 0.0) * x + disp[n].get(2, 0.0) * y) / r
    rows.append((r, ur))
rows.sort()

# normalise by the inner radius: r_bar = r/ri, u_bar = u/ri  (cleaner axes)
with open("lattice.dat", "w") as f:
    f.write(f"# r/ri  u_r/ri   raw lattice nodes, b={b}\n")
    for r, ur in rows:
        f.write(f"{r/ri:.6e} {ur/ri:.6e}\n")

ua = analytic(b)
with open("analytic.dat", "w") as f:
    f.write(f"# r/ri  u_r/ri   analytical A.22, b={b}\n")
    for i in range(201):
        r = ri + (ro - ri) * i / 200.0
        f.write(f"{r/ri:.6e} {ua(r)/ri:.6e}\n")

print(f"b={b}: {len(rows)} nodes; analytic u(ri)/ri={ua(ri)/ri:.3e} "
      f"u(ro)/ri={ua(ro)/ri:.3e} ratio o/i={ua(ro)/ua(ri):.3f}")
