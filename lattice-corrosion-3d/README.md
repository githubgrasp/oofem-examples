# 3D lattice — corrosion-induced cracking of a thick-walled cylinder

A 10 mm-thick slice of a 150 mm concrete cylinder with a single 8 mm
diameter steel bar along its axis. A 0.1 mm rust shell at the steel/
concrete interface expands radially over time (eigenstrain ramp via a
linear thermal-expansion analogue), driving radial pressure into the
surrounding concrete and forming the classical splitting-crack pattern.

The purpose of the example is to show the lattice analogue of the
thick-walled cylinder problem with a discrete, random tessellation:

1. **Random Voronoi lattice** built with `generator` + `qvoronoi` over a
   cylindrical domain, with extra densification at the rebar interface.
2. **Material heterogeneity** through `genran` — `ft` of the concrete
   matrix is randomised via a `Gaussian` random field with mean 1 and
   cov 0.2.
3. **Corrosion eigenstrain** applied as an `StructTemperatureLoad` on
   the ITZ ring, with `calpha` and the load-time function chosen so the
   ramp produces a small radial expansion at the end of the run.
4. **Bounded radial compression** via `latticeplastdam` — the plasticity
   surface caps the compressive stress around the bar, where a pure
   damage law would unphysically lose all stiffness.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/lattice-corrosion-3d
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash -c "bash run.sh && oofem -f oofem.in > std.out && perl pressureExtractor.pl && gnuplot pressure-plot.gp"
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:lattice-corrosion-3d`.

Outputs:

| file                            | content                                          |
|---------------------------------|--------------------------------------------------|
| `nodes.dat`, `voronoi.dat`      | lattice node coordinates + Voronoi facets        |
| `random.dat`                    | spectral random field for `ft`                   |
| `oofem.in`                      | OOFEM input (assembled by `converter`)           |
| `std.out`                       | OOFEM stdout incl. quasi-reaction table          |
| `oofem.out`                     | OOFEM solver output                              |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                  |
| `oofem.out.m1.*.gp`             | per-step Gauss-point data for the extractor      |
| `pressure.dat`                  | step vs. mean radial pressure on the ITZ ring    |

`bash clean.sh` removes everything generated.

## Workflow

```bash
genran random.in random.dat                      # → random.dat
generator mesh.in                                # → nodes.dat
qvoronoi p Fv < nodes.dat > voronoi.dat          # → voronoi.dat
converter control.in nodes.dat voronoi.dat      # → oofem.in
oofem -f oofem.in > std.out                      # → oofem.out.*, oofem.out.m1.*.gp
perl pressureExtractor.pl                        # → pressure.dat
```

`pressureExtractor.pl` reads each `oofem.out.m1.<step>.gp` file, picks
elements with the ITZ material flag, area-averages the radial normal
stress, and writes one row per step.

## Inputs you can edit

| file                 | knobs to play with                                                              |
|----------------------|---------------------------------------------------------------------------------|
| `mesh.in`            | overall spacing (`#@diam`), interface densification (`#@interfacecylinder refine`), cylinder geometry (`#@cylinder`/`#@interfacecylinder line/radius`) |
| `random.in`          | random seed (`ranint`), autocorrelation length (`autoLength*`), grid resolution |
| `control.in`         | concrete (`latticeplastdam`: `e`, `ft`, `fc`, `wf`), steel and ITZ (`latticelinearelastic`: `e`, `a1`, `calpha`), corrosion ramp (`PiecewiseLinFunction 2`), time stepping |
| `pressureExtractor.pl` | step range (`numberOfSteps`), output filename                                 |

## Material parameters

| material | role                              | key parameters                                       |
|----------|-----------------------------------|------------------------------------------------------|
| 1        | concrete matrix                   | `e 30 GPa`, `ft 3 MPa`, `fc 30 MPa`, `wf 50 µm`, random `ft` via `randvars 1 800` |
| 2        | steel rebar core (inside R=8 mm)  | `em 200 GPa`, `nu 0.3`, no expansion                 |
| 3        | corrosion ITZ (0.1 mm shell)      | `e 200 GPa`, `a1 0.001` (shear-free), `calpha 0.15e-4` driving radial eigenstrain |

The ITZ uses a near-zero `a1` rather than the `nu` Poisson form so the
shell can expand radially without locking against the matrix in shear.

## Further reading

Two open-access journal articles use the same lattice approach for
corrosion-induced cracking and explore aspects that go well beyond this
example (time/rate dependence, creep, calibration to experiments):

- I. Aldellaa, P. Grassl. *Rate dependence of corrosion-induced surface
  cracking in concrete: Lattice modelling and experiments*. Frontiers in
  Materials, vol. 327, 2026.
  [doi:10.3389/fmats.2026.1802361](https://doi.org/10.3389/fmats.2026.1802361)
- I. Aldellaa, P. Havlásek, M. Jirásek, P. Grassl. *Effect of Creep on
  Corrosion-Induced Cracking*. Engineering Fracture Mechanics, vol. 264,
  2022.
  [doi:10.1016/j.engfracmech.2022.108310](https://doi.org/10.1016/j.engfracmech.2022.108310)

## Referenced by

- Blog post: https://petergrassl.com/blog/lattice-corrosion-3d/
