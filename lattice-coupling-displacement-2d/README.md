# Displacement-driven inclusion (hydro-mechanical lattice)

A stiff circular **steel inclusion** sits inside a concrete **matrix** disk,
separated by a thin **interfacial transition zone (ITZ)**. The ITZ expands
radially (an eigen-displacement, as in a corrosion / swelling problem), pushing
the surrounding matrix outward. The compressive axial stress this generates in
the radial ITZ struts is transferred to the **transport** lattice as a pore
pressure — the *mechanical → transport* coupling.

This is the mirror image of the companion
[`lattice-coupling-pressure-2d`](../lattice-coupling-pressure-2d/) example. There
a fluid pressure was transferred *onto* the mechanical mesh and the **displacement**
was validated; here a mechanical displacement is imposed and the transferred
**pore pressure** is validated (with the displacement as a secondary check).

It uses the displacement-driven (Dirichlet) coupling of:

> P. Grassl, C. Fahy, D. Gallipoli, S.J. Wheeler,
> [*A hydro-mechanical lattice approach for modelling hydraulic fracture*](https://petergrassl.com/publications/grafahgal15a/),
> J. Mech. Phys. Solids **75** (2015) 104–118.

## The physics in two figures

Because the inclusion is much stiffer than the matrix, the ITZ eigen-displacement
at the interface acts like a *prescribed inner radial displacement* of a
thick-walled cylinder (the matrix annulus `a … b`, free outer edge). Both fields
are therefore classical:

- **`pressure.pdf` — the transferred quantity.** With the outer boundary drained
  (`P_f = 0`) and no storage (`c = 0`), steady radial conduction gives a
  **logarithmic** pore-pressure field `P_f(r) = P_a · ln(b/r) / ln(b/a_p)` between
  the ITZ-midline coupling ring (radius `a_p`, where the pressure is injected) and
  the drained outer edge. The transport lattice nodes fall on this curve.
- **`displacement.pdf` — the mechanical check.** The matrix radial displacement
  follows the **Lamé** annulus solution `u_r(r) = A r + B/r` (prescribed `u(a)`,
  traction-free outer). With `a1 = 1` the lattice Poisson ratio is `ν = 0`, giving
  a clean closed form.

The amplitude of each curve (set by the eigenstrain and the stiffness contrast) is
taken from the simulation; the example validates the *shape* of both transferred
fields against the analytical solutions.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-coupling-displacement-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

Or with a local build — `generator`, `qvoronoi`, `converter`, `oofem` on the
PATH, plus `python3` and `gnuplot`:

```bash
bash run.sh      # generate, solve, and draw pressure.pdf + displacement.pdf
bash clean.sh    # back to a git-clean folder (keeps sources + local/)
```

### Pipeline (`run.sh`)

1. `generator mesh.in` — seeds a random node cloud in the disk, with rings on the
   inclusion and ITZ circles (deterministic).
2. `qvoronoi` — Voronoi tessellation (dual transport lattice).
3. `converter control.in mesh.nodes mesh.voronoi` — writes the coupled
   `oofem.sm.in` (mechanical, Delaunay edges) and `oofem.tm.in` (transport,
   Voronoi edges) in one pass (`#@grid 2dSMTM`).
4. `oofem -f oofem.smtm.in` — staggered **SM-first** mechanical→transport solve.
   `profileopt 1` reorders the skyline solver.
5. `compare.py` + `gnuplot` — profiles and the two PDFs.

### Key input ingredients

- `#@diskinclusion 1 … radius 0.008 itz 0.0005 inside 2 interface 3` — the steel
  inclusion (material 2) and its ITZ shell (material 3) inside the matrix.
- `#@bodyload 3 3` + `StructTemperatureLoad 3` — the ITZ eigen-expansion (applied
  to every ITZ element, material 3).
- `#@coupling inclusion 1 dirichlet ltf 1` — emits one `LatticeDirichletCoupling`
  per ITZ-midline transport node, driven by its two flanking radial ITZ structural
  elements (compression → pore pressure). This is the *mechanical → transport*
  coupling and **must** run SM-first (`coupling 3 1 2 0` in `oofem.smtm.in`).
- `#@edgebc region 1 bc 1` — holds the **outer** boundary at zero pore pressure
  (drainage), so the steady field is logarithmic. Without it the outer boundary is
  insulated and the field would be uniform.
- transport materials: matrix and ITZ are conductive (`k = 1e-19`); the steel
  inclusion is effectively impermeable (`k = 1e-25`), so flow threads only through
  the matrix. Zero capacity (`c 0.`) → steady state each step.

The ITZ expansion is ramped over the steps, so the saved VTU frames animate in
ParaView; the field shapes are self-similar, so the final step is used for the
graphs.

### Output layout

```
tracked sources:        mesh.in, control.in, control.tm.in, oofem.smtm.in,
                        run.sh, clean.sh, compare.py, README.md
generated (gitignored): mesh.nodes, oofem.*.in/out,
                        disp_lattice.dat / disp_analytic.dat,
                        pres_lattice.dat / pres_analytic.dat,
                        pressure.pdf, displacement.pdf
local/ (gitignored):    vtu/  — ParaView opens oofem.tm.out.m0.pvd (pore
                        pressure) or oofem.sm.out.m0.pvd (displacement)
```

## Notes

- **Why two materials with `a1 = 1`.** The matrix uses `a1 = 1` so its effective
  Poisson ratio is `ν = 0`, which makes the Lamé comparison a clean closed form.
  The ITZ uses a small `a1` and a thermal-expansion coefficient to act as the
  eigen-strain driver.
- **Anchoring.** Both analytical curves are anchored to the simulated amplitude:
  the matrix inner-ring displacement `u(a)` for the Lamé curve, and the mean
  ITZ-midline pore pressure `P_a` for the logarithmic curve. The validation is of
  the radial *profile shape*, which is the part fixed by the physics.
- **Coupling direction.** Unlike the pressure example (transport→mechanical,
  TM-first), this one is mechanical→transport and runs **SM-first**: the mechanical
  stress must exist before the transport reads it. The two examples use opposite
  staggered orders by design.
```
