#!/bin/bash
# Remove generated artefacts in the periodic and regular sub-cases.
# Explicit allow-list — never `git clean -fdx`, which would wipe every
# untracked file in the working tree.
set -e
cd "$(dirname "$0")"

for d in periodic regular; do
    [ -d "$d" ] || continue
    # Mesher / converter outputs
    rm -f "$d"/nodes.dat "$d"/mesh.nodes "$d"/mesh.voronoi
    rm -f "$d"/random.dat "$d"/stat.dat
    rm -f "$d"/oofem.in
    # OOFEM run outputs
    rm -f "$d"/oofem.out "$d"/std.out "$d"/ld.dat "$d"/ld.pdf
    rm -f "$d"/*.vtu "$d"/*.vtk "$d"/*.log
    # Editor scratch
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
done

echo "Cleaned $(pwd)"
