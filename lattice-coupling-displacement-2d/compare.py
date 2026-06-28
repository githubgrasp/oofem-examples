#!/usr/bin/env python3
"""
Post-processing for the displacement-driven (Dirichlet) hydro-mechanical lattice
example, two-way coupled. A stiff steel inclusion with an expanding ITZ pushes
the matrix outward; the ITZ axial stress is transferred to the transport mesh as
a pore pressure (mechanical -> transport), and with Biot coupling the resulting
pore pressure feeds back into the matrix stress (transport -> mechanical). This
is the mirror image of the companion fluid-pressure example.

Two analytical comparisons, both for the same thick-walled-cylinder geometry
(matrix annulus a..b) and both ABSOLUTE — predicted from the simulated pore
pressure, with no amplitude fitting (the same spirit as the fluid-pressure
example, which predicts displacement from the prescribed cavity pressure):

  1. TRANSPORT (the forward-transferred quantity): pore pressure prescribed at
     the ITZ midline (the coupling ring, radius ap) and drained (P_f = 0) at the
     outer edge, no storage (c = 0), so steady radial conduction gives the
     logarithmic P_f(r) = Pa ln(b/r)/ln(b/ap).
  2. MECHANICAL: the coupling pressure Pa IS the ITZ axial stress, i.e. the
     radial traction the ITZ applies to the matrix inner edge. So the matrix
     annulus is loaded by sigma_r(a) = Pa, a traction-free outer edge
     sigma_r(b) = 0, and (for Biot b>0) the distributed pore-pressure body force.
     The radial displacement solves
        u'' + u'/r - u/r^2 = -(b/K) P',   K = E/(1-nu^2),
     giving u(r) = (kappa/2) r ln r + D r + C1/r,  kappa = b Pa (1-nu^2)/(E ln(b/ap)),
     with D, C1 fixed by the two stress BCs. At b = 0 this is the classic Lame
     annulus under inner pressure Pa (wall thins); b = 1 adds the body force
     (wall thickens). No anchoring — the amplitude is a prediction.

Reads:  control.in (matrix a1, E, bio), oofem.sm.in / oofem.tm.in (geometry),
        oofem.sm.out (u), oofem.tm.out (P_f).
Writes: pres_lattice.dat / pres_analytic.dat   (r/ri, P_f/Pa)
        disp_lattice.dat / disp_analytic.dat   (r/ri, u_r/ri)
        (all lengths normalised by the inclusion radius ri, as in the pressure example)
"""
import re, math

# --- geometry (match mesh.in / control.in) ---
r_incl = 0.008              # steel inclusion radius [m]  (#@diskinclusion radius)
itz    = 0.00001            # ITZ thickness [m]           (#@diskinclusion itz)
ri     = r_incl             # normalising length (inclusion radius), as in the pressure example
a      = r_incl + itz       # matrix inner radius (ITZ/matrix interface)
ap     = r_incl + 0.5 * itz # coupling (ITZ-midline) radius = effR
b      = 0.025              # outer radius [m]            (#@disk radius)


def read_matrix_params():
    # matrix is material 1: latticelinearelastic 1 ... e <E> a1 <a1> [bio <b>]
    for ln in open("control.in"):
        if re.match(r'\s*latticelinearelastic\s+1\b', ln):
            E  = float(re.search(r'\be\s+([0-9.eE+-]+)', ln).group(1))
            a1 = float(re.search(r'\ba1\s+([0-9.eE+-]+)', ln).group(1))
            m  = re.search(r'\bbio\s+([0-9.eE+-]+)', ln)
            bio = float(m.group(1)) if m else 0.0
            return a1, E, bio
    raise SystemExit("compare.py: matrix 'latticelinearelastic 1 ...' not found")


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


a1, E, bio = read_matrix_params()
nu = (1.0 - a1) / (3.0 + a1)          # lattice: a1=1 -> nu=0, a1=1/3 -> nu=0.2
L = math.log(b / ap)

# ---------------- transport: P_f vs logarithmic ----------------
tc = read_coords("oofem.tm.in")
td = read_last_step("oofem.tm.out")

