#!/bin/bash
# Remove generated artefacts across all three meshes. Explicit allow-list —
# never `git clean -fdx`, which would also wipe the maintainer-only local/
# folder and any sibling untracked work.
#
# Keeps the committed inputs (mesh.in, oofem.t3d.ctrl, oofem.in), the
# precomputed ld.dat, and the committed comparison figure ld_mesh_compare.*.
set -e
cd "$(dirname "$0")"

for m in Coarse Medium Fine; do
  [ -d "$m" ] || continue
  ( cd "$m" && bash clean.sh )
done

echo "Cleaned $(pwd)"
