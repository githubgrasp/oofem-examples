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
# Plot settings live in these editable gnuplot scripts (axes, ranges, labels,
# styles) -- change them directly, no need to touch run.sh or compare.py.
gnuplot pressure.gp
gnuplot displacement.gp

echo "Done: $(pwd)"
echo "  pressure.pdf       (transport P_f vs logarithmic  -- the transferred quantity)"
echo "  displacement.pdf   (matrix u_r vs poroelastic annulus -- Biot feedback)"
echo "  oofem.tm.out.m0.pvd  pore-pressure VTU frames (ParaView)"
echo "  oofem.sm.out.m0.pvd  displacement VTU frames  (ParaView)"
