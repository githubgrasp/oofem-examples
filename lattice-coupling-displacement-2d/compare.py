#!/usr/bin/env python3
"""
Post-processing for the displacement-driven (Dirichlet) hydro-mechanical lattice
example. A stiff steel inclusion with an expanding ITZ pushes the matrix outward;
the resulting ITZ axial stress is transferred to the transport mesh as a pore
pressure (the mechanical -> transport coupling). This is the mirror image of the
fluid-pressure example, which transferred pressure onto the mechanical mesh and
validated the displacement -- here we drive the displacement and validate the
transferred PRESSURE (and, as a check on the mechanical side, the displacement).

Two analytical comparisons, both for the same thick-walled-cylinder geometry
(annulus a..b), anchored to the simulated amplitude (set by the eigenstrain):

  1. MECHANICAL: the matrix is loaded by the ITZ-driven radial displacement at
     its inner edge with a free outer edge, so u_r(r) = A r + B/r follows the
     Lame solution (sigma_r(b)=0, u(a)=u_a). Plane stress, nu from the matrix a1.
  2. TRANSPORT: pore pressure prescribed at the ITZ midline (the coupling nodes,
     radius ap) and drained (P_f=0) at the outer edge, with no storage (c=0), so
     steady radial conduction gives the logarithmic P_f(r) = Pa ln(b/r)/ln(b/ap).

Reads:  control.in (matrix a1), oofem.sm.in / oofem.tm.in (geometry),
        oofem.sm.out (u), oofem.tm.out (P_f).
Writes: disp_lattice.dat / disp_analytic.dat   (r/a,  u_r/a)
        pres_lattice.dat / pres_analytic.dat   (r/ap, P_f/Pa)
"""
import re, math

# --- geometry (match mesh.in / control.in) ---
r_incl = 0.008              # steel inclusion radius [m]  (#@diskinclusion radius)
itz    = 0.0005             # ITZ thickness [m]           (#@diskinclusion itz)
a      = r_incl + itz       # matrix inner radius (ITZ/matrix interface)
ap     = r_incl + 0.5 * itz # coupling (ITZ-midline) radius = effR
b      = 0.025              # outer radius [m]            (#@disk radius)


def read_matrix_a1():
    for ln in open("control.in"):
        m = re.match(r'\s*latticelinearelastic\s+1\b.*?\ba1\s+([0-9.eE+-]+)', ln)
        if m:
            return float(m.group(1))
    raise SystemExit("compare.py: matrix 'latticelinearelastic 1 ... a1' not found")


def read_coords(path):
    coords = {}
    for ln in open(path):
        m = re.match(r'\s*node\s+(\d+)\s+coords\s+2\s+(\S+)\s+(\S+)', ln)
        if m:
            coords[int(m.group(1))] = (float(m.group(2)), float(m.group(3)))
    return coords


def read_last_step(path):
    vals, cur = {}, None
    for ln in open(path):
        if re.search(r'Output for time', ln):
            vals, cur = {}, None
        m = re.match(r'\s*Node\s+(\d+)\s*\(', ln)
        if m:
            cur = int(m.group(1)); vals[cur] = {}
        m2 = re.match(r'\s*dof\s+(\d+)\s+d\s+(\S+)', ln)
        if m2 and cur is not None:
            vals[cur][int(m2.group(1))] = float(m2.group(2))
    return vals


def mean(xs):
    return sum(xs) / len(xs)


def write(path, header, pts):
    with open(path, "w") as f:
        f.write(header + "\n")
        for x, y in pts:
            f.write(f"{x:.6e} {y:.6e}\n")


# ---------------- mechanical: matrix u_r vs Lame ----------------
a1 = read_matrix_a1()
nu = (1.0 - a1) / (3.0 + a1)          # lattice: a1=1 -> nu=0, a1=1/3 -> nu=0.2
sc = read_coords("oofem.sm.in")
sd = read_last_step("oofem.sm.out")

drows = []
for n, (x, y) in sc.items():
    if n not in sd or not sd[n]:
        continue
    r = math.hypot(x, y)
    if r < a - 1.0e-5:                # matrix annulus only (skip inclusion + ITZ)
        continue
    ur = (sd[n].get(1, 0.0) * x + sd[n].get(2, 0.0) * y) / r
    drows.append((r, ur))
drows.sort()

u_a = mean([ur for r, ur in drows if r < a + 0.0015])   # prescribed inner u(a)
k = (1.0 - nu) / ((1.0 + nu) * b * b)
B = u_a / (k * a + 1.0 / a)
A = k * B
u = lambda r: A * r + B / r

write("disp_lattice.dat", f"# r/a  u_r/a   lattice matrix nodes (a1={a1}, nu={nu:.3f})",
      [(r / a, ur / a) for r, ur in drows])
write("disp_analytic.dat", f"# r/a  u_r/a   Lame annulus, nu={nu:.3f}",
      [((a + (b - a) * i / 200.0) / a, u(a + (b - a) * i / 200.0) / a) for i in range(201)])

# ---------------- transport: P_f vs logarithmic ----------------
tc = read_coords("oofem.tm.in")
td = read_last_step("oofem.tm.out")

prows = []
for n, (x, y) in tc.items():
    if n not in td or 11 not in td[n]:
        continue
    r = math.hypot(x, y)
    if r < ap - 1.0e-5:              # conductive annulus from the coupling ring out
        continue
    prows.append((r, td[n][11]))
prows.sort()

Pa = mean([p for r, p in prows if abs(r - ap) < 4.0e-4])   # prescribed midline P_f
pf = lambda r: Pa * math.log(b / r) / math.log(b / ap)

write("pres_lattice.dat", f"# r/ap  P_f/Pa   lattice transport nodes (Pa={Pa:.4e})",
      [(r / ap, p / Pa) for r, p in prows])
write("pres_analytic.dat", "# r/ap  P_f/Pa   logarithmic, drained outer",
      [((ap + (b - ap) * i / 200.0) / ap, pf(ap + (b - ap) * i / 200.0) / Pa) for i in range(201)])

print(f"mechanical: {len(drows)} matrix nodes  nu={nu:.3f}  u(a)={u_a:.3e}  "
      f"u(b)/u(a)={u(b)/u(a):.3f}")
print(f"transport : {len(prows)} nodes  Pa={Pa:.3e}  (P_f/Pa: 1 at interface -> 0 at drained outer)")
