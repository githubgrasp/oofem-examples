#!/bin/bash
# Remove generated artefacts in all four sub-tests; return to git-clean state.
set -e
cd "$(dirname "$0")"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git clean -fdx .
else
  for d in Tension Compression SimpleShear PureShear; do
    rm -f "$d"/oofem.out "$d"/std.out "$d"/ld.dat "$d"/ld.pdf "$d"/*.vtu "$d"/*.log
    rm -f "$d"/*~ "$d"/.\#* "$d"/\#*\#
  done
  rm -f ld-all.pdf ld-all.gif ld-all.mp4
fi

echo "Cleaned $(pwd)"
