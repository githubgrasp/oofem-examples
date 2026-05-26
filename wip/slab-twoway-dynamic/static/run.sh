#!/bin/bash
# Reproduce: 1x1 m two-way slab (shell lattice, thickness 10 mm) under
# uniformly distributed static load. Static reference for the dynamic
# triangular-pulse companion run.
#
# Pipeline:
#   1. t3d       mesh.in -> mesh.out
#   2. converter control.in mesh.out -> oofem.in
#   3. oofem -f  oofem.in -> std.out, *.vtu
#
# Full pipeline needs T3D (private Docker image). With only the public
# image, the committed oofem.in is used directly.

set -e
cd "$(dirname "$0")"

if command -v t3d >/dev/null 2>&1 && command -v converter >/dev/null 2>&1; then
    echo "Generating mesh with T3D..."
    t3d -d 0.1 -i mesh.in -o mesh.out
    echo "Assembling oofem.in..."
    converter control.in mesh.out
elif [ -f oofem.in ]; then
    echo "T3D not on PATH — using committed oofem.in."
else
    echo "ERROR: T3D not on PATH and no oofem.in present." >&2
    exit 1
fi

echo "Running OOFEM (NonLinearStatic)..."
oofem -f oofem.in > std.out

echo "Done. VTU files in $(pwd) — open with ParaView."
