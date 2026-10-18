#!/bin/bash
# Remove generated artefacts. Explicit allow-list: never `git clean -fdx`,
# which would also wipe the maintainer-only local/ folder.
#
# Keeps the committed inputs (mesh.in, oofem.t3d.ctrl, oofem.in), the
# precomputed ld.dat, experiment.dat and the figure ld.pdf/png.
set -e
cd "$(dirname "$0")"
rm -f oofem.out oofem.out.* std.out mesh.out
rm -f *.vtu *.pvd *.osf *.log
echo "Cleaned $(pwd)"
