#!/bin/bash
# Remove generated artefacts in both capacity variants.
# Explicit allow-list — never `git clean -fdx`.
set -e
cd "$(dirname "$0")"

for d in lumped consistent; do
    [ -d "$d" ] || continue
    rm -f "$d"/mesh.nodes "$d"/mesh.voronoi
    rm -f "$d"/oofem.in "$d"/oofem.out "$d"/std.out
    rm -f "$d"/profile_*.dat
    rm -f "$d"/*.vtu "$d"/*.vtk "$d"/*.log
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
done

# Parent-level comparison artefacts
rm -f analytical_*.dat compare.pdf compare.png
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
