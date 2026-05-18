# 2D unsaturated lattice transport — why lumped capacity matters

A 100×100 mm prism with van Genuchten unsaturated transport, run twice on
the same mesh: once with **lumped** capacity and once with the
**consistent** capacity matrix (default in OOFEM's
`latticemt2D`). Initially the specimen is partially unsaturated
(`u_IC = 2000` Pa, `S ≈ 0.45`); the bottom face is saturated (`u_BC = 0`)
from `t = 0`. The wetting front propagates upward through the steep `c(p)`
peak around `p ≈ a`, which is where the choice of capacity matrix matters.

| sub-test       | capacity matrix                         |
|----------------|-----------------------------------------|
| `lumped/`      | diagonal — monotone, no overshoot       |
| `consistent/`  | row-sum-preserving 2×2 off-diagonal     |

The classical Celia–Bouloutas–Zarba (1990) result for Richards-type
problems: with the consistent capacity matrix, the off-diagonal coupling
produces transient overshoots above the dry-side initial value that
linger because the relative permeability `k_r(p)` is asymmetric (high on
the wet side → fast damping, low on the dry side → slow damping). Lumped
capacity is row-monotone and avoids the overshoot entirely.

In this run the consistent variant overshoots the IC bound (`p = 2000`)
by ~17% around step 50, with the overshoot localised to a narrow band at
the moving wetting front. By step 200 the overshoot has dissipated and
both variants agree on the long-term profile.

## Adaptive time stepping

A direct step from `u_IC = 2000` to `u_BC = 0` with a fixed `dt` gives
Picard a nearly-singular first-step Jacobian (the dry-side `k_r ≈ 0.7%`).
This example uses OOFEM's `deltatfunction` to drive the solver with a
**piecewise-linear `dt` schedule** indexed by step:

    PiecewiseLinFunction 2 nPoints 3 t 3 0. 50. 500. f(t) 3 1e-6 1e-6 1e-4

→ `dt = 10⁻⁶` for the first 50 steps (absorbs the initial Jacobian
stiffness), then growing linearly to `dt = 10⁻⁴` by step 500. Standard
Picard converges throughout for both variants — even with the step BC.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-flow-2d-lumped
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

Or with a local checkout and `test.sh`:

```bash
./test.sh ghcr.io/githubgrasp/oofem-public:latest
cd /work/lattice-flow-2d-lumped
bash run-all.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-flow-2d-lumped`.

Outputs (per sub-test, in `lumped/` and `consistent/`):

| file                            | content                                     |
|---------------------------------|---------------------------------------------|
| `oofem.in`                      | OOFEM input (assembled by `converter`)      |
| `std.out`                       | OOFEM stdout                                |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView             |
| `profile_<step>.dat`            | per-node `(x, y, p)` at snapshot steps      |
| `profile_<step>_binned.dat`     | per-y-band `(y, p_mean, p_max)` for plotting|

Top-level outputs:

| file           | content                                                  |
|----------------|----------------------------------------------------------|
| `compare.pdf`  | 2×2 panels at steps 10/30/50/80 (max-per-band lines)     |
| `compare.png`  | same as PDF, 1200×1200 PNG for LinkedIn/blog             |

`bash clean.sh` (at this level) removes everything generated across both
sub-tests.

## Workflow per sub-test

Each `run.sh` runs the standard four-step pipeline:

1. `generator mesh.in` → `mesh.nodes`
2. `qvoronoi p Fv < mesh.nodes > mesh.voronoi`
3. `converter control.in mesh.nodes mesh.voronoi` → `oofem.in`
4. `oofem -f oofem.in > std.out` → `oofem.out.m0.*.vtu`

Then at the parent level, `compare.py` extracts profiles and `gnuplot`
overlays both variants on the same 2×2 figure with a dashed reference
line at the IC bound.

## Inputs you can edit

| file                       | knobs to play with                                            |
|----------------------------|---------------------------------------------------------------|
| `*/mesh.in`                | node spacing (`#@diam`), domain size (`#@rect`)               |
| `*/control.in`             | material (`latticetransmat` vG params), `dt` schedule         |
| `compare.py`               | which steps to sample (`STEPS`), bin width                    |

The only difference between the two `control.in` files is the
`#@lumpedcapacity 1` directive: present in `lumped/`, absent in
`consistent/`.

## Material parameters (van Genuchten, mild)

`latticetransmat 1 d 1. k 1.e-4 vis 1. thetas 1. thetar 0. thetam 1. contype 1 m 0.5 a 1000. paev 0.`

| parameter | value    | meaning                              |
|-----------|----------|--------------------------------------|
| `k`       | 10⁻⁴     | intrinsic permeability               |
| `vis`     | 1        | viscosity                            |
| `m`       | 0.5      | van Genuchten shape (≡ `n = 2`)      |
| `a`       | 1000 Pa  | air-entry suction (peak of `c(p)`)   |
| `thetas`  | 1        | saturated water content              |
| `thetar`  | 0        | residual water content               |
| `paev`    | 0        | suction below which `k_r = 1`        |

Mild curves were chosen deliberately so both lumped and consistent
converge — the textbook benchmark regime (Celia et al. 1990). With
sharper concrete-like parameters the consistent variant typically fails
to converge at all (see the project memory on adaptive-`dt` patterns).

## Referenced by

- Blog post: *(to be written)*
- Celia, M. A., Bouloutas, E. T. & Zarba, R. L. (1990). *A general
  mass-conservative numerical solution for the unsaturated flow
  equation.* Water Resources Research, 26(7), 1483–1496.
  [doi:10.1029/WR026i007p01483](https://doi.org/10.1029/WR026i007p01483)