prows = []
for n, (x, y) in tc.items():
    if n not in td or 11 not in td[n]:
        continue
    r = math.hypot(x, y)
    if r < ap:                      # from the coupling ring outward (ap = ITZ midline)
        continue
    prows.append((r, td[n][11]))
prows.sort()

Pa = mean([p for r, p in prows if abs(r - ap) < 4.0e-4])   # prescribed midline P_f
pf = lambda r: Pa * math.log(b / r) / math.log(b / ap)

write("pres_lattice.dat", f"# r/ri  P_f/Pa   lattice transport nodes (Pa={Pa:.4e})",
      [(r / ri, p / Pa) for r, p in prows])
write("pres_analytic.dat", "# r/ri  P_f/Pa   logarithmic, drained outer",
      [((ap + (b - ap) * i / 200.0) / ri, pf(ap + (b - ap) * i / 200.0) / Pa) for i in range(201)])

# ---------------- mechanical: matrix u_r vs poroelastic annulus ----------------
sc = read_coords("oofem.sm.in")
sd = read_last_step("oofem.sm.out")

drows = []
for n, (x, y) in sc.items():
    if n not in sd or not sd[n]:
        continue
    r = math.hypot(x, y)
    if r < a - 0.5 * itz:            # matrix only; cut at the ITZ midline so the
        continue                     # inclusion/ITZ nodes (on the stiff steel) are
                                     # excluded regardless of how thin the ITZ is
    ur = (sd[n].get(1, 0.0) * x + sd[n].get(2, 0.0) * y) / r
    drows.append((r, ur))
drows.sort()

u_a_sim = mean([ur for r, ur in drows if r < a + 0.0015])   # measured, for reporting only

# Absolute prediction — no amplitude fitting. The coupling pressure Pa is the ITZ
# axial stress and is the radial traction the ITZ applies to the matrix. With a
# THIN ITZ the matrix inner edge a = r_i + itz and the coupling ring ap = r_i +
# itz/2 both collapse onto ~r_i, so there is no radius mismatch: the annulus is
# simply loaded by sigma_r(a) = Pa (inner), a traction-free outer sigma_r(b) = 0,
# and the distributed Biot body force.
# u(r) = (kappa/2) r ln r + D r + C1/r ;  kappa = b Pa (1-nu^2)/(E ln(b/ap)).
# kappa = 0 (b = 0) recovers the classic Lame annulus under inner pressure Pa.
K = E / (1.0 - nu * nu)
kappa = bio * Pa / (K * L)
m11, m12 = K * (1.0 + nu), -K * (1.0 - nu) / (a * a)
m21, m22 = K * (1.0 + nu), -K * (1.0 - nu) / (b * b)
r1 = Pa - bio * Pa * math.log(b / a) / L - K * 0.5 * kappa * ((1.0 + nu) * math.log(a) + 1.0)
r2 = 0.0                                 - K * 0.5 * kappa * ((1.0 + nu) * math.log(b) + 1.0)
det = m11 * m22 - m12 * m21
D  = (r1 * m22 - m12 * r2) / det
C1 = (m11 * r2 - r1 * m21) / det
u = lambda r: 0.5 * kappa * r * math.log(r) + D * r + C1 / r

label = "Lame" if bio == 0.0 else "poroelastic (Biot b=%g)" % bio
write("disp_lattice.dat", f"# r/ri  u_r/ri   lattice matrix nodes (a1={a1}, nu={nu:.3f}, bio={bio})",
      [(r / ri, ur / ri) for r, ur in drows])
write("disp_analytic.dat", f"# r/ri  u_r/ri   {label} annulus, nu={nu:.3f}",
      [((a + (b - a) * i / 200.0) / ri, u(a + (b - a) * i / 200.0) / ri) for i in range(201)])

print(f"transport : {len(prows)} nodes  Pa={Pa:.3e}  (logarithmic, P_f/Pa: 1 -> 0)")
print(f"mechanical: {len(drows)} matrix nodes  nu={nu:.3f}  bio={bio}  ({label}, absolute)")
print(f"            analytic u(a)={u(a):.3e}  lattice u(a)={u_a_sim:.3e}  "
      f"u(b)/u(a)={u(b)/u(a):.3f}")
