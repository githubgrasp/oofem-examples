# CFRP-confined concrete cylinder — confined vs unconfined

Two companion 3D analyses of the same concrete cylinder
(100 mm diameter × 200 mm tall) under axial compression, with the same
prescribed end displacement. The only difference is the boundary: in
`confined/` the cylinder is wrapped with a CFRP jacket, in `unconfined/`
it is bare. Concrete is modelled with CDPM2 (`con2dpm`).

The purpose of this example is to show, in one side-by-side run, the
two contrasting macroscopic responses that CFRP confinement produces:

1. **Unconfined**: peak followed by softening, classic uniaxial
   compression behaviour for plain concrete.
2. **Confined**: continued hardening past the unconfined peak, even
   though the concrete inside the wrap is already damaging.

The hardening mechanism is the competition between two effects. As the
concrete damages, its stiffness drops, and lateral expansion accelerates.
The CFRP wrap reacts elastically to that expansion and applies a passive
confining pressure, which pushes the stress state up the CDPM2 yield
surface. Confinement wins fast enough that the axial load capacity keeps
growing despite the stiffness loss. This matches what is seen
experimentally when FRP-wrapped specimens are cut open: the interior
concrete shows damage typical of softening under unconfined loading, but
the macroscopic load–displacement curve never softens.

The CFRP wrap is discretised as `truss3d` elements oriented in the
circumferential direction only — the wrap carries hoop force but no
axial or shear force. This mirrors a circumferentially wound CFRP sheet,
which is strongly orthotropic: stiff and strong along the fibres, soft
across them. Modelling the wrap as a continuum shell would impose an
axial stiffness that the real material does not have.

One detail to keep in mind when looking at the damage field: the top
and bottom end faces of the cylinder have prescribed axial displacement
but are also restrained from radial expansion (the prescribed-displacement
BC fixes all three DOFs at the loaded nodes). That acts as a built-in
confinement source near the end zones — a platen-like effect — so even
the unconfined cylinder is laterally confined for free at z = 0 and
z = L. Damage in the unconfined case therefore localises in the middle
of the specimen, away from the over-confined end bands. The contour to
look at is the compressive damage variable ω_c in CDPM2 (the tensile
damage ω_t follows ω_c under this load path).

## Reproduce

Both `oofem.in` files are committed, so the public Docker image (no T3D
needed) is enough to rerun the analyses:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/column-frp-confined
docker run --rm -v "$PWD":/work \
  ghcr.io/githubgrasp/oofem-public:column-frp-confined bash run-all.sh
```

The `:column-frp-confined` tag is the immutable image baked against the
OOFEM commit that produced the committed `ld.dat` reference curves; use
`:latest` to track the current OOFEM build instead.

If you want to regenerate the mesh from `mesh.in` (e.g. to change
geometry or wrap layout) you need T3D, which is bundled in the private
image — see the
[student-projects](https://petergrassl.com/student-projects/) page for
setup.

`run-all.sh` runs `unconfined/` then `confined/` in turn. To run just
one case, `cd` into that sub-folder and `bash run.sh`.

`bash clean.sh` removes everything generated in both sub-folders.

Runtimes on a typical workstation: unconfined ~30 min, confined ~10 min
(confined is faster because the global response never softens).

## Outputs

Per sub-folder:

| file                            | content                                          |
|---------------------------------|--------------------------------------------------|
| `oofem.in`                      | OOFEM input (assembled by `t3d2oofem`)           |
| `std.out`                       | OOFEM stdout                                     |
| `oofem.out`                     | OOFEM solver output                              |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                  |
| `ld.dat`                        | load–displacement at the top platen              |

## Workflow

Per sub-folder:

```bash
t3d -i mesh.in -o mesh.out -d 0.01 -p 8   # tet mesh
t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
oofem -f oofem.in > std.out
```

## Inputs you can edit

| file              | knobs to play with                                                  |
|-------------------|---------------------------------------------------------------------|
| `*/mesh.in`       | cylinder geometry, hoop spacing (confined only), mesh size          |
| `*/oofem.t3d.ctrl`| CDPM2 parameters, prescribed displacement, CFRP `SimpleCS` area, step count |

## Material parameters

Concrete (CDPM2, identical in both cases):

```
con2dpm 1 d 2400 E 31.0e9 n 0.2 wf 2.22e-4 fc 30.0e6 ft 2.7e6 ...
```

CFRP (confined only):

```
isole 2 d 1.8e3 n 0.3 e 254e9
```

CFRP wrap geometry (confined only). The hoops sit at a fixed vertical
spacing along the cylinder (controlled in `mesh.in`); each hoop is
assigned a `SimpleCS` whose area equals **spacing × wrap thickness**, so
the discrete hoops carry the same total hoop force per unit height as a
continuous wrap of that thickness:

| parameter          | value                                                    |
|--------------------|----------------------------------------------------------|
| wrap thickness `t` | 0.334 mm (typical for a single CFRP layer)               |
| hoop spacing `s`   | 6.25 mm (31 intermediate hoops + 2 endcap hoops)         |
| full-hoop area     | `s · t = 2.0875e-6 m²` — 31 intermediate hoops           |
| endcap-hoop area   | `0.5 · s · t = 1.04375e-6 m²` — 2 endcap hoops (half tributary length) |

To change layer count or wrap thickness, edit the hoop spacing in
`confined/mesh.in` and the two `SimpleCS area` lines in
`confined/oofem.t3d.ctrl` so that the area still equals spacing × thickness.
