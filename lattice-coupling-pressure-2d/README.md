# Fluid-pressurised thick-walled cylinder (hydro-mechanical lattice)

A saturated thick-walled cylinder (annulus) is loaded by a fluid pressure on its
inner surface. Steady-state radial flow sets up a logarithmic pore-pressure field
between the pressurised inner radius and the drained (zero-pressure) outer radius.
The pore pressure drives the mechanical response through Biot's effective-stress
coupling, and the resulting radial displacement is compared with the analytical
poroelastic solution.

This reproduces the elastic part of the benchmark in:

> P. Grassl, C. Fahy, D. Gallipoli, S.J. Wheeler,
> [*A hydro-mechanical lattice approach for modelling hydraulic fracture*](https://petergrassl.com/publications/grafahgal15a/),
> J. Mech. Phys. Solids **75** (2015) 104–118 — Fig. 7 and Appendix A (eq. A.22).

but with a different ratio of outer and inner radii to make it run faster.

## Referenced by

- Blog: https://petergrassl.com/blog/lattice-coupling-pressure-2d/

## The physics in one figure

`compare.pdf` plots the normalised radial displacement `u_r / r_i` against the
normalised radius `r / r_i` for two Biot coefficients, each as raw lattice nodes
(scatter) vs the analytical solution (line):

- **b = 0**: the fluid pressure acts only as a traction on the
  inner cavity wall — a classic pressurised cylinder. `u_r` *decreases* with
  radius, so the wall **thins**.
- **b = 1** (full Biot): the pore pressure additionally acts as a distributed
  body force throughout the wall. `u_r` *increases* with radius, so the wall
  **thickens**.

Biot's coefficient gives contrasting qualitative responses.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-coupling-pressure-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:lattice-coupling-pressure-2d bash run.sh
```

Or with a local build — `generator`, `qvoronoi`, `converter`, `oofem` on the
PATH, plus `python3` and `gnuplot`:

```bash
bash run.sh      # runs both Biot cases (b0/ and b1/) and the combined compare.pdf
bash b0/run.sh   # or run a single case on its own (self-contained)
bash clean.sh    # back to a git-clean folder (keeps b0/ b1/ sources + local/)
```

Each Biot case lives in its own self-contained folder — `b0/` (b = 0) and `b1/`
(b = 1) — holding its own `mesh.in`, `control.in` (the Biot value), `control.tm.in`,
`oofem.smtm.in`, `run.sh` and `compare.py`. The two cases differ only by the
`bio` value in `control.in`.

### Pipeline (each case folder, `b0/run.sh`)

1. `generator mesh.in` — seeds a random node cloud in the annulus (deterministic).
2. `qvoronoi` — Voronoi tessellation (dual transport lattice).
3. `converter control.in mesh.nodes mesh.voronoi` — writes the coupled
   `oofem.sm.in` (mechanical, Delaunay edges) and `oofem.tm.in` (transport,
   Voronoi edges) in one pass (`#@grid 2dSMTM`).
4. `oofem -f oofem.smtm.in` — staggered transport↔mechanical solve.
   `profileopt 1` reorders the skyline solver (~30× faster here).
5. `compare.py` + `gnuplot` — profiles and per-case `case.pdf`.

### Key input ingredients

- `#@coupling hole 1 neumann ltf 1 tmbc 2` — prescribes the inner fluid pressure
  on the transport rim and transfers it to the mechanical boundary.
- `#@edgebc region 1 bc 1` — holds the **outer** boundary at zero pore pressure
  (drainage), so the steady-state field is logarithmic (eq. A.7). Without this
  the outer boundary is insulated and the field would be uniform.
- `#@couplingflag` + `latticelinearelastic ... bio <b>` — the distributed Biot
  term `sigma_total = sigma_eff + b * P_f` in every mechanical element.
- zero capacity (`c 0.`) in `latticetransmat` → steady state each step.

The inner pressure is ramped 0 → −1e6 Pa over the steps (compression negative),
so the saved VTU frames animate the deformation in ParaView (warp by
*Displacement*). The displacement is linear in pressure, so the final step
equals the full-pressure response used for the graph.

### Output layout

```
b0/  b1/            self-contained per-Biot case folders:
  tracked sources:  mesh.in, control.in, control.tm.in, oofem.smtm.in,
                    run.sh, compare.py
  generated (gitignored): mesh.nodes, oofem.*.in/out, VTU + .pvd frames,
                    lattice.dat, analytic.dat, case.pdf. ParaView opens
                    b0/oofem.sm.out.m0.pvd (mechanical) or
                    b0/oofem.tm.out.m0.pvd (pore pressure).
compare.pdf         u_r/r_i vs r/r_i: raw lattice scatter vs analytical, both b
local/              maintainer-only, gitignored (repo-root **/local/)
  frames_b0/ frames_b1/   ParaView-rendered PNG sequences (deformed mesh)
  anim.sh           compose those PNGs into b0.mp4 | b1.mp4 -> cylinder.mp4
```

## Notes

- **Anchoring.** Rigid-body modes are removed by pinning three boundary control
  vertices (tangential constraints), not by enforcing perfect axisymmetry. This
  introduces some angular scatter in `u_r` at a given radius — visible in the
  plot and honest to the discrete model.
- **E vs E_c.** The analytical solution uses the continuum modulus `E_c`. The
  lattice input `E` equals `E_c` exactly only for a regular triangular lattice;
  this mesh is irregular, so the lattice displacements sit ~5–10 % off the
  analytical magnitudes. The *ratios* (inner/outer, i.e. the thinning-vs-
  thickening signature) match closely.
- **Resolution.** `#@diam 0.001` gives ≈1300 nodes (101 uniform rim nodes); the
  full two-case run takes ~25 s. Increase `#@diam` in `mesh.in` for a quicker,
  coarser demo, or decrease it for an even tighter scatter at the cost of runtime.
