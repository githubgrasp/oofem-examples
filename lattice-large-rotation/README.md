# Large-rotation lattice: a cantilever bent into a full circle

A slender cantilever driven by a prescribed end rotation of a full turn
(2 pi), curling from straight into a **closed circle** is presented. It is the simplest
benchmark for the large-rotation (geometrically nonlinear) lattice element
`lattice3dnl` (the rigid-body–spring frame element of Abdelrhim and Grassl
(2026), see [Further reading](#further-reading)). It is a problem whose exact
solution is known in closed form, so the lattice solution can be checked against it.

## Referenced by

- 2026-08 Blog: https://petergrassl.com/blog/lattice-large-rotation/

## The problem

A straight elastic rod of length L = 9.42 m is clamped at one end. A
moment is applied at the free end by prescribing its rotation from `0` up to
`2 pi`. Under a pure end moment the exact deformed shape is a **circular arc** of
radius

    R = EI / M = L / θ

so as the end rotation `θ` sweeps from `0` to `2π` the rod passes through a
quarter circle, a semicircle (`θ = π`, radius `L/π ≈ 3.0 m`), and finally
closes into a full circle (`θ = 2π`, radius `L/2π ≈ 1.5 m`) whose free end
returns exactly to the clamped end. The moment–rotation response is linear,

    M = (EI / L) · θ,

The test is whether the element can carry the rotation all the way to `2π` — far outside
the small-rotation range — and still return the linear moment history and a
shape that closes on itself and converges to the circle.

## The model

| item          | value                                                        |
|---------------|--------------------------------------------------------------|
| element       | `lattice3dnl` (large-rotation 3D lattice/frame)              |
| discretisation| 8 equal elements, 9 nodes                                    |
| section       | circular, `r = 10 mm` (`A = 3.14e-4 m²`, `I = 7.86e-9 m⁴`)   |
| material      | `latticeframeelastic`, `E = 210 GPa`, `ν = 0.3` (steel)      |
| clamp         | node 1, all six DOFs fixed                                   |
| drive         | node 9, rotation `θz` prescribed `0 → 2π` (rotation control) |
| steps         | 100 (`NonlinearStatic`, `controlmode 1`)                     |

The analysis is **rotation-controlled**: the end rotation is imposed and the
reaction moment is read back, which traces the response robustly all the way
to the closed circle.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-large-rotation/8El
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-large-rotation`.

Or, with OOFEM and the post-processing tools already on your `PATH`:

```bash
cd oofem-examples/lattice-large-rotation/8El
bash run.sh
```

This runs the analysis and post-processes it: `extractor.py` pulls the
moment–rotation history into `ld.dat`, and `post.pl` writes one deformed-shape
file per step (`outputStep*.dat`) — the nodal coordinates plus displacements,
ready to plot or animate.

## Outputs

| file                    | content                                             |
|-------------------------|-----------------------------------------------------|
| `oofem.out.m0.*.vtu`    | per-step VTU for ParaView                            |
| `ld.dat`                | nodal displacements + end rotation + reaction moment |
| `outputStep*.dat`       | deformed `(x, y)` shape per step (for the animation) |

## The data in `ld.dat`

Each row is one step. Columns `1–9` are the `x`-displacements of nodes `1–9`,
columns `10–18` the `y`-displacements, column `19` the prescribed end rotation
(`0 → 6.283`), and column `20` the reaction moment at the free end
(`0 → 1100.5 N·m`). Plotting column 20 against column 19 gives the straight
line `M = (EI/L)·θ`; the exactness of the circle is easiest to see in the
`outputStep*.dat` shapes, where the final step returns node 9 to the origin.

## Further reading

The large-rotation lattice element `lattice3dnl` is a rigid-body–spring frame
element extended to arbitrarily large rotations; this cantilever is one of the
classical bending benchmarks it is verified against. It is developed in:

> G. Abdelrhim and P. Grassl. *A 3D frame element for large rotations based on
> the rigid-body–spring concept for analysing the failure of structures.*
> International Journal of Solids and Structures, vol. 327, 113812, 2026.
> [DOI](https://doi.org/10.1016/j.ijsolstr.2025.113812)
