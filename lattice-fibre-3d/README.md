# 3D lattice — SFRC cube: with vs without fibres

A periodic 30 × 30 × 30 mm concrete cube pulled in uniaxial tension, run
**twice on the identical matrix** to isolate what the fibres do:

| subdir            | model                                                        |
|-------------------|-------------------------------------------------------------|
| `with-fibres/`    | matrix + `Vf = 1%` straight steel fibres bridging the crack |
| `without-fibres/` | the same matrix lattice and random `ft` field, no fibres    |

Both cases share the same deterministic matrix: the lattice nodes
(`generator`, seed `ranint -2`) and the correlated Gaussian `ft` field
(`genran`, seed `ranint -2`) are bit-identical between the two runs. The
only difference is the `#@inclusionfile packing.dat` line in
`with-fibres/control.in`, which the converter uses to discretise the
fibres on top of the matrix Voronoi. So the comparison is clean: same
crack, with and without bridging.

Expected result: both curves rise to the same matrix cracking peak
(~5 MPa) and soften. The **plain matrix softens toward zero** as the crack
opens, while the **fibre case softens to a bridging plateau** (~1.5 MPa)
carried by the fibres crossing the crack.

## Reproduce

```bash
cd oofem-examples/lattice-fibre-3d
bash run-all.sh
```

This runs both subdirectories, extracts `ld.dat` (macroscopic strain
`eps_yy` = control-node dof 32 vs. load level) for each, and writes the
combined `ld-compare.pdf`. Re-plot without re-running with
`gnuplot compare.gp`.

Each subdirectory is self-contained and can be run on its own with
`bash with-fibres/run.sh` (then extract + plot via `run-all.sh` or the
`extractor`). See `with-fibres/README.md` for the full fibre pipeline,
material parameters, and the 2019 reference.

## Outputs

| file                              | content                                   |
|-----------------------------------|-------------------------------------------|
| `{with,without}-fibres/oofem.out.m0.*.vtu` | per-step VTU for ParaView         |
| `{with,without}-fibres/ld.dat`    | macroscopic strain vs. load level         |
| `ld-compare.pdf`                  | combined load-displacement comparison     |

## Note on the axes

**y-axis** — `ld.dat` column 2 is the CALM load level = total force on the
loaded cell face. The macroscopic stress is `sigma_yy = load level / A`,
with the cube cross-section `A = 0.03 * 0.03 = 9e-4 m^2`; `compare.gp`
applies `YSCALE = 1/(A*1e6)` to plot MPa.

**x-axis** — `ld.dat` column 1 is the control-node *displacement* `u_y`
(the node sits at the cell corner, so `u_y = eps_yy * l_p`). The
macroscopic strain is `eps_yy = u_y / l_p` with `l_p = 0.03 m`;
`compare.gp` divides by `LP` and scales to mm/m. (A quick check: in the
elastic range this recovers `E_hom ~ 30 GPa`, the matrix modulus.)

The peak reads higher than the matrix `ft` (~3 MPa): this is a modelling
artefact, the coarse lattice over-stiffens the response,
and the periodic cell carries lattice cross-section on both sides of the
boundary, so the effective load-bearing area exceeds the nominal `A`. Both
curves share the same factor, so the *comparison* (bridging vs. plain) is
unaffected. Refining the mesh reduces this effect.
