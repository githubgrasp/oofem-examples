#!/bin/bash
# Run both static and dynamic cases.
set -e
cd "$(dirname "$0")"

for sub in static dynamic; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
done

echo
echo "Done. VTU files: static/oofem.out.m0.*.vtu  dynamic/oofem.out.m0.*.vtu"
