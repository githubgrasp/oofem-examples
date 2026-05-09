#!/bin/bash
# Remove generated artefacts. Explicit allow-list — never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

rm -f packing.dat mesh.nodes mesh.voronoi
rm -f oofem.in oofem.out std.out
rm -f *.vtu *.vtk *.osf *.log
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
