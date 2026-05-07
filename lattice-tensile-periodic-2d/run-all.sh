#!/bin/bash
# Run both lattice direct-tension analyses (periodic + regular) and produce:
#   - per-subfolder ld.pdf
#   - parent-level ld-all.pdf (side-by-side comparison)
set -e
cd "$(dirname "$0")"

for sub in periodic regular; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
done

echo
echo "Generating combined plot ld-all.pdf..."
gnuplot <<'EOF'
set terminal pdf size 22cm,9cm
set output 'ld-all.pdf'

set multiplot layout 1,2 title "2D direct tensile lattice - periodic vs regular mesh" font ",14"

set xlabel 'Displacement [mm]'
set ylabel 'Load [kN]'
set grid
set key off

set title 'Periodic mesh'
plot 'periodic/ld.dat' using ($1*1000):($2/1000.) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#1f77b4'

set title 'Regular mesh'
plot 'regular/ld.dat'  using ($1*1000):($2/1000.) with linespoints lw 2 pt 7 ps 0.3 lc rgb '#d62728'

unset multiplot
EOF

echo
echo "All done."
echo "  Per-test plots: */ld.pdf"
echo "  Combined plot:  ld-all.pdf"
