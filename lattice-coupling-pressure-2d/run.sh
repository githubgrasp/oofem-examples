#!/bin/bash
# Reproduce BOTH Biot cases and overlay them. Each case is self-contained in
# b0/ (b=0, wall thins) and b1/ (b=1, wall thickens) and can be run on its own:
#     bash b0/run.sh
# This top-level script just runs both and draws the combined comparison.
set -e
cd "$(dirname "$0")"

bash b0/run.sh
bash b1/run.sh

echo
echo "Combined overlay -> compare.pdf"
gnuplot <<'EOF'
set terminal pdf size 18cm,13cm
set output 'compare.pdf'
set grid
set xlabel 'normalised radius  r / r_i'
set ylabel 'normalised radial displacement  u_r / r_i'
set key top left
set title "Fluid-pressurised thick-walled cylinder: lattice vs analytical (A.22), {/Symbol n}=0"
plot 'b0/lattice.dat'  u 1:2 w p pt 6 ps 0.35 lc rgb '#1f77b4' title 'b=0 lattice', \
     'b0/analytic.dat' u 1:2 w l lw 2.5        lc rgb '#1f77b4' title 'b=0 analytical', \
     'b1/lattice.dat'  u 1:2 w p pt 8 ps 0.35 lc rgb '#d62728' title 'b=1 lattice', \
     'b1/analytic.dat' u 1:2 w l lw 2.5        lc rgb '#d62728' title 'b=1 analytical'
EOF

echo "Done."
echo "  Combined:  compare.pdf"
echo "  Per case:  b0/case.pdf  b1/case.pdf   (and b0/ b1/ VTU for ParaView)"
