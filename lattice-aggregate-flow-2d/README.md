# 2D lattice transport through a heterogeneous matrix with circular inclusions

A 100×100 mm prism populated with randomly-placed low-permeability
circular inclusions in a high-permeability matrix, with prescribed
pressure on the bottom face and dry initial condition everywhere else.
Linear constant-capacity transport (lumped). The story is **heterogeneity**:
the wetting front threads around the impermeable inclusions, and the 2D
field shows the deflection.

The other two flow examples in this directory isolate a single variable
each (`lattice-flow-2d-erfc/` validates the discretisation against the 1D
analytical; `lattice-flow-2d-lumped/` explores lumped vs consistent
capacity). This example holds those constant — linear constant `c` /
`k`, lumped capacity — and varies only the spatial distribution of
material properties.

| material  | `k`         | `D = k/(vis·c)` |
|-----------|-------------|-----------------|
| matrix    | 2×10⁻⁵      | 2×10⁻⁵ m²/s     |
| aggregate | 2×10⁻⁹      | 2×10⁻⁹ m²/s     |

Matrix `k` is set so the front reaches ~45 mm into the specimen over
the 100 s run — the bottom half, where the front threads visibly
around several rows of aggregates. The 10⁴× matrix/aggregate contrast
keeps each aggregate effectively dry throughout (aggregate diffusion
length `≈ 0.45 mm`, well below the 2.5–6 mm aggregate radii).

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-aggregate-flow-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

Or with a local checkout and `test.sh`:

```bash
./test.sh ghcr.io/githubgrasp/oofem-public:latest
cd /work/lattice-aggregate-flow-2d
bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-aggregate-flow-2d`.

Outputs:

| file                            | content                                          |
|---------------------------------|--------------------------------------------------|
| `packing.dat`                   | random aggregate packing (from `aggregate`)      |
| `mesh.nodes`, `mesh.voronoi`    | random node distribution + Voronoi tessellation  |
| `oofem.in`                      | OOFEM input (assembled by `converter`)           |
| `std.out`                       | OOFEM stdout                                     |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                  |

`bash clean.sh` removes everything generated.

## Workflow

```bash
aggregate aggregate.in                           # → packing.dat
generator mesh.in                                # → mesh.nodes
qvoronoi p Fv < mesh.nodes > mesh.voronoi        # → mesh.voronoi
converter control.in mesh.nodes mesh.voronoi    \
  packing.dat                                    # → oofem.in
oofem -f oofem.in > std.out                      # → oofem.out.m0.*.vtu
```

The aggregate packing is fed to the converter via the `#@inclusionfile`
directive in `control.in`, which routes any lattice element with at
least one endpoint inside an aggregate disk to the low-permeability
material (`mat 2`).

## Inputs you can edit

| file            | knobs to play with                                                     |
|-----------------|------------------------------------------------------------------------|
| `aggregate.in`  | aggregate grading (`#@grading`), packing seed (`#@seed`)               |
| `mesh.in`       | node spacing (`#@diam`), periodicity (`#@perflag`)                     |
| `control.in`    | matrix vs aggregate `k`, BC face (`#@nodebc`), capacity flag           |

## Material parameters

| line                       | role             | `k`        | `c`   |
|----------------------------|------------------|------------|-------|
| `latticetransmat 1 ...`    | matrix           | 2×10⁻⁵     | 1     |
| `latticetransmat 2 ...`    | aggregate        | 2×10⁻⁹     | 1     |

Both materials use `contype 0` (constant linear) so the example focuses
entirely on the spatial heterogeneity rather than constitutive
nonlinearity.

## Referenced by

- Blog post: *(to be written)*
