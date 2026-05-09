#!/bin/bash
# Remove generated artefacts; the committed oofem.in is preserved so
# users without T3D can still re-run the analysis.
set -e
cd "$(dirname "$0")"

rm -f oofem.out std.out mesh.out
rm -f *.vtu *.vtk *.osf *.log
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
