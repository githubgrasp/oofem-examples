# 2D direct tensile lattice — periodic vs regular mesh

Two 2D Voronoi-lattice analyses of a 100×100 mm concrete prism in direct
uniaxial tension, identical in every respect except the meshing strategy.

| sub-test    | mesh                          | crack pattern                |
|-------------|-------------------------------|------------------------------|
| `periodic/` | doubly-periodic Voronoi mesh  | crack inside the specimen    |
| `regular/`  | non-periodic Voronoi mesh     | crack locked to the boundary |

In direct tension, a non-periodic lattice forces every element near the
loaded face to terminate at that face. The shortest-path crack runs along
the boundary instead of through the bulk material — an artefact of the
discretisation, not of the material.

Rebuilding the mesh so elements cross the boundary and connect to their
counterparts on the opposite face removes the artefact: the crack now
reflects the heterogeneity of the random particle distribution.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-tensile-periodic-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

Or with a local checkout of `oofem-examples`:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
./test.sh                           # opens shell in oofem-private container
cd /work/lattice-tensile-periodic-2d/periodic
bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-tensile-periodic-2d`.

Each sub-test produces in its own folder:

| file                 | content                                          |
|----------------------|--------------------------------------------------|
| `oofem.in`           | OOFEM input (assembled by `converter`)           |
| `std.out`            | OOFEM stdout incl. quasi-reaction table          |
| `oofem.out`          | OOFEM solver output                              |
| `oofem.out.m0.*.vtu` | per-step VTU files for ParaView                  |
| `ld.dat`             | extracted load-displacement (m, N)               |
| `ld.pdf`             | load-displacement curve (mm, kN)                 |

`bash clean.sh` (at this level) removes everything generated across both.

## Workflow per sub-test

Each `run.sh` runs the same four-step pipeline:

1. `generator mesh.in` — random particle distribution → `nodes.dat`.
2. `qvoronoi p Fv < mesh.nodes > mesh.voronoi` — Voronoi tessellation.
3. `converter control.in mesh.nodes mesh.voronoi` — builds the lattice
   topology, merges with `control.in` to produce `oofem.in`.
4. `oofem -f oofem.in > std.out` — solve.

The only difference between the two sub-tests is the periodicity flag
(`#@perflag`) in `mesh.in` and a small change in `control.in` for the
displacement-control node setup.

## Inputs you can edit

| file         | knobs to play with                                                                        |
|--------------|-------------------------------------------------------------------------------------------|
| `mesh.in`    | particle diameter (`#@diam`), domain size (`#@rect`), periodicity flag (`#@perflag`)      |
| `control.in` | material parameters (`latticedamage`), load history (`PiecewiseLinFunction`), time stepping |

## Material parameters (lattice damage)

Same in both `control.in` files (on the `latticedamage` line).

| parameter | value     | meaning                              |
|-----------|-----------|--------------------------------------|
| `e`       | 30 GPa    | elastic modulus                      |
| `e0`      | 100×10⁻⁶  | strain at peak tensile stress        |
| `wf`      | 33 µm     | crack opening at zero stress (mode I)|
| `coh`     | 2.0       | shear-to-tension cohesion ratio      |
| `ec`      | 10        | compressive-to-tensile strength ratio|

## Referenced by

- Blog post: https://petergrassl.com/blog/lattice-tensile-periodic-2d/
