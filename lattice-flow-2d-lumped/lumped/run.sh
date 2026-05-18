#!/bin/bash
# Reproduce: 2D lattice mass-transport through a matrix with two ways of modelling capacity
# Pipeline: aggregate -> generator -> qvoronoi -> converter -> oofem
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

echo "Done. VTU output: oofem.out.m0.*.vtu"
