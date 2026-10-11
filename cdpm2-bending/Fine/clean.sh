#!/bin/bash
# Remove this mesh's generated artefacts. Keeps the committed inputs
# (mesh.in, oofem.t3d.ctrl, oofem.in) and the precomputed ld.dat.
set -e
cd "$(dirname "$0")"
rm -f oofem.out oofem.out.* std.out ld.pdf
rm -f *.vtu *.pvd *.osf *.log
