#!/bin/bash
# Displacement-driven (Dirichlet) hydro-mechanical lattice coupling.
# A stiff steel inclusion with an expanding ITZ deforms the surrounding matrix;
# the ITZ axial stress drives the transport pore pressure (mechanical -> transport).
# Pipeline: generator -> qvoronoi -> converter -> oofem (staggered) -> compare.py -> gnuplot
#
# Validation: the matrix is a thick-walled cylinder loaded by the ITZ-driven inner
# displacement (free outer edge), so its radial displacement follows the Lame
# solution -- the same analytical family as the fluid-pressure example.
set -e
cd "$(dirname "$0")"

echo "Generating node distribution..."
generator mesh.in

echo "Building Voronoi tessellation..."
qvoronoi p Fv < mesh.nodes > mesh.voronoi

echo "Assembling oofem.sm.in / oofem.tm.in (converter)..."
converter control.in mesh.nodes mesh.voronoi

echo "Running coupled (staggered, SM-first) analysis..."
oofem -f oofem.smtm.in > std.out

echo "Extracting displacement (Lame) + pressure (logarithmic) profiles..."
python3 compare.py

echo "Plotting pressure.pdf + displacement.pdf..."
gnuplot <<'EOF'
set terminal pdf size 16cm,12cm
set grid

# Transport: the transferred quantity -- pore pressure vs logarithmic solution
set output 'pressure.pdf'
set xlabel 'normalised radius  r / a_p'
set ylabel 'normalised pore pressure  P_f / P_a'
set key top right
set title "Displacement-driven coupling: transport lattice vs logarithmic P_f"
plot 'pres_lattice.dat'  using 1:2 with points pt 6 ps 0.35 lc rgb '#1f77b4' title 'lattice (transport)', \
     'pres_analytic.dat' using 1:2 with lines  lw 2.5        lc rgb '#d62728' title 'P_a ln(b/r)/ln(b/a_p)'

# Mechanical: matrix displacement vs poroelastic annulus (Biot feedback)
set output 'displacement.pdf'
set xlabel 'normalised radius  r / a'
set ylabel 'normalised radial displacement  u_r / a'
set title "Displacement-driven inclusion: matrix lattice vs poroelastic annulus"
plot 'disp_lattice.dat'  using 1:2 with points pt 6 ps 0.35 lc rgb '#1f77b4' title 'lattice (matrix)', \
     'disp_analytic.dat' using 1:2 with lines  lw 2.5        lc rgb '#d62728' title 'poroelastic (prescribed u(a), Biot, free outer)'
EOF

# Keep the transport VTU frames (pore-pressure field) for ParaView.
mkdir -p local/vtu
mv -f oofem.tm.out.m0.*.vtu oofem.tm.out.m0.pvd local/vtu/ 2>/dev/null || true
mv -f oofem.sm.out.m0.*.vtu oofem.sm.out.m0.pvd local/vtu/ 2>/dev/null || true

echo "Done: $(pwd)"
echo "  pressure.pdf      (transport P_f vs logarithmic  -- the transferred quantity)"
echo "  displacement.pdf  (matrix u_r vs poroelastic annulus -- Biot feedback)"
echo "  local/vtu/        (oofem.tm.out.m0.pvd = pore pressure, oofem.sm.out.m0.pvd = displacement)"
