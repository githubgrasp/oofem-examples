#!/bin/bash
# Reproduce: Bending a cantilever into a full circle with a large-rotation lattice
# Blog: https://petergrassl.com/blog/lattice-large-rotation/
set -e
cd "$(dirname "$0")"

# 1. Run OOFEM. The 9-node cantilever is written out in full in oofem.in,
#    so there is no mesh to generate.
echo "Running OOFEM..."
oofem -f oofem.in

# 2. Post-process: extract the moment-rotation history (ld.dat) and write one
#    deformed-shape file per step (outputStep*.dat) for the animation.
echo "Post-processing..."
bash post.sh

echo "Done. Outputs in $(pwd)"
