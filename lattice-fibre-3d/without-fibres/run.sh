#!/bin/bash
# Reproduce: 3D periodic PLAIN-MATRIX cube (no fibres), random ft.
# Identical matrix lattice and random ft field as ../with-fibres (the seeds in
# mesh.in / random.in are deterministic); the only difference is that control.in
# has no #@inclusionfile, so no fibres are discretised. The matrix damages and
# localises into a crack with nothing to bridge it -> the load drops to ~zero.
# Pipeline: genran -> generator -> qvoronoi -> converter -> oofem
set -e
cd "$(dirname "$0")"

echo "Generating random field for matrix ft (genran -> random.dat)..."
genran random.in random.dat

echo "Generating lattice nodes (generator -> nodes.dat)..."
generator mesh.in

echo "Building Voronoi tessellation (qvoronoi -> voronoi.dat)..."
qvoronoi p Fv < nodes.dat > voronoi.dat

echo "Assembling oofem.in (converter, matrix only)..."
converter control.in nodes.dat voronoi.dat

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Done. VTU output: oofem.out.m0.*.vtu"
