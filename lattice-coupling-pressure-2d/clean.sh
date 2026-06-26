#!/bin/bash
# Remove generated artefacts; KEEP the b0/ b1/ source inputs (mesh.in, control.in,
# control.tm.in, oofem.smtm.in, run.sh, compare.py) and local/. Explicit
# allow-list — never `git clean -fdx` (that would also wipe the sources and local/).
set -e
cd "$(dirname "$0")"

for d in . b0 b1; do
    rm -f "$d"/mesh.nodes "$d"/mesh.voronoi "$d"/control.work.in
    rm -f "$d"/oofem.sm.in "$d"/oofem.tm.in
    rm -f "$d"/oofem.sm.out "$d"/oofem.tm.out "$d"/oofem.smtm.out "$d"/std.out
    rm -f "$d"/oofem.sm.out.* "$d"/oofem.tm.out.*
    rm -f "$d"/*.dat "$d"/*.pdf "$d"/*~
done

# NOTE: b0/ b1/ folders, their *.in / run.sh / compare.py sources, and local/
# are deliberately kept.
echo "Cleaned $(pwd)"
