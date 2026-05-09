#!/bin/bash
# Run both sub-tests (random e0 field, uniform e0) on the same lattice and
# produce:
#   - per-subfolder ld.pdf
#   - parent-level ld-compare.pdf with both curves on one axis
set -e
cd "$(dirname "$0")"

for sub in random uniform; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
done

echo
echo "Generating comparison plot ld-compare.{pdf,png}..."
gnuplot <<'EOF'
set xlabel 'Displacement [mm]'
set ylabel 'Load [kN]'
set title '2D direct tensile lattice - random vs uniform e0'
set grid
set key top right

set terminal pdf size 14cm,10cm
set output 'ld-compare.pdf'
plot 'uniform/ld.dat' using ($1*1000):($2/1000.) \
       with linespoints lw 2 pt 7 ps 0.3 lc rgb '#1f77b4' title 'uniform e0', \
     'random/ld.dat'  using ($1*1000):($2/1000.) \
       with linespoints lw 2 pt 7 ps 0.3 lc rgb '#d62728' title 'random e0'

set terminal pngcairo size 1200,900 enhanced font ',14'
set output 'ld-compare.png'
replot
EOF

echo
echo "All done."
echo "  Per-test plots: */ld.pdf"
echo "  Comparison:     ld-compare.{pdf,png}"
