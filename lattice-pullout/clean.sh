#!/bin/bash
# Remove generated artefacts. Explicit allow-list -- never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

# Generator + qvoronoi outputs
rm -f nodes.dat voronoi.dat mesh.nodes mesh.voronoi

# Converter output
rm -f oofem.in

# OOFEM run outputs
rm -f oofem.out oofem.out.* *.vtu *.vtk *.pvd

# Pipeline log files
rm -f stdMeshGenerator.out stdMeshConverter.out *.log std.out

# Editor backups
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
