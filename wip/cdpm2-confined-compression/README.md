# CDPM2: single-element triaxial compression (Imran-Pantazopoulou 1996)

Seven single-`ltrspace` triaxial compression tests on a unit tetrahedron,
covering active-confinement levels &sigma;<sub>lat</sub> &isin; {0, 2.15, 4.3, 8.6, 17.2, 30.1,
43} MPa for concrete with `fc = 47.4 MPa, ft = 4.74 MPa, E = 30 GPa,
nu = 0.15`, matching the **w/c = 0.55, dry** specimens in Table 2 of
Imran & Pantazopoulou, *Experimental Study of Plain Concrete under
Triaxial Stress*, ACI Materials Journal 93(6), 1996.

Reference digitised stress-strain and lateral-strain curves are committed
as `Imran<level>.dat` files (three columns: &sigma;<sub>axial</sub> in MPa, &epsilon;<sub>axial</sub> in
per mille, &epsilon;<sub>lateral</sub> in per mille; tension-positive convention).

```
cdpm2-confined-compression/
|-- 0/           sigma_lat = 0       (uniaxial reference)
|-- 2p15/        sigma_lat = 2.15 MPa
|-- 4p3/         sigma_lat = 4.3 MPa
|-- 8p6/         sigma_lat = 8.6 MPa
|-- 17p2/        sigma_lat = 17.2 MPa
|-- 30p1/        sigma_lat = 30.1 MPa
|-- 43/          sigma_lat = 43 MPa
|-- Imran*.dat   experimental data (one file per sigma_lat)
`-- plot.gp      overlay simulation + experiment
```

Each case contains an `oofem.in` and (after running) an `oofem.out` and
extracted `ld.dat`. `gnuplot plot.gp` produces `stress-strain.png` and
`volumetric.png` overlaying all seven OOFEM curves with the Imran data.

## Running

In each case folder:
```
oofem -f oofem.in
python3 extractor.py -f oofem.in > ld.dat
```
Then in the parent folder:
```
gnuplot plot.gp
```

`ld.dat` has columns `epsilon_axial  epsilon_lateral  sigma_axial[Pa]  step` (axial = y
direction, lateral = z direction; both lateral directions equal by
symmetry).

## Loading protocol: biaxial then axial

The Imran Type-a path is reproduced exactly:

- **Phase 1** (20 steps, t = 0 to 19): lateral NodalLoads on the x and z
  faces ramp from zero to the target &sigma;<sub>lat</sub> under indirect load control
  (`controllmode 1`). The axial direction (y) is unrestrained (no axial
  load and no prescribed displacement), so &sigma;<sub>yy</sub> = 0 and &epsilon;<sub>yy</sub> is the
  Poisson dilation under biaxial lateral compression.
- **Phase 2** (200 steps, t = 20 to 219): lateral loads are held at &sigma;<sub>lat</sub>
  (LTF 2 drops to zero so no further reference load is added, but the
  cumulated load level from phase 1 stays via `initialLoadVector`). The
  axial DOF (`ddm 2 3 2` = node 3 dof 2) is displacement-controlled,
  ramping &epsilon;<sub>y</sub> from zero down to the imposed maximum via `ddv` x `ddltf`.

This matches the experimental setup (cylindrical specimen in a triaxial
cell, oil pressure on lateral surface only, axial rams retracted in
phase 1 and engaged under displacement control in phase 2).

## Stress-path geometry: the Lode angle sweeps

A consequence of the biaxial-then-axial protocol is that the stress
state traverses the deviatoric plane during phase 2:

| Stage | Principal stress ordering | Lode position |
|---|---|---|
| End of phase 1 | &sigma;<sub>y</sub> (=0) > &sigma;<sub>x</sub> = &sigma;<sub>z</sub> | triaxial extension, &theta; &asymp; 0 |
| Hydrostatic point (&sigma;<sub>y</sub> = &sigma;<sub>lat</sub>) | all equal | &rho; = 0, &theta; undefined |
| Late phase 2 | &sigma;<sub>x</sub> = &sigma;<sub>z</sub> > &sigma;<sub>y</sub> | triaxial compression, &theta; &asymp; &pi;/3 |

So the trial state crosses through the hydrostatic axis and rotates from
the tensile meridian to the compression meridian. The compression
meridian is larger (`r(pi/3) = 1` vs `r(0) = 2` in the denominator of
&rho;&middot;r in the yield function), which means in phase 2 the yield surface
"grows in front of" the path. This produces a visible **elastic
unloading-reloading plateau** in the &sigma;<sub>y</sub> vs &epsilon;<sub>y</sub> curve at high
confinement before yielding resumes on the compression meridian. This is not a
numerical artefact, just the geometry of the loading path against an
extension-vs-compression-asymmetric surface.

## What the comparison shows

For confinement levels up to &sigma;<sub>lat</sub> / fc about 0.2 (cases 0, 2.15, 4.3, 8.6,
17.2 MPa), the CDPM2 simulations track the Imran curves closely for both
the stress-strain envelope (peak and post-peak) and the volumetric
response (initial contraction, dilation transition, expansion rate).

At higher confinement (30.1, 43 MPa) the model captures peak stress
within 5-10 % of the experiment, but **under-predicts the depth of
volumetric compaction**: Imran reports up to -15 to -18 &permil; compaction at
&sigma;<sub>lat</sub> = 43 MPa, while CDPM2 ends nearer -6 to -8 &permil;.

In summary: the model is well-calibrated for the experimentally
relevant moderate-confinement range and captures peak strength across
the full sweep; the compaction depth gap at very high active confinement
is a documented limitation of the underlying model class, not a defect
of this particular run.

## Future work

A useful second validation point would be Candappa, Sanjayan & Setunge,
*Complete triaxial stress-strain curves of high-strength concrete*,
J. Materials in Civil Engineering 13(3), 2001, 209-215. High-strength
concrete (fc about 60-100 MPa), clean complete pre- and post-peak curves,
and a hydrostatic-preload loading protocol that would exercise the
deeply-triaxial regime of the hardening ductility law, the regime the
IP biaxial-preload path does not reach.
