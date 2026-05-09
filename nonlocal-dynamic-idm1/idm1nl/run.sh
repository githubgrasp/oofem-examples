#!/bin/bash
# Reproduce: dynamic fracture of a notched plate — nonlocal damage (idmnl1)
# Blog: https://petergrassl.com/blog/nonlocal-dynamic-idm1/
#
# Pipeline (only steps 1-2 if T3D is on PATH; otherwise the committed
# oofem.in is used directly):
#   1. t3d        mesh.in  -> mesh.out
#   2. t3d2oofem  oofem.t3d.ctrl mesh.out -> oofem.in
#   3. oofem -f oofem.in   -> std.out, *.vtu
#
# Runtime: more than 30 min on a recent laptop (NlDEIDynamic, explicit).
# Pass --yes to skip the confirmation.
set -e
cd "$(dirname "$0")"

if [ "${1:-}" != "--yes" ]; then
    echo "This explicit dynamic analysis takes more than 30 min."
    echo "Re-run with: bash run.sh --yes"
    exit 1
fi

if command -v t3d >/dev/null 2>&1 && command -v t3d2oofem >/dev/null 2>&1; then
    echo "Generating mesh with T3D..."
    t3d -X -i mesh.in -o mesh.out -d 0.001 -p 512
    echo "Building oofem.in via t3d2oofem..."
    t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
elif [ -f oofem.in ]; then
    echo "T3D not on PATH — using committed oofem.in."
else
    echo "ERROR: T3D not on PATH and no oofem.in present." >&2
    exit 1
fi

echo "Running OOFEM (NlDEIDynamic, explicit)..."
oofem -f oofem.in > std.out

echo "Done. VTU files in $(pwd) — open with ParaView."
