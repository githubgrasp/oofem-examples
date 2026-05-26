#!/bin/bash
# Remove generated artefacts in both sub-cases. Explicit allow-list.
set -e
cd "$(dirname "$0")"

for d in unconfined confined; do
    [ -d "$d" ] || continue
    rm -f "$d"/mesh.out "$d"/oofem.in
    rm -f "$d"/oofem.out "$d"/std.out
    rm -f "$d"/*.vtu "$d"/*.vtk "$d"/*.osf "$d"/*.log
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
done

rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
