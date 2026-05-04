# CDPM2 — single-element monotonic verification set

Four single-tetrahedron, single-Gauss-point analyses that together cover the
principal axes of the Concrete Damage Plasticity Model 2 (`con2dpm`) under
monotonic loading. Same element, same material parameters; only the boundary
conditions and loading change.

| sub-test       | strain state imposed              | stress state           |
|----------------|-----------------------------------|------------------------|
| `Tension/`     | uniaxial tension (lateral free)   | σxx ≠ 0; rest = 0      |
| `Compression/` | uniaxial compression (lat. free)  | σxx ≠ 0; rest = 0      |
| `SimpleShear/` | pure γxy, all normal strains = 0  | σxy + confinement      |
| `PureShear/`   | only γxy elastically (free dilatn)| σxy ≠ 0; rest = 0      |

The simple-shear / pure-shear pairing is deliberate. Their elastic peaks
match (both reach σ1 = ft), but post-peak diverges:

- **simple shear** suppresses dilation → confinement builds up → CDPM2's cap
  / confinement-sensitive branch is exercised.
- **pure shear** lets normal strains develop → conventional shear failure
  along the σ1 direction at 45° to element axes.

Anyone implementing CDPM2 needs to reproduce all four. Matching peaks is the
easy bit (just the failure surface); reproducing the post-peak divergence
between SimpleShear and PureShear is the discriminating test for damage
evolution, dilatancy, and crack-band scaling.

## Reproduce

With the public Docker image (no compilation needed):

```bash
docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest \
  bash /work/Tension/run.sh        # one of the four
```

Or with a local checkout of `oofem-examples`:

```bash
./test.sh                           # opens shell in oofem-private container
cd /work/cdpm2-single-monotonic/Tension
bash run.sh
```

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
| `wf`      | 148.13 µm  | crack opening at zero stress (mode I)|
| `hp`      | 0.01       | hardening parameter                  |

## Why single tetra / single GP

Constant-strain tet (`ltrspace`) with one integration point means the GP
response IS the element response. No mesh-bias, no spatial gradients, no
quadrature artefacts — purely the constitutive law. Bug-hunting in CDPM2
implementations is much faster when the test harness has no other moving
parts.

## Referenced by

- (TODO) Blog post: <url>
