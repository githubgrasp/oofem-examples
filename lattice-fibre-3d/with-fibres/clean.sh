#!/bin/bash
# Remove generated artefacts. Explicit allow-list — never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

# Aggregate placer
rm -f packing.dat

# Genran random-field outputs
rm -f random.dat stat.dat

# Generator + qvoronoi outputs
rm -f nodes.dat voronoi.dat mesh.nodes mesh.voronoi

# Converter output
rm -f oofem.in

# OOFEM run outputs. Gauss-point exports use the oofem.out.* prefix.
rm -f oofem.out oofem.out.* *.vtu *.vtk *.pvd

# Pipeline log files
rm -f *.log std.out

# Editor backups
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
