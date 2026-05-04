#!/bin/bash
# Run all four CDPM2 single-element monotonic tests and produce:
#   - per-subfolder ld.pdf (individual stress-strain curves)
#   - parent-level ld-all.pdf (2x2 grid of all four for the blog post)
set -e
cd "$(dirname "$0")"

for sub in Tension Compression SimpleShear PureShear; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
done

echo
echo "Generating combined 2x2 plot ld-all.pdf..."
gnuplot <<'EOF'
set terminal pdf size 22cm,16cm
set output 'ld-all.pdf'

set multiplot layout 2,2 title "CDPM2 - single tetrahedron, single GP - monotonic verification set" font ",14"

set xlabel 'Strain [mm/m]'
set ylabel 'Stress [MPa]'
set grid
set key off

set title 'Uniaxial tension'
plot 'Tension/ld.dat'      using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#1f77b4'

set title 'Uniaxial compression'
plot 'Compression/ld.dat'  using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#d62728'

set title 'Simple shear (constant volume)'
plot 'SimpleShear/ld.dat'  using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#2ca02c'

set title 'Pure shear stress'
plot 'PureShear/ld.dat'    using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#9467bd'

unset multiplot
EOF

echo
echo "All done."
echo "  Per-test plots: */ld.pdf"
echo "  Combined plot:  ld-all.pdf"
