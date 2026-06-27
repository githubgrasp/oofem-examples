#!/bin/bash
# Remove generated artefacts; KEEP the source inputs (mesh.in, control.in,
# control.tm.in, oofem.smtm.in, run.sh, compare.py, README.md) and local/.
# Explicit allow-list -- never `git clean -fdx` (that would wipe the sources).
set -e
cd "$(dirname "$0")"

rm -f mesh.nodes mesh.voronoi
rm -f oofem.sm.in oofem.tm.in
rm -f oofem.sm.out oofem.tm.out oofem.smtm.out std.out
rm -f oofem.sm.out.* oofem.tm.out.*
rm -f *.dat *.pdf *~

echo "Cleaned $(pwd)  (sources and local/ kept)"
