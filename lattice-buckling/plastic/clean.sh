#!/bin/bash
# Remove generated artefacts. Explicit allow-list: never `git clean -fdx`,
# which would also wipe any sibling untracked work.
#
# Keeps the committed oofem.in and the precomputed ld.dat.
set -e
cd "$(dirname "$0")"

rm -f oofem.out oofem.out.* std.out tmp_model_info
rm -f *.vtu *.pvd *.log
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
