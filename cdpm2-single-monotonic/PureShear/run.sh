#!/bin/bash
# Reproduce: CDPM2 single tetrahedron under pure shear stress
# (only σxy ≠ 0; all normal strains free → conventional shear failure).
# Blog: https://petergrassl.com/blog/<TODO-slug>/
set -e
cd "$(dirname "$0")"

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Extracting stress-strain data..."
extractor -f oofem.in > ld.dat

echo "Generating plot..."
gnuplot <<'EOF'
set terminal pdf size 12cm,9cm
set output 'ld.pdf'
set xlabel 'Strain [mm/m]'
set ylabel 'Stress [MPa]'
set title 'CDPM2 single tetrahedron - pure shear stress'
set grid
plot 'ld.dat' using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.4 title 'pure shear'
EOF

echo "Done. See ld.pdf for the stress-strain curve."
