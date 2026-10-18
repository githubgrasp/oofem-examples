#!/bin/bash
# Top-level driver: run both the local (idm1) and nonlocal (idm1nl)
# explicit-dynamic analyses of the Homalite cruciform. Each is an explicit
# NlDEIDynamic run of ~1000+ steps and takes a while, so --yes is required
# (passed through to the sub-scripts).
#
# Reproduce (public image):
#   docker run --rm -v "$PWD":/work ghcr.io/githubgrasp/oofem-public:latest bash run.sh --yes
set -e
cd "$(dirname "$0")"

if [ "${1:-}" != "--yes" ]; then
    echo "These explicit dynamic analyses take a while (~1000+ steps each)."
    echo "Re-run with: bash run.sh --yes"
    exit 1
fi

for d in idm1 idm1nl; do
    echo "============================================================"
    echo "  Running $d"
    echo "============================================================"
    bash "$d/run.sh" --yes
done

echo
echo "Done. VTU files in idm1/ and idm1nl/. Open with ParaView."
