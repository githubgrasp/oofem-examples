#!/bin/bash
# Reproduce: Pull-out of a centrically embedded rebar from a concrete cylinder
# Lattice model with a bond-plasticity (latticecontact3d) steel<->concrete interface.
set -e
cd "$(dirname "$0")"

# 1. Generate the random node distribution and the Voronoi/Delaunay dual mesh.
echo "Generating nodes (generator)..."
generator mesh.in >stdMeshGenerator.out

echo "Building Voronoi diagram (qvoronoi)..."
qvoronoi p Fv <nodes.dat >voronoi.dat

# 2. Convert to an OOFEM input deck. control.in tags the ITZ shell as
#    latticecontact3d bond elements (material 3 bonded, material 4 debonded).
echo "Converting to OOFEM input (converter)..."
converter control.in nodes.dat voronoi.dat >stdMeshConverter.out

# 3. Run the pull-out analysis.
echo "Running OOFEM..."
oofem -f oofem.in >stdout.log

echo "Done. Outputs in $(pwd)"
