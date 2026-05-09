#!/bin/bash
# Reproduce: 2D direct tensile lattice with random field
# Blog: https://petergrassl.com/blog/lattice-tensile-random-2d/
#
# Outputs (all in this directory):
#   oofem.in           - OOFEM input (assembled by `converter`)
#   std.out            - OOFEM stdout incl. quasi-reaction table
#   oofem.out          - OOFEM solver output
#   oofem.out.m0.*.vtu - per-step VTU for ParaView
#   ld.dat             - load-displacement (m, N) from quasi-reaction table
#   ld.pdf             - load-displacement plot (mm, kN)
set -e
cd "$(dirname "$0")"

echo "Generating node distribution..."
generator mesh.in

echo "Building Voronoi tessellation..."
qvoronoi p Fv < mesh.nodes > mesh.voronoi

echo "Generating random field..."
genran random.in random.dat

echo "Building lattice + assembling oofem.in..."
converter control.in mesh.nodes mesh.voronoi

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Extracting load-displacement from quasi-reaction table..."
awk '/^NRSolver:[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[+-]/ {print $4, $5}' std.out > ld.dat

echo "Generating plot..."
gnuplot <<'EOF'
set terminal pdf size 12cm,9cm
set output 'ld.pdf'
set xlabel 'Displacement [mm]'
set ylabel 'Load [kN]'
set title '2D direct tensile lattice - random e0 field'
set grid
plot 'ld.dat' using ($1*1000):($2/1000.) with linespoints lw 2 pt 7 ps 0.4 title 'random'
EOF

echo "Done. See ld.pdf for the load-displacement curve."
