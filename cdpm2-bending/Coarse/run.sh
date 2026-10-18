#!/bin/bash
# Reproduce one mesh of the CDPM2 three-point-bending study (plane stress).
# Blog: https://petergrassl.com/blog/cdpm2-bending/
#
# Runs OOFEM on the committed standalone input (oofem.in), extracts the
# load-CMOD data, and plots the single-mesh curve. No mesh generation is
# needed here: oofem.in already carries the full mesh. To regenerate it from
# the T3D source (private image only) see the parent README.
#
# Outputs (this folder):
#   std.out    OOFEM stdout
#   oofem.out  OOFEM solver output (+ per-step .vtu / .osf)
#   ld.dat     cols: loadlevel[N]  u_x(node3)  u_x(node4)  u_y(node17)  [m]
#   ld.pdf     load-CMOD curve for this mesh
set -e
cd "$(dirname "$0")"
MESH=$(basename "$PWD")

echo "[$MESH] Running OOFEM (this can take a while)..."
oofem -f oofem.in > std.out

echo "[$MESH] Extracting load-CMOD data..."
extractor -f oofem.in > ld.dat

echo "[$MESH] Plotting ld.pdf..."
# Load[kN] = -col1/1000 ; CMOD[mm] = (u_x(node4) - u_x(node3)) * 1000
gnuplot <<EOF
set terminal pdf size 12cm,9cm
set output 'ld.pdf'
set xlabel 'CMOD [mm]'
set ylabel 'Load [kN]'
set title 'Three-point bending (plane stress, CDPM2) - ${MESH} mesh'
set grid
set key off
plot 'ld.dat' using ((\$3-\$2)*1000):(-\$1/1000) with lines lw 2 lc rgb '#d62728'
EOF

echo "[$MESH] Done."
