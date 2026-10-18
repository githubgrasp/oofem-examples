# CDPM2: single-element monotonic verification set

Four single-tetrahedron, single-Gauss-point analyses that together cover an important range of the response of the Concrete Damage Plasticity Model 2 (`con2dpm`) under monotonic loading. Same element, same material parameters; only the boundary conditions and loading change.

| sub-test       | strain state imposed              | stress state           |
|----------------|-----------------------------------|------------------------|
| `Tension/`     | uniaxial tension (lateral free)   | &sigma;<sub>xx</sub> &ne; 0; rest = 0      |
| `Compression/` | uniaxial compression (lat. free)  | &sigma;<sub>xx</sub> &ne; 0; rest = 0      |
| `SimpleShear/` | pure &gamma;<sub>xy</sub>, all normal strains = 0  | &sigma;<sub>xy</sub> + confinement      |
| `PureShear/`   | only &gamma;<sub>xy</sub> elastically (free dilatn)| &sigma;<sub>xy</sub> &ne; 0; rest = 0      |

The simple-shear / pure-shear pairing is deliberate:

- **simple shear** suppresses dilation, so confinement builds up.
- **pure shear** lets normal strains develop, giving conventional shear failure
  along the &sigma;<sub>1</sub> direction at 45&deg; to element axes.

Anyone implementing CDPM2 should reproduce all four.

## Reproduce

With the public Docker image (no compilation needed):

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
cd oofem-examples/cdpm2-single-monotonic
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run-all.sh
```

Or with a local checkout of `oofem-examples`:

```bash
git clone https://github.com/githubgrasp/oofem-examples.git
./test.sh                           # opens shell in oofem-private container
cd /work/cdpm2-single-monotonic/Tension
bash run.sh
```

`:latest` always points at the current OOFEM build and may evolve. For the
exact image used to produce the figures in the linked blog post, replace
`:latest` with the per-example tag:
`ghcr.io/githubgrasp/oofem-public:cdpm2-single-monotonic`.

Each sub-test produces in its own folder:

| file        | content                                |
|-------------|----------------------------------------|
| `std.out`   | OOFEM stdout                           |
| `oofem.out` | OOFEM solver output                    |
| `ld.dat`    | extracted stress-strain pairs (Pa, m/m)|
| `ld.pdf`    | stress-strain curve (MPa, mm/m)        |

`bash clean.sh` (at this level) removes everything generated across all four.

## Material parameters

Same in all four `oofem.in` files (on the `con2dpm` line). Edit + re-run to
compare sensitivities.

| parameter | value      | meaning                              |
|-----------|------------|--------------------------------------|
| `E`       | 30 GPa     | Young's modulus                      |
| `n`       | 0.15       | Poisson's ratio                      |
| `fc`      | 30 MPa     | uniaxial compressive strength        |
| `ft`      | 3 MPa      | uniaxial tensile strength            |
| `wf`      | 148.13 &micro;m  | crack opening at zero stress (mode I)|
| `hp`      | 0.01       | hardening parameter                  |

## Why single tetra / single GP

Constant-strain tet (`ltrspace`) with one integration point means the GP
response is the element response. Element length of 0.1~m is chosen here.

## Referenced by

- Blog post: https://petergrassl.com/blog/cdpm2-single-monotonic/
