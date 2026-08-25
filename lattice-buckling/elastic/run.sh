#!/bin/bash
# Reproduce: Elastic buckling of an imperfect strut with the large-rotation lattice
# Blog: https://petergrassl.com/blog/lattice-buckling/
set -e
cd "$(dirname "$0")"

# 1. Run OOFEM. The 12-node pin-pin strut (with its half-sine imperfection) is
#    written out in full in oofem.in, so there is no mesh to generate.
echo "Running OOFEM..."
oofem -f oofem.in

# 2. Post-process: extract the load-rotation history into ld.dat.
echo "Post-processing..."
bash post.sh

echo "Done. Outputs in $(pwd)"
