#!/bin/bash
# Reproduce ONE Biot case of the fluid-pressurised thick-walled cylinder.
# Self-contained: generates its own mesh and runs the coupled (staggered)
# analysis entirely in this folder — runnable on its own (bash run.sh) without
# the sibling case. The Biot coefficient is set in control.in (latticelinearelastic bio).
# Pipeline: generator -> qvoronoi -> converter -> oofem -> compare.py -> gnuplot
set -e
cd "$(dirname "$0")"

echo "Generating node distribution..."
generator mesh.in

echo "Building Voronoi tessellation..."
qvoronoi p Fv < mesh.nodes > mesh.voronoi

echo "Assembling oofem.sm.in / oofem.tm.in (converter)..."
converter control.in mesh.nodes mesh.voronoi

echo "Running coupled (staggered) analysis..."
oofem -f oofem.smtm.in > std.out

echo "Extracting profiles + analytical solution..."
python3 compare.py

echo "Plotting case.pdf..."
gnuplot <<'EOF'
set terminal pdf size 16cm,12cm
set output 'case.pdf'
set grid
set xlabel 'normalised radius  r / r_i'
set ylabel 'normalised radial displacement  u_r / r_i'
set key top left
set title "Thick-walled cylinder: lattice vs analytical (A.22)"
plot 'lattice.dat'  using 1:2 with points pt 6 ps 0.35 lc rgb '#1f77b4' title 'lattice', \
     'analytic.dat' using 1:2 with lines  lw 2.5        lc rgb '#d62728' title 'analytical'
EOF

echo "Done: $(pwd)  (lattice.dat, binned.dat, analytic.dat, case.pdf; VTU for ParaView)"
