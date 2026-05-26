#!/bin/bash
# Reproduce: plain concrete cylinder (100 mm diameter × 200 mm tall),
# axial compression. No FRP wrap.
#
# Pipeline:
#   1. t3d       mesh.in -> mesh.out
#   2. t3d2oofem oofem.t3d.ctrl mesh.out -> oofem.in
#   3. oofem -f  oofem.in -> std.out, *.vtu
#
# Requires the private Docker image (T3D bundled). See the student-projects
# page on petergrassl.com for setup.

set -e
cd "$(dirname "$0")"

if command -v t3d >/dev/null 2>&1 && command -v t3d2oofem >/dev/null 2>&1; then
    echo "Generating mesh with T3D..."
    t3d -i mesh.in -o mesh.out -d 0.01 -p 8
    echo "Building oofem.in via t3d2oofem..."
    t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
elif [ -f oofem.in ]; then
    echo "T3D not on PATH — using committed oofem.in."
else
    echo "ERROR: T3D not on PATH and no oofem.in present." >&2
    exit 1
fi

echo "Running OOFEM..."
oofem -f oofem.in > std.out

echo "Done. VTU files in $(pwd) — open with ParaView."
