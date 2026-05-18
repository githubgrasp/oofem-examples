#!/bin/bash
# Reproduce: 2D linear lattice mass-transport with consistent capacity,
# verified against the 1D finite-slab analytical solution.
# Pipeline: generator -> qvoronoi -> converter -> oofem -> compare.py -> gnuplot
set -e
cd "$(dirname "$0")"

echo "Generating node distribution..."
generator mesh.in

echo "Building Voronoi tessellation..."
qvoronoi p Fv < mesh.nodes > mesh.voronoi

echo "Assembling oofem.in..."
converter control.in mesh.nodes mesh.voronoi

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Extracting profiles and computing analytical..."
python3 compare.py

echo "Generating compare.pdf..."
gnuplot <<'EOF'
set terminal pdf size 24cm,18cm
set output 'compare.pdf'

set multiplot layout 2,2 title "Homogeneous 2D lattice flow (consistent capacity) vs 1D analytical" font ",14"

set grid
set xlabel 'y [m]'
set ylabel 'p / p_0'
set xrange [0:0.1]
set yrange [-0.05:1.1]
set key top right

# Must match STEPS in compare.py and deltat in control.in (0.05 s)
times = "0.5 1.5 3.0 5.0"
steps = "10  30  60  100"

do for [i=1:4] {
    s = word(steps, i)
    t = word(times, i)
    set title sprintf("t = %s s", t)
    plot 'profile_'.s.'.dat'   using 2:3 with points pt 6 ps 0.45 lc rgb '#1f77b4' title 'lattice', \
         'analytical_'.s.'.dat' using 1:2 with lines  lw 2.5 lc rgb 'black'        title 'analytical'
}

unset multiplot
EOF

echo
echo "Done."
echo "  VTU output:   oofem.out.m0.*.vtu"
echo "  Profile data: profile_*.dat  analytical_*.dat"
echo "  Plot:         compare.pdf"
