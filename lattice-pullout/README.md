# 3D lattice — pull-out of a centrically embedded rebar

A 100 mm long, 100 mm diameter concrete cylinder with a single 16 mm
diameter steel bar along its axis. The steel/concrete interface is a
0.1 mm shell modelled with `latticecontact3d` node-to-node bond-contact
elements carrying the Grassl & Davies (2011) bond-plasticity law
(Mohr–Coulomb friction + compression cap). The **first 20 mm** of the
interface from the loaded face is **debonded** (frictionless sleeve);
the remaining length is fully bonded.

On the loaded face the concrete is supported on a frictionless roller (the
matrix nodes there are held in x only, free in y/z) and the bar is pulled out
in displacement control. The whole specimen — steel, matrix **and** bond — is
a lattice.

**The debonded length.** In experiments a bond-free length is left near the
loaded face because friction between the loading plate and the concrete
creates a confinement cone that locally inflates bond and splitting; the
debond moves the measured bond into the undisturbed interior. Here the support
is an idealised *frictionless* roller, so that cone does not form — but the
20 mm debonded sleeve is retained to mirror the standard test configuration
(and to exercise the `debond` clause). Switching the support face to a full
clamp (`#@nodebc … matrixonly` without `dofs 1 1`) reinstates the confinement
cone and makes the debond physically necessary — a useful contrast.

The example demonstrates the *updated* modelling toolchain:

1. **Random Voronoi lattice** (`generator` + `qvoronoi`) over a cylinder,
   densified at the rebar interface.
2. **Bond-contact interface** — the ITZ shell of a `#@cylinderinclusion`
   is emitted as `latticecontact3d` elements via `#@element material`,
   using the `latticebondplast` material (the modern replacement for
   putting the bond law on ordinary `lattice3D` struts).
3. **Debonded sleeve** — the `debond` clause of `#@cylinderinclusion`
   assigns a frictionless bond material to the first 20 mm.
4. **Rigid pull grip + one-value load extraction** — the bar's loaded-end
   nodes are slaved in all three translations (`#@slaveside … dofs 1 2 3
   inclusiononly`) to a single master node prescribed at x = pull, y = z = 0,
   so the cross-section moves as a rigid grip and the x-reaction at that node
   is the *total* pull-out force. This rigid grip also removes the assembly's
   rigid-body modes (y/z translation and twist about x), so the matrix support
   face can stay a frictionless roller (`#@nodebc … matrixonly dofs 1 1`)
   without leaving the specimen free to drift.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-pullout
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag
`ghcr.io/githubgrasp/oofem-public:lattice-pullout`.

`bash clean.sh` removes everything generated.

## Workflow

```bash
generator mesh.in                              # → nodes.dat
qvoronoi p Fv < nodes.dat > voronoi.dat        # → voronoi.dat
converter control.in nodes.dat voronoi.dat     # → oofem.in
oofem -f oofem.in                              # → oofem.out, oofem.out.m0.*.vtu
```

## Load–slip curve

The pull-out force is the reaction at the master bar node (`#@CTL1`, node
1), which OOFEM prints in the `REACTIONS OUTPUT` block each step. Slip is
that node's axial displacement. Extract both with:

```bash
paste \
  <(grep -A2 'Node           1 ' oofem.out | grep 'dof 1   d' | awk '{print -$NF*1000}') \
  <(grep 'iDof  1 reaction' oofem.out | awk '{print -$6}') \
  > load_slip.dat        # columns: slip [mm]   pull force [N]
```

No custom extractor script is needed — the rigid-grip slaving makes the
single master reaction the total pull-out force.

## Outputs

| file                       | content                                          |
|----------------------------|--------------------------------------------------|
| `nodes.dat`, `voronoi.dat` | lattice node coordinates + Voronoi facets        |
| `oofem.in`                 | OOFEM input (assembled by `converter`)           |
| `oofem.out`                | OOFEM solver output incl. reactions              |
| `oofem.out.m0.*.vtu`       | per-step VTU files (bars + cross-sections) for ParaView |

## Material parameters

| material | role                          | key parameters                                              |
|----------|-------------------------------|-------------------------------------------------------------|
| 1        | concrete matrix               | `latticeplastdam`: `e 30 GPa`, `nu 0.2`, `ft 3 MPa`, `fc 30 MPa`, `wf 50 µm`, `ahard 1.e-3` |
| 2        | steel rebar core (R = 8 mm)   | `latticelinearelastic`: `e 200 GPa`, `nu 0.2`               |
| 3        | bonded interface              | `latticebondplast`: `e 5.2e13`, `a1 0.175`, `fc 40 MPa`, `angle1 0.24` (friction), `flowangle 0.05` (dilation) |
| 4        | debonded interface (0–20 mm)  | as material 3 but `angle1 0` → frictionless, no shear transfer |

The bond parameters follow Grassl & Davies (2011): `a1` is the shear/normal
stiffness ratio, `angle1`/`flowangle` the friction/dilation of the
Mohr–Coulomb surface. Note `e` is **not** a modulus: `latticecontact3d`
feeds the material the displacement *jump* directly (no division by the
interface thickness), so `e` is a stiffness per unit jump [Pa/m] ≈ E_b/h.
A stiff interface is essential — pull-out slip drives the dilatant plastic
flow, whose radial component, resisted by `e`, generates the confinement
stress that both stresses/splits the matrix and mobilises friction. Too
soft an `e` leaves the bond elastic and the matrix unstressed. The physical
value E_b/h ≈ 5.2e14 needs adaptive step subdivision to converge; `5.2e13`
is a penalty compromise that mobilises the mechanism while staying solvable
(reduce the step size — `nsteps` — for robustness).

The concrete matrix uses `latticeplastdam` (damage-**plasticity**), not pure
damage, on purpose: the dilating bond drives radial compression into the
matrix, and a pure-damage element would accumulate damage under that
compression and shed its axial stiffness as well — unphysical. The plasticity
part gives a finite compressive yield surface (`fc`) that takes the radial
compression as bounded plastic strain, so the spurious axial-stiffness loss is
suppressed while tensile splitting is still captured by damage (`ft`, `wf`).

## Inputs you can edit

| file        | knobs to play with                                                                 |
|-------------|------------------------------------------------------------------------------------|
| `mesh.in`   | overall spacing (`#@diam`), interface densification (`#@interfacecylinder refine`), cylinder/rebar geometry |
| `control.in`| concrete (`latticeplastdam`: `e`, `ft`, `fc`, `wf`, `ahard`), steel (`latticelinearelastic`), bond (`latticebondplast`: `e`, `a1`, `fc`, `angle1`, `flowangle`), support face (`#@nodebc … dofs 1 1` roller vs full clamp), debond length (`#@cylinderinclusion … debond`), pull magnitude and steps (`PiecewiseLinFunction 2`, `nsteps`) |

## Further reading

- P. Grassl, T. Davies. *Lattice modelling of corrosion induced cracking
  and bond in reinforced concrete*. Cement and Concrete Composites,
  33(9):918–924, 2011.
  [doi:10.1016/j.cemconcomp.2011.05.005](https://doi.org/10.1016/j.cemconcomp.2011.05.005)

## Referenced by

- Blog post: https://petergrassl.com/blog/lattice-pullout/
