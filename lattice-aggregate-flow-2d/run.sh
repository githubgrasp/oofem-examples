#!/bin/bash
# Reproduce: 2D lattice mass-transport through a matrix with low-permeability disks
# Pipeline: aggregate -> generator -> qvoronoi -> converter -> oofem
set -e
cd "$(dirname "$0")"

echo "Generating disk packing..."
aggregate aggregate.in

echo "Generating node distribution (with inclusions)..."
generator mesh.in

echo "Building Voronoi tessellation..."
qvoronoi p Fv < mesh.nodes > mesh.voronoi

echo "Assembling oofem.in..."
converter control.in mesh.nodes mesh.voronoi

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Done. VTU output: oofem.out.m0.*.vtu"
