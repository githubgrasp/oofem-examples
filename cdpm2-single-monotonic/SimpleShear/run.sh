#!/bin/bash
# Reproduce: CDPM2 single tetrahedron under simple shear (γxy only,
# all normal strains constrained to zero — confinement builds up).
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
set title 'CDPM2 single tetrahedron - simple shear (constant volume)'
set grid
plot 'ld.dat' using ($1*1000):($2/1.e6) with linespoints lw 2 pt 7 ps 0.4 title 'simple shear'
EOF

echo "Done. See ld.pdf for the stress-strain curve."
