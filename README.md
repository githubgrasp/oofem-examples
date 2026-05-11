# oofem-examples

Reproducible OOFEM analyses that accompany blog posts at
[petergrassl.com](https://petergrassl.com). Each folder is a self-contained
example: input file, run script, README explaining what it shows.

The goal is two-command reproducibility — no compilation, no toolchain.

> **Note** — these examples use my OOFEM fork at
> [github.com/githubgrasp/oofem](https://github.com/githubgrasp/oofem),
> not the upstream
> [oofem/oofem](https://github.com/oofem/oofem).
> The fork contains features that aren't (yet) upstream (aggregate,
> converter, generator, …) and may lag upstream on others. Examples here
> are guaranteed to run against the published `oofem-public` Docker image,
> not against arbitrary OOFEM builds.

## Reproduce an example

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/<example-folder>
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh
```

Outputs (PDF plots, extracted data, OOFEM logs) appear in the example
folder, viewable on your host with any normal application.

## Examples

| folder | what it shows |
|---|---|
| [`cdpm2-single-monotonic/`](cdpm2-single-monotonic/) | CDPM2 verification set: tension, compression, simple shear, pure shear on a single tetrahedron with one Gauss point. |
| [`lattice-tensile-periodic-2d/`](lattice-tensile-periodic-2d/) | 2D direct tensile lattice analysis on a 100×100 mm prism, comparing a non-periodic mesh (crack locks onto the boundary) with a periodic mesh (crack goes through the random mesh). |
| [`lattice-tensile-random-2d/`](lattice-tensile-random-2d/) | 2D direct tensile lattice analysis on a periodic 100×100 mm prism, comparing a uniform `e0` (crack pattern driven by mesh randomness only) with a spatially random `e0` (heterogeneity controls crack location). |
| [`nonlocal-dynamic-idm1/`](nonlocal-dynamic-idm1/) | Explicit-dynamic fracture of a 254×254 mm Homalite-100 cruciform with a central crack under biaxial impulsive loading, comparing local (`idm1` crack-band) vs nonlocal damage regularisation. |

More to follow as blog posts are published.

## How this works

- The `oofem-public` image on
  [ghcr.io](https://github.com/githubgrasp/oofem-examples/pkgs/container/oofem-public)
  ships my OOFEM fork plus mesh-generation and post-processing utilities.
- The image is multi-arch (linux/amd64, linux/arm64) so `docker pull` does
  the right thing on Apple Silicon Macs, Intel Macs, and Linux/Windows
  hosts automatically.
- The exact OOFEM commit baked into each image release is recorded at
  `/opt/oofem/OOFEM_COMMIT` inside the container.

## Interactive shell

If you want to poke around inside the container instead of running a single
example via `bash run.sh`, `test.sh` opens an interactive shell with the
current directory mounted at `/work`:

```bash
./test.sh ghcr.io/githubgrasp/oofem-public:latest
```

Once inside the container, `cd /work/<example>` and run any command (oofem,
extractor, gnuplot, …). Files you create are visible on your host.

## Feedback

Issues and questions: open one on the
[issue tracker](https://github.com/githubgrasp/oofem-examples/issues).
