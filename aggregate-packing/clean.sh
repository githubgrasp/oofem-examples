#!/bin/bash
# Remove generated artefacts. Explicit allow-list: never `git clean -fdx`,
# which would also wipe the maintainer-only local/ folder and any sibling
# untracked work.
#
# packing.dat is committed as a precomputed result, so it is NOT removed.
set -e
cd "$(dirname "$0")"

rm -f packing.vtu placement.trace
rm -f *~ .\#* \#*\#

echo "Cleaned $(pwd)"
