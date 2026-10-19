#!/bin/bash
# Remove generated artefacts in both sub-cases. Explicit allow-list:
# never `git clean -fdx`, which would also wipe the maintainer-only local/
# folder and any sibling untracked work.
#
# Keeps the committed inputs (mesh.in, oofem.t3d.ctrl, oofem.in, view.pvsm)
# and the precomputed ld.dat.
set -e
cd "$(dirname "$0")"

for d in unconfined confined; do
    [ -d "$d" ] || continue
    rm -f "$d"/mesh.out
    rm -f "$d"/oofem.out "$d"/std.out
    rm -f "$d"/*.vtu "$d"/*.vtk "$d"/*.pvd "$d"/*.osf "$d"/*.log
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
done

rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
