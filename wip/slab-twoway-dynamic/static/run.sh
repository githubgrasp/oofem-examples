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
# Requires the private Docker image (T3D bundled).

set -e
cd "$(dirname "$0")"

echo "Generating mesh with T3D..."
t3d -d 0.1 -i mesh.in -o mesh.out

echo "Assembling oofem.in..."
converter control.in mesh.out

echo "Running OOFEM (NonLinearStatic)..."
oofem -f oofem.in > std.out

echo "Done. VTU files in $(pwd) — open with ParaView."
