#!/bin/bash
# Reproduce: Periodic aggregate packing of an RVE
# Blog: https://petergrassl.com/blog/aggregate-packing/
set -e
cd "$(dirname "$0")"

# Generate the packing. `aggregate` reads the #@ directives in control.in,
# runs the trial-and-error placer, and writes packing.dat (the inclusion
# list) plus packing.vtu (a ParaView-loadable surface tessellation).
# The seed in control.in makes the result deterministic.
echo "Generating aggregate packing..."
aggregate control.in

echo "Done. Outputs in $(pwd)"
