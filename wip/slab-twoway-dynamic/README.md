# Two-way slab — static and explicit-dynamic response

A 1 m × 1 m simply-supported two-way slab of 10 mm thickness,
discretised with the **shell lattice** in OOFEM (`LatticeCS shape 2`),
under a uniformly distributed transverse load. The same mesh is used
for two analyses in companion sub-folders:

- **`static/`** — `NonLinearStatic`, single load step, ramped pressure.
  Use this as the reference quasi-static response.
- **`dynamic/`** — `NlDEIDynamic` (explicit central-difference), 20 000
  steps of `Δt = 1 µs` (20 ms total). The load is a triangular pulse:
  zero → peak at t = 0.5 ms → back to zero at t = 1 ms, followed by
  free vibration to the end of the run.

Both share an identical mesh (`mesh.in`), boundary conditions
(corners and edges pinned at z = 0; mid-side and corner dofs locked
to suppress rigid-body modes), and the same shell-lattice geometry.
The only differences are the engineering model and the load-time
function.

## Reproduce

Both `oofem.in` files are committed, so the public Docker image (no T3D
needed) is enough to rerun the analyses:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/wip/slab-twoway-dynamic
docker run --rm -v "$PWD":/work \
  ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

If you want to regenerate the mesh from `mesh.in` (e.g. to change slab
dimensions or mesh size) you need T3D, which is bundled in the private
image — see the
[student-projects](https://petergrassl.com/student-projects/) page for
setup.

`run-all.sh` runs `static/` then `dynamic/` in turn. To run just one
case, `cd` into that sub-folder and `bash run.sh`. `bash clean.sh`
from the top level wipes the generated artefacts in both.

The dynamic run uses `-l 1` (WARNING) to suppress the per-step
"Solving [Step …]" and "user time consumed" chatter that explicit
analyses produce 20 000 times otherwise. Errors and warnings still
print.

## Workflow

Per sub-folder:

```bash
t3d -d 0.1 -i mesh.in -o mesh.out   # 2D surface mesh on the slab
converter control.in mesh.out       # → oofem.in (uses #@ directives)
oofem -f oofem.in > std.out         # solve
```

## Outputs

Per sub-folder:

| file                            | content                                         |
|---------------------------------|-------------------------------------------------|
| `oofem.in`                      | OOFEM input (assembled by `converter`)          |
| `std.out`                       | OOFEM stdout                                    |
| `oofem.out`                     | OOFEM solver output (DOFMan / reaction history) |
| `oofem.out.m0.*.vtu`            | per-step VTU files for ParaView                 |

Open the VTU sequence (or the `.pvd`) in ParaView to view the
deflection field over time. For the dynamic case, you can also extract
the mid-span (DOFMan 5) z-displacement history from `oofem.out` to
plot against time.

## What to look at

- Static: the centre deflection at full load (DOFMan 5). The textbook
  reference is the Navier double-sine-series solution for a
  simply-supported square plate under uniform load — see
  [Wikipedia: Bending of plates](https://en.wikipedia.org/wiki/Bending_of_plates):

  ```
  w_max = 0.00406 · q · a⁴ / D       with D = E · t³ / [12 · (1 − ν²)]
  ```

  With the example parameters (`a = 1 m`, `t = 0.01 m`, `q = 100 Pa`,
  `E = 30 GPa`, `ν = 0`, so `D = E·t³/12 = 2500 N·m`), this gives
  `w_max ≈ 1.62 × 10⁻⁴ m = 0.162 mm` at the centre — what the lattice
  should reproduce within the discretisation error.
- Dynamic: the centre deflection history during the 1 ms pulse and
  the free-vibration phase that follows. Note the dynamic amplification
  factor — peak dynamic deflection vs peak static deflection at the
  same pulse magnitude — and the natural frequency you can read off
  the free-vibration period.

## Material parameters

```
LatticeFrameElastic 1 d 2400 tAlpha 0 E 30 GPa n 0.0
```

(Static run uses `d 1` since inertia plays no role there.) Shell
thickness is set with `#@THICKNESS 0.01` in `control.in`.

## Inputs you can edit

| file              | knobs to play with                                          |
|-------------------|-------------------------------------------------------------|
| `*/mesh.in`       | slab dimensions, mesh size                                  |
| `*/control.in`    | thickness, distributed load magnitude (`#@LOAD ... q ...`), step count, time function |
