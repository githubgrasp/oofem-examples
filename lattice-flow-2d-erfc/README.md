# 2D lattice transport — verification against 1D analytical (erfc)

A 100×100 mm prism with prescribed pressure on the bottom face and zero
pressure (dry) initial condition everywhere else. Linear, isotropic
transport (constant capacity `c` and permeability `k`), so the governing
equation reduces to 1D diffusion with diffusivity `D = k / (vis · c)`. The
analytical solution is the classical finite-slab series

    p(y, t) = 1 - Σ_n [4/((2n+1)π)] sin((2n+1)π y / (2H)) exp(-((2n+1)π/(2H))² D t)

which the lattice must reproduce. The total run time is short enough that
the far face stays at `p ≈ 0`, so the early-time semi-infinite limit
`p(y, t) ≈ erfc(y / (2√(D t)))` is also a useful intuition.

The purpose of this example is twofold:

1. **Introduce the transport lattice as the geometric dual** of the
   mechanical lattice. Both share the underlying Voronoi–Delaunay
   tessellation, but each lives on a different part of the duality:
   structural frame elements (`latticedamage`) along the Delaunay
   edges, transport conduit elements (`latticemt2D`) along the dual
   Voronoi edges.
2. **Verify** that the discrete transport scheme matches the continuum
   solution to mesh-randomness accuracy (~3% at this resolution).

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-flow-2d-erfc
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

Or with a local checkout and `test.sh`:

```bash
./test.sh ghcr.io/githubgrasp/oofem-public:latest
cd /work/lattice-flow-2d-erfc
bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-flow-2d-erfc`.

Outputs:

| file                            | content                                          |
|---------------------------------|--------------------------------------------------|
| `oofem.in`                      | OOFEM input (assembled by `converter`)           |
| `std.out`                       | OOFEM stdout                                     |
| `oofem.out`                     | OOFEM solver output                              |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                  |
| `profile_<step>.dat`            | per-node `(x, y, p)` at four snapshot steps      |
| `analytical_<step>.dat`         | finite-slab analytical `(y, p)` at the same `t`  |
| `compare.pdf`                   | 2×2 panels: lattice scatter + analytical curve   |

`bash clean.sh` removes everything generated.

## Workflow

```bash
generator mesh.in                                # → mesh.nodes
qvoronoi p Fv < mesh.nodes > mesh.voronoi        # → mesh.voronoi
converter control.in mesh.nodes mesh.voronoi     # → oofem.in
oofem -f oofem.in > std.out                      # → oofem.out.m0.*.vtu
python3 compare.py                               # → profile_*.dat, analytical_*.dat
gnuplot ... (inline in run.sh)                   # → compare.pdf
```

`compare.py` parses each requested VTU, extracts the nodal pressure
field, and writes per-step text files plus an analytical reference on the
same time grid. The plot overlays lattice scatter on the analytical curve.

## Inputs you can edit

| file         | knobs to play with                                                   |
|--------------|----------------------------------------------------------------------|
| `mesh.in`    | node spacing (`#@diam`), domain size (`#@rect`)                      |
| `control.in` | material (`latticetransmat`: `k`, `vis`, `c`), `nsteps`, `deltat`    |
| `compare.py` | which steps to sample (`STEPS`), analytical truncation (`NTERMS`)    |

## Material parameters (constant linear transport)

`latticetransmat 1 d 1. k 1.e-4 vis 1. c 1. thetas 1. thetar 0.`

| parameter | value   | meaning                          |
|-----------|---------|----------------------------------|
| `d`       | 1       | density                          |
| `k`       | 10⁻⁴    | intrinsic permeability           |
| `vis`     | 1       | viscosity                        |
| `c`       | 1       | volumetric capacity              |
| `thetas`  | 1       | saturated water content          |
| `thetar`  | 0       | residual water content           |

→ diffusivity `D = k / (vis · c) = 10⁻⁴ m²/s`. Run length 5 s ⇒ diffusion
length `√(D·t) ≈ 22 mm`, well below the 100 mm specimen height (semi-
infinite regime).

## Referenced by

- Blog post: *(to be written)*
