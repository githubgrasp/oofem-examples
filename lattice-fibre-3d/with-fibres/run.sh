#!/bin/bash
# Reproduce: 3D periodic SFRC cube, random ft, steel fibres at Vf = 1%.
# Pipeline: aggregate -> genran -> generator -> qvoronoi -> converter -> oofem
set -e
cd "$(dirname "$0")"

echo "Placing fibres (aggregate -> packing.dat)..."
aggregate aggregate.in

echo "Generating random field for matrix ft (genran -> random.dat)..."
genran random.in random.dat

echo "Generating lattice nodes (generator -> nodes.dat)..."
generator mesh.in

echo "Building Voronoi tessellation (qvoronoi -> voronoi.dat)..."
qvoronoi p Fv < nodes.dat > voronoi.dat

echo "Assembling oofem.in (converter)..."
converter control.in nodes.dat voronoi.dat

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Done. VTU output: oofem.out.m0.*.vtu"
