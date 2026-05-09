# Dynamic fracture of a notched plate — local vs nonlocal damage

Two explicit-dynamic OOFEM analyses of a 254×254 mm cruciform Homalite-100
specimen with a 50 mm central crack under biaxial impulsive loading. Same
geometry, same mesh, same elastic and damage parameters; only the
regularisation of the damage model differs.

| sub-test    | material      | regularisation                                       | what to expect                                                          |
|-------------|---------------|------------------------------------------------------|-------------------------------------------------------------------------|
| `idm1/`     | `idm1`        | crack-band scaling of softening (Bažant & Oh)        | mesh-independent fracture energy, but band width follows the mesh        |
| `idm1nl/`   | `idmnl1`      | nonlocal averaging, radius `r=2 mm`                  | mesh-independent fracture energy *and* band width (~`r`)                 |

The geometry, material (Homalite-100, E ≈ 5 GPa, ρ = 1230 kg/m³), and biaxial
loading ratio `B = Fx/Fy ≈ 0.33` correspond to one of the dynamic-photoelastic
tests reported by Hawong, Kobayashi, Dadkhah, Kang & Ramulu, "Dynamic Crack
Curving and Branching Under Biaxial Loading", *Experimental Mechanics* (1987),
[doi.org/10.1007/BF02319466](https://doi.org/10.1007/BF02319466). The
experiments use a 16-spark-gap Cranz–Schardin camera to capture the
isochromatic fringes around the propagating crack over the ~600 µs fracture
event. The simulation aims to recover the qualitative crack path and timing,
not to fit any one stress-intensity history quantitatively.

The contrast between the two sub-tests is a standard pedagogical point for
strain-softening damage in dynamics. `idm1` already uses the crack-band
approach of Bažant & Oh: the softening law is scaled by the element size so
that the dissipated energy per unit crack area equals `gf` regardless of mesh
refinement. What it does **not** fix is the spatial extent of the localisation
or the crack path — strains collapse onto a single row of elements, so the
crack travels along mesh lines. The nonlocal model `idmnl1` averages the equivalent
strain over a fixed length scale `r`, which sets a material-controlled band width
and lets the crack curve and branch independently of the mesh.

## Reproduce

> Each analysis takes more than 30 minutes on a recent laptop (`NlDEIDynamic`
> explicit time integration, ~1000+ steps with VTK output every 10 steps).
> Don't run this on a coffee break — start it in the background or overnight.

The committed `oofem.in` in each sub-folder has the mesh baked in, so the
analysis runs as-is:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/nonlocal-dynamic-idm1/idm1
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh --yes
```

Regenerating the mesh from `mesh.in` requires the
[T3D mesh generator](http://mech.fsv.cvut.cz/~dr/t3d.html), which is not
bundled in the public Docker image. If `t3d` and `t3d2oofem` are on your
`PATH`, `run.sh` automatically picks them up; otherwise it falls back to the
committed `oofem.in`.

## Workflow per sub-test

`run.sh` runs:

1. *(only if t3d available)* `t3d -X -i mesh.in -o mesh.out -d 0.001 -p 512`
2. *(only if t3d2oofem available)* `t3d2oofem oofem.t3d.ctrl mesh.out oofem.in`
3. `oofem -f oofem.in > std.out` — explicit dynamic solve.

`bash clean.sh` removes the generated VTU files, `std.out`, and `mesh.out`
but **keeps** `oofem.in` so the no-T3d path still works after a clean.

## Inputs you can edit

| file                  | knobs to play with                                                                  |
|-----------------------|-------------------------------------------------------------------------------------|
| `*/mesh.in`           | T3d geometry; element size via `-d` on the first line                                |
| `*/oofem.t3d.ctrl`    | engng-model record (time step, nsteps, output frequency), material, BCs, loads      |
| `idm1/oofem.in`       | mesh.in is regenerated from this in absence of t3d. Direct edits to the assembled file are also possible. |
| `idm1nl/oofem.in`     | same, plus the nonlocal radius `r` on the `idmnl1` material line                    |

After editing `oofem.t3d.ctrl` or `mesh.in`, re-run `run.sh` inside a t3d-capable
environment (private Docker image) to regenerate `oofem.in`.

## Material parameters

Approximate values for Homalite-100, identical elastic and damage initiation in
both cases. The only difference is the regularisation.

| parameter   | value         | meaning                                  |
|-------------|---------------|------------------------------------------|
| `d`         | 1230 kg/m³    | mass density                             |
| `E`         | 5.3 GPa       | Young's modulus                          |
| `n`         | 0.3           | Poisson's ratio                          |
| `e0`        | 1.61×10⁻³     | strain at peak tensile stress            |
| `gf` *(local)*    | 88 J/m²    | fracture energy (`idm1`)                 |
| `r`  *(nonlocal)* | 2 mm       | nonlocal interaction radius (`idmnl1`)   |
| `ef` *(nonlocal)* | 5.16×10⁻³  | exponential softening parameter          |

## Time integration

`NlDEIDynamic` (nonlinear dynamic, explicit), `deltat = 2×10⁻⁷ s`,
1000 steps nominal (the solver auto-reduces `deltat` to satisfy the CFL
stability limit, bringing the step count to ~1074). VTK output every 10 steps.

## Referenced by

- Blog post: https://petergrassl.com/blog/nonlocal-dynamic-idm1/
