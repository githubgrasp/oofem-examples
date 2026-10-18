# CDPM2: reinforced concrete shear beam (plane stress, crack band)

Leonhardt and Walther beam no. 5: a reinforced concrete beam without shear
reinforcement in four-point bending that fails in shear. The concrete is
modelled with the crack-band (local) version of the Concrete Damage
Plasticity Model 2 (`con2dpm`) in **plane stress**. The longitudinal
reinforcement is modelled with truss elements whose nodes are embedded in the
concrete mesh as hanging nodes (perfect bond). Half the beam is analysed (symmetry at midspan).

The example shows the modelling pipeline: T3D geometry with the reinforcement
as a free curve, conversion with `t3d2oofem`, automatic embedding of the bars
in OOFEM, and the nonlinear analysis. The mesh has an element size of 20 mm in
the refined region (1198 nodes, of which 64 hanging; 2183 elements, of which
63 trusses).

Geometry, material parameters and experiment follow Xenos and Grassl (2016)
(see [Related work](#related-work)).

## Referenced by

Blog post: https://petergrassl.com/blog/cdpm2-reinforced-2d/

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/cdpm2-reinforced-2d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

The analysis takes about 4 minutes. The committed `ld.dat` already holds the
result, so to rebuild **only the figure**:

```bash
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash -c 'SKIP_RUN=1 bash run.sh'
```

## What you get

| file             | content                                                     |
|------------------|-------------------------------------------------------------|
| `mesh.in`        | T3D geometry (incl. reinforcement curve)                    |
| `oofem.t3d.ctrl` | t3d2oofem control file (materials, BCs, extractor block)    |
| `oofem.in`       | standalone OOFEM input (full mesh embedded)                 |
| `experiment.dat` | experiment: `load P [kN]  midspan deflection [m]`           |
| `ld.dat`         | `loadlevel[N]  u_y(node 4)  u_y(node 15)  u_y(node 18)  u_y(node 19)` in metres |
| `ld.pdf/png`     | load vs midspan deflection, with the experiment             |
| `std.out`        | OOFEM stdout                                                |
| `oofem.out`      | OOFEM solver output (+ `.vtu` every 5th step)               |

Load and deflection are derived from `ld.dat` as:

- `Load P [kN]       = -col1 / 1000`  (load on the half beam = one load point)
- `Deflection [mm]   = -col2 * 1000`  (bottom of the beam at midspan, node 4)

Column 3 is the vertical displacement of the load point (node 15, centre of
the loading plate). Columns 4 and 5 are the vertical displacements of the two
control nodes 18 and 19 (see [Load control](#load-control)).

`bash clean.sh` removes the generated outputs. It keeps the committed inputs,
`ld.dat`, `experiment.dat` and the figure.

## Geometry and material

Half beam:

- Half length 1.275 m (support at 0.30 m from the end, load at 0.81 m
  from the support, 0.165 m from the load to midspan). Depth 0.32 m.
  Out-of-plane thickness 0.19 m.
- Support plate 100 x 30 mm, centred at x = 0.30 m. It is supported at its
  bottom centre (node 12, `u_y = 0`).
- Loading plate 75 x 30 mm, centred at x = 1.11 m. The load is applied at its top
  centre (node 15).
- Symmetry plane x = 1.275 m: `u_x = 0`.
- Reinforcement 2 bars of 26 mm diameter at 50 mm above the bottom face,
  `A_s = 2*pi*13^2 = 1061.9 mm^2`, over the full half length.

Materials:

| part               | model      | parameters                                                     |
|--------------------|------------|----------------------------------------------------------------|
| concrete (mat 1)   | `con2dpm`  | `E = 30.48 GPa`, `nu = 0.2`, `fc = 28.5 MPa`, `ft = 2.247 MPa`, `wf = 0.0594 mm` (`G_F = ft*wf = 133 N/m`), `stype 2` (exponential), `efc = 3e-5`, `asoft = 15` |
| steel plates (mat 2)  | `isole` | `E = 200 GPa`, `nu = 0.3`                                     |
| reinforcement (mat 3) | `isole` | `E = 200 GPa`, `nu = 0.3` (linear elastic truss)              |

`E`, `ft` and `G_F` follow from the CEB-FIP Model Code 2010 for `fcm = 28.5 MPa`.

### Reinforcement in the mesh

The concrete mesh does not need to conform to the reinforcement. In `mesh.in`
the bar is a free curve (`curve 12 vertex 9 10 output yes`). It is not attached
to the outline curves and not fixed to any patch, so T3D meshes it
independently of the concrete. In `oofem.t3d.ctrl` its nodes are written as
`hangingnode` with `doftype 2 2 2` and no `masterElement`. On start-up, OOFEM
finds the host concrete element of each bar node and interpolates the node's
displacements from that element's nodes. This gives perfect bond without
aligning element edges with the bar. More complicated layouts (several layers,
bent bars, stirrups) only need more curves.

### Load control

The analysis uses indirect displacement control (arc length with
`hpcmode 2`) in two metasteps:

1. Up to just before the peak (220 steps): the vertical displacement of the
   load point (node 15) increases by 10 &micro;m per step.
2. Through the shear failure: the controlled quantity is
   `-u_y(15) + 100*(u_y(19) - u_y(18))`
   (`hpc 6 15 2 19 2 18 2 hpcw 3 -1 100 -100`).

The beam fails by a crack that splits the concrete along the reinforcement
towards the support. During this failure the load drops and the load point
moves back up (snap-back), so control by the load-point displacement alone
cannot follow it. Nodes 18 and 19 lie at x = 0.75 m on the bottom face and at
y = 0.10 m, on either side of the bars, so `u_y(19) - u_y(18)` measures the
opening of the splitting crack. This opening increases monotonically through
the failure. On its own it is not a suitable control variable, because it
also increases during elastic unloading. The load-point term prevents this
unloading branch. The two nodes are T3D vertices in `mesh.in` (vertex 19 is
placed inside the concrete with `fixed vertex 19` on patch 1), so their
numbers do not change when the mesh is regenerated.

## Related work

> Xenos D, Grassl P. *Modelling the failure of reinforced concrete with
> nonlocal and crack band approaches using the damage-plasticity model CDPM2.*
> Finite Elements in Analysis and Design (2016).
> [doi:10.1016/j.finel.2016.04.002](https://doi.org/10.1016/j.finel.2016.04.002)

Experiment: F. Leonhardt, R. Walther, *Schubversuche an einfeldrigen
Stahlbetonbalken mit und ohne Schubbewehrung zur Ermittlung der
Schubtragfähigkeit und der oberen Schubspannungsgrenze*, Deutscher Ausschuss
für Stahlbeton (DAfStb), 1962.

## Mesh regeneration (students, private image)

`oofem.in` is committed standalone, so the public image needs no mesh tool.
To regenerate it from the T3D source:

```bash
t3d -d 0.02 -p 8 -i mesh.in -o mesh.out
t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
```
