#!/bin/bash
# Remove generated artefacts. Explicit allow-list — never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

# Generator + qvoronoi outputs (legacy and modern names)
rm -f nodes.dat voronoi.dat mesh.nodes mesh.voronoi

# Genran random-field outputs
rm -f random.dat stat.dat

# Converter output
rm -f oofem.in

# OOFEM run outputs. Gauss-point exports use the oofem.out.* prefix.
rm -f oofem.out oofem.out.* *.vtu *.vtk *.pvd

# Pipeline log files
rm -f stdMeshGenerator.out stdMeshConverter.out *.log std.out

# Post-processing
rm -f pressure.dat pressure-penetration.pdf

# Editor backups
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
