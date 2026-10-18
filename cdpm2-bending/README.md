# CDPM2: three-point bending (plane stress), mesh refinement

A notched concrete beam in three-point bending, modelled in **plane stress**
with the Concrete Damage Plasticity Model 2 (`con2dpm`). The analysis is
crack-mouth-opening-displacement (CMOD) controlled, so the full load-CMOD
response (pre-peak, peak, and the long softening tail) is captured.

The same beam is run on three meshes that differ **only in the ligament**
(the strip above the notch where the crack grows); the rest of the mesh is
held fixed. This isolates the effect of ligament element size on the
load-CMOD curve.

The wider motivation is to exercise the **plane-stress implementation of
CDPM2 in OOFEM**: a notched bending test driven all the way through the
softening tail, across a mesh-refinement series, is a demanding check of that
implementation's robustness, and the mesh-convergent fracture energy (see the
[fracture-energy check](#fracture-energy-check)) confirms it behaves correctly.
This is why the three-point-bending analyses are revisited here.

| mesh   | ligament size factor | elements | colour |
|--------|----------------------|----------|--------|
| Coarse | `size def * 0.14`    | 775      | green  |
| Medium | `size def * 0.07`    | 961      | blue   |
| Fine   | `size def * 0.035`   | 1453     | red    |

The legend entries in the figures read `(size factor, element count)`.

## Referenced by

Blog post: https://petergrassl.com/blog/cdpm2-bending/

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/cdpm2-bending
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

`run-all.sh` runs all three meshes and then builds the comparison figure.
Each mesh is a full nonlinear analysis and takes a while (tens of minutes
on the Fine mesh). The committed `ld.dat` files already hold the results, so
to rebuild **only the figure** from the shipped data:

```bash
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash -c 'SKIP_RUNS=1 bash run-all.sh'
```

To run a single mesh:

```bash
cd Fine
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

`:latest` tracks the current OOFEM build. For the exact image used to make the
figures in the blog post, use the per-example tag
`ghcr.io/githubgrasp/oofem-public:cdpm2-bending`.

## What you get

Parent level:

| file                      | content                                           |
|---------------------------|---------------------------------------------------|
| `ld_mesh_compare.pdf/png` | all three meshes: peak-region detail + full range |

Each mesh folder (`Coarse/`, `Medium/`, `Fine/`):

| file        | content                                                       |
|-------------|---------------------------------------------------------------|
| `oofem.in`  | standalone OOFEM input (full mesh embedded)                   |
| `ld.dat`    | `loadlevel[N]  u_x(node3)  u_x(node4)  u_y(node17)` in metres |
| `ld.pdf`    | single-mesh load-CMOD curve                                   |
| `std.out`   | OOFEM stdout                                                  |
| `oofem.out` | OOFEM solver output (+ per-step `.vtu` / `.osf`)              |

Load and CMOD are derived from `ld.dat` as:

- `Load [kN]  = -col1 / 1000`
- `CMOD [mm]  = (u_x(node4) - u_x(node3)) * 1000`  (opening across the notch mouth, nodes 3/4)

`bash clean.sh` removes the generated outputs, keeping the committed inputs,
`ld.dat`, and the comparison figure.

## Geometry and material

- Beam: 1188.5 x 500 mm, plane stress, thickness 40 mm.
- Central notch: 1.8 mm wide, 150 mm deep; supports span 1088.5 mm (= 2.177&middot;D);
  load at the top mid-span node.
- `con2dpm`: `E = 35.6 GPa`, `nu = 0.172`, `fc = 50 MPa`, `ft = 5 MPa`,
  `wf = 53.33 um` (crack-band softening), `stype 1` (bilinear), `damflag 1`.

The bilinear softening (`stype 1`) uses the CDPM2 defaults `ft1 = 0.3*ft` and
`wf1 = 0.15*wf` (kink at `(wf1, ft1)`, then down to `(wf, 0)`), giving a mode-I
fracture energy

```
G_f = 0.5*ft*wf1 + 0.5*ft1*wf = 60.0 J/m^2
```

Edit the `con2dpm` line in each `oofem.in` and re-run to explore sensitivities.

This is the largest notched specimen (depth `D = 500 mm`, relative notch depth
`lambda = 0.3`) of the Hoover et al. three-point-bending size-effect series.

### Fracture-energy check

`run-all.sh` closes with a work-of-fracture check: the structural fracture
energy is the area under the load vs **load-point deflection** curve
(`u_y(node 17)`, column 4 of `ld.dat`) divided by the ligament area
`A_lig = b*(D - a) = 0.04*0.35 = 0.014 m^2`. Run to near-complete separation (load to 0),
the recovered `G_F` converges to the input `G_f = 60 J/m^2` from above as the
ligament mesh is refined (Coarse 80.5 to Medium 67.3 to Fine 62.1 J/m<sup>2</sup>, i.e.
Fine within ~4 %). This is a direct check of the input fracture energy and of the
mesh objectivity of the crack-band regularisation.

## Related work

Same beam geometry (depth `D = 500 mm`, out-of-plane thickness 40 mm, span
`L = 2.177*D`, notch `lambda = 0.3`, plane stress) and the same calibrated elastic
constants (`E = 35.6 GPa`, `nu = 0.172`) were used, with an **integral-type
nonlocal isotropic damage model** (a different constitutive model from the
CDPM2 crack-band plasticity-damage used here, but the identical specimen
geometry, also run in OOFEM with T3D meshes), in:

> Havlásek P, Grassl P, Jirásek M. *Analysis of size effect on strength of
> quasi-brittle materials using integral-type nonlocal models.* Engineering
> Fracture Mechanics 2016;157:72-85.
> [petergrassl.com/publications/havgrajir16](https://petergrassl.com/publications/havgrajir16/)

The same broad question (size effect in CMOD-controlled three-point-bending
concrete beams) is studied with a discrete meso-scale **lattice** model (stiff
aggregates in a soft matrix with weak interfaces), on a different beam geometry,
in:

> Grassl P, Grégoire D, Rojas Solano L, Pijaudier-Cabot G. *Meso-scale
> modelling of the size effect on the fracture process zone of concrete.*
> International Journal of Solids and Structures 2012;49(13):1818-1827.
> [petergrassl.com/publications/gragresol12](https://petergrassl.com/publications/gragresol12/)

There the geometry is different (the Grégoire et al. beam series) and the model
is discrete rather than continuum, a further contrast to the CDPM2 crack-band
model used here. The lattice examples elsewhere in this repository
(`lattice-tensile-random-2d/`, ...) use the same discrete approach.

## Mesh regeneration (students, private image)

`oofem.in` is committed standalone, so the public image needs no mesh tool.
To regenerate it from the T3D source:

```bash
t3d -d 0.2 -p 8 -i mesh.in -o mesh.out
t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
```

`oofem.t3d.ctrl` is the converter template (boundary conditions, cross-section,
material, and the extractor `%BEGIN_CHECK%` block).
