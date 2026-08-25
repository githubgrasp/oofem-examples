# Buckling of a strut: elastic and elasto-plastic, with the large-rotation lattice model

A slender imperfect strut pinned on both sides is compressed until it buckles, modelled with the
large-rotation lattice element `lattice3dnl` (the rigid-body–spring frame
element of Abdelrhim and Grassl (2026), see [Further reading](#further-reading)).
Two responses are compared against the exact post-buckling repsonse of the
perfect strut:

- **elastic** — the load rises *above* the critical Euler buckling load as the strut deflects
  laterally, and the imperfect lattice converges onto the solution of the perfect strut;
- **elasto-plastic** — a plastic hinge forms and the load *drops* soon after
  buckling.

## Referenced by

- 2026-08 Blog: https://petergrassl.com/blog/lattice-buckling/

## The problem

A straight elastic strut of length `L = π m`, pinned at both ends, is loaded in
axial compression by a prescribed end shortening. The classical result is that
it stays straight until the axial load reaches the Euler critical load

    Pcr = π² EI / L²   =   EI   =   1.66e6 N   (here L = π, so Pcr = EI)

and then buckles laterally. For the *perfect* strut the load keeps rising slowly above `Pcr` as the lateral
deflection grows (large-displacement stiffening). This branch is computed
independently in MATLAB (`Matlab/`) and shipped as `Matlab/matlabPerfect.dat`
(end rotation `θ` vs `P/Pcr`) — the reference the lattice is checked against.

The model carries a small **half-sine geometric imperfection**, amplitude `≈ 0.03 m` (`≈ L/100`), peaking
at midspan. The imperfection removes the sharp bifurcation: the strut starts to
deflect from the first load increment, reaches `Pcr` **later and at larger
lateral deflection**, and then converges onto the perfect elastica.

The *same* imperfect geometry is run with one material throughout — every
element identical — in two variants:

| case      | folder      | material (all elements)      | what happens                                         |
|-----------|-------------|------------------------------|------------------------------------------------------|
| elastic   | `elastic/`  | `latticeframeelastic`        | load climbs to `P/Pcr ≈ 1.46`, tracking the theory   |
| plastic   | `plastic/`  | `latticeframesteelplastic`   | load peaks at `P/Pcr ≈ 0.48`, then softens           |

In the elasto-plastic case the large lateral deflection before `Pcr` drives the
bending moment at midspan up to the yield surface, activating a **plastic
hinge** that reduces the load. Although *every* element is free to yield, the plastic
deformation **localises into the single midspan element**: it yields first, the
structure softens, and the drop in load unloads every other element
elastically, so none of them ever reaches yield.

Compared with the [large-rotation cantilever](../lattice-large-rotation/), this
example adds the **coupling of axial force and bending** and the **formation of
plastic hinges** on top of the same large-rotation kinematics.

## The model

| item           | value                                                                  |
|----------------|------------------------------------------------------------------------|
| element        | `lattice3dnl` (large-rotation 3D lattice/frame)                        |
| discretisation | 11 equal elements, 12 nodes                                            |
| geometry       | pin-pin strut, chord `L ≈ 3.14 m`, half-sine imperfection `≈ L/100`    |
| section        | `area = 0.01 m²`, `Iy = Iz = 8.3e-6 m⁴`, `Ik = 16.6e-6 m⁴`, `shape 3`  |
| material       | `E = 200 GPa`, `ν = 0.3` (steel); one material for all elements         |
| plastic yield  | `Nx0 = 2.0e6 N`, `Mx0 = 0.0889e6`, `My0 = Mz0 = 0.05e6 N·m` (plastic)  |
| supports       | node 1 pinned (rotation free), node 12 axial roller                    |
| drive          | prescribed end shortening at node 12 (displacement control)            |
| steps          | 1000 (`NonlinearStatic`, `controlmode 1`)                             |

`Pcr = EI = 1.66e6 N` is used to normalise the load; the perfect
reference solution is already stored as `P/Pcr`.

## Reproduce

With the public Docker image (no compilation needed), run each case in its
folder:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-buckling/elastic
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
cd ../plastic
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag
`ghcr.io/githubgrasp/oofem-public:lattice-buckling`.

Or, with OOFEM and the post-processing tools already on your `PATH`:

```bash
cd oofem-examples/lattice-buckling/elastic && bash run.sh
cd ../plastic && bash run.sh
```

`run.sh` runs the analysis and post-processes it: `extractor.py` pulls the
load-rotation history into `ld.dat`.

## Outputs

| file                               | content                                          |
|------------------------------------|--------------------------------------------------|
| `<case>/oofem.out.m0.*.vtu`        | per-step VTU for ParaView (deformed strut)       |
| `plastic/oofem.out.m0.*.cross.vtu` | rigid-body cross-sections for ParaView           |
| `<case>/ld.dat`                    | load-rotation history (see column map below)     |
| `Matlab/matlabPerfect.dat`         | perfect-strut elastica reference (`θ` vs `P/Pcr`) |

## The data in `ld.dat`

Each row is one step. Column `1` is the end rotation `θ` at the pin (rad),
column `2` the axial reaction = applied load `P` (N), column `3` the step,
columns `4–15` the axial (x) displacements of nodes `1–12`, and columns
`16–27` the lateral (y) displacements of nodes `1–12` (midspan = columns
`21/22`). Plotting `column 2 / 1.66e6` against `column 1` gives `P/Pcr` vs `θ`,
directly comparable with `Matlab/matlabPerfect.dat`.

## Further reading

The large-rotation lattice element `lattice3dnl` is a rigid-body based frame
element for large rotations, with coupled axial–bending
plasticity; this buckling strut is one of the benchmarks in

> G. Abdelrhim and P. Grassl. *A 3D frame element for large rotations based on
> the rigid-body–spring concept for analysing the failure of structures.*
> International Journal of Solids and Structures, vol. 327, 113812, 2026.
> [DOI](https://doi.org/10.1016/j.ijsolstr.2025.113812)
