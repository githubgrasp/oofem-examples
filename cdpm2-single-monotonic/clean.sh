#!/bin/bash
# Remove generated artefacts in the four sub-tests. Uses an explicit
# allow-list — never `git clean -fdx`, which would wipe every untracked
# file in the working tree (e.g. a sibling example folder you haven't
# committed yet).
set -e
cd "$(dirname "$0")"

for d in Tension Compression SimpleShear PureShear; do
    [ -d "$d" ] || continue
    rm -f "$d"/oofem.out "$d"/std.out "$d"/ld.dat "$d"/ld.pdf
    rm -f "$d"/*.vtu "$d"/*.log
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
done

rm -f ld-all.pdf ld-all.gif ld-all.mp4

echo "Cleaned $(pwd)"
