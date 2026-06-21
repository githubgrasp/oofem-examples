# 3D lattice — SFRC cube with random ft and fibres bridging the crack

A 30 × 30 × 30 mm periodic cube of concrete with `Vf = 1%` straight steel
fibres (length 15 mm, diameter 0.4 mm — about 140 fibres for this volume).
The matrix tensile strength is randomised on a Gaussian field with
mean 1, CoV 0.2 and autocorrelation length 10 mm. The cube is pulled
in uniaxial tension via a periodic-cell `hpc` constraint; the matrix
damages and localises into a crack plane; the fibres crossing that
plane bridge it, extending the post-peak softening branch.

The purpose is to show the lattice-with-fibres pipeline of the 2019
paper applied to a small SFRC cell that runs in minutes:

1. **Fibre placement** with the `aggregate` packer (no aggregates — just
   `#@fibres`). Periodic, deterministic.
2. **Material heterogeneity** with `genran` — same correlated Gaussian
   field as in the corrosion and tensile examples.
3. **Discretisation** by the `converter`: each fibre is split into
   axial lattice segments + per-node `latticelink3D` bonds to the
   nearest matrix Voronoi nodes. Fibres are `lattice3d` with `shape 1
   radius` (circular cross-section); the legacy `latticeframe*` family
   is not used.
4. **Three-material lattice**: `latticedamage` matrix, `latticelinearelastic`
   steel fibres, `latticeslip` MC2010-style bond.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-fibre-3d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-fibre-3d`.

Outputs:

| file                            | content                                          |
|---------------------------------|--------------------------------------------------|
| `packing.dat`                   | aggregate placer output (fibre endpoints)        |
| `random.dat`                    | spectral random field for `ft`                   |
| `nodes.dat`, `voronoi.dat`      | lattice node coordinates + Voronoi facets        |
| `oofem.in`                      | OOFEM input (assembled by `converter`)           |
| `std.out`                       | OOFEM stdout incl. quasi-reaction table          |
| `oofem.out`                     | OOFEM solver output                              |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                  |
| `oofem.out.m1.*.gp`             | per-step Gauss-point data                        |

`bash clean.sh` removes everything generated.

## Workflow

```bash
aggregate aggregate.in                           # → packing.dat
genran    random.in random.dat                   # → random.dat
generator mesh.in                                # → nodes.dat
qvoronoi  p Fv < nodes.dat > voronoi.dat         # → voronoi.dat
converter control.in nodes.dat voronoi.dat       # → oofem.in
oofem -f  oofem.in > std.out                     # → oofem.out.*
```

## Inputs you can edit

| file           | knobs to play with                                                                 |
|----------------|------------------------------------------------------------------------------------|
| `aggregate.in` | `#@fibres fraction / length / diameter`, `#@box`, `#@seed`                         |
| `random.in`    | `ranint`, `autoLength*`, grid size                                                 |
| `mesh.in`      | matrix lattice spacing (`#@diam`), prism size (`#@prism`)                          |
| `control.in`   | concrete (`latticedamage`), fibre (`latticelinearelastic`), bond (`latticeslip`), load history, time stepping |

## Material parameters

| material | role                                | key parameters                                       |
|----------|-------------------------------------|------------------------------------------------------|
| 1        | concrete matrix                     | `e 30 GPa`, `e0 100e-6` (`ft ≈ 3 MPa`), `wf 40 µm`, random multiplier on `e0` via `randvars 1 800` |
| 2        | steel fibre (`shape 1 radius 0.2 mm`)| `em 200 GPa`, `nu 0.3`                              |
| 3        | matrix-to-fibre bond (`latticeslip`) | `t0 4 MPa`, `s1 10 µm`, MC2010 ribbed-bar values    |

## Further reading

The lattice-with-fibres approach used here is developed in:

> P. Grassl, A. Antonelli. *3D network modelling of fracture processes
> in fibre-reinforced geomaterials.* International Journal of Solids
> and Structures, vol. 156–157, pp. 234–242, 2019.
> [DOI](https://doi.org/10.1016/j.ijsolstr.2018.08.019)

## Referenced by

- Blog post: https://petergrassl.com/blog/lattice-fibre-3d/
