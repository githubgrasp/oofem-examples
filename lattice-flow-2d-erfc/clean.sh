#!/bin/bash
# Remove generated artefacts. Explicit allow-list — never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

rm -f mesh.nodes mesh.voronoi
rm -f oofem.in oofem.out std.out
rm -f profile_*.dat analytical_*.dat compare.pdf
rm -f *.vtu *.vtk *.log
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
