# 2D direct tensile lattice — random vs uniform e0

Two 2D Voronoi-lattice analyses of a 100×100 mm concrete prism in direct
uniaxial tension on a periodic mesh. Same geometry, same mean
material parameters; only the spatial distribution of `e0` (the
elastic-strain threshold for damage initiation) differs.

| sub-test    | `e0`                                                  | crack pattern                                                       |
|-------------|-------------------------------------------------------|---------------------------------------------------------------------|
| `uniform/`  | constant across the specimen                          | tortuous (mesh randomness only); localises at peak                  |
| `random/`   | random field via `genran` (mean and autocorrelation length set in `random.in`) | tortuous (mesh + field randomness); disconnected cracks earlier, lower peak   |

The random field is generated with [`genran`](https://github.com/githubgrasp/genran)
using the spectral representation of Shinozuka & Deodatis. It supports
Gaussian, Weibull, and grafted Weibull–Gaussian distributions
and a Gaussian-shaped autocorrelation. The lattice picks up the field
through the `InterpolatingFunction` directive in `control.in`, which
multiplies the per-element `e0` by the field value at the element's
Gauss point.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-tensile-random-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

Or with a local checkout of `oofem-examples`:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
./test.sh                           # opens shell in oofem-private container
cd /work/lattice-tensile-random-2d/random
bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-tensile-random-2d`.

Each sub-test produces in its own folder:

| file                 | content                                          |
|----------------------|--------------------------------------------------|
| `oofem.in`           | OOFEM input (assembled by `converter`)           |
| `std.out`            | OOFEM stdout incl. quasi-reaction table          |
| `oofem.out`          | OOFEM solver output                              |
| `oofem.out.m0.*.vtu` | per-step VTU files for ParaView                  |
| `ld.dat`             | extracted load-displacement (m, N)               |
| `ld.pdf`             | load-displacement curve (mm, kN)                 |

`bash clean.sh` (at this level) removes everything generated across both,
including the parent-level `ld-compare.pdf`.

## Workflow per sub-test

`random/run.sh` runs a five-step pipeline:

1. `generator mesh.in` — random node distribution → `mesh.nodes`.
2. `qvoronoi p Fv < mesh.nodes > mesh.voronoi` — Voronoi tessellation.
3. `genran random.in random.dat` — generate the spectral random field.
4. `converter control.in mesh.nodes mesh.voronoi` — builds the lattice
   topology and assembles `oofem.in`. The `InterpolatingFunction`
   directive in `control.in` reads `random.dat`.
5. `oofem -f oofem.in > std.out` — solve.

`uniform/run.sh` skips step 3 — `control.in` has no `InterpolatingFunction`
and the `latticedamage` material uses a constant `e0`.

## Inputs you can edit

| file                | knobs to play with                                                              |
|---------------------|---------------------------------------------------------------------------------|
| `random/random.in`  | random seed (`ranint`), autocorrelation length (`autoLength*`), grid resolution |
| `*/control.in`      | material parameters (`latticedamage`), load history, time stepping              |
| `*/mesh.in`         | node minimum distance (`#@diam`), domain size (`#@rect`)                        |

Try changing `ranint` in `random/random.in` to see how a different
realisation of the same field statistics shifts the crack location.

## Material parameters (lattice damage)

Mean values, identical in both `control.in` files (on the `latticedamage` line).

| parameter | value     | meaning                              |
|-----------|-----------|--------------------------------------|
| `e`       | 30 GPa    | elastic modulus                      |
| `e0`      | 100×10⁻⁶  | mean strain at peak tensile stress   |
| `wf`      | 33 µm     | crack opening at zero stress (mode I)|
| `coh`     | 2.0       | shear-to-tension cohesion ratio      |
| `ec`      | 10        | compressive-to-tensile strength ratio|

In `random/`, `e0` is multiplied per Gauss point by the value sampled
from the random field.

## Referenced by

- Blog post: https://petergrassl.com/blog/lattice-tensile-random-2d/
