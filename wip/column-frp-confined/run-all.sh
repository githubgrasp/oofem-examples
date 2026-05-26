#!/bin/bash
# Run both confined and unconfined cases.
set -e
cd "$(dirname "$0")"

for sub in unconfined confined; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
done

echo
echo "Done. VTU files: unconfined/oofem.out.m0.*.vtu  confined/oofem.out.m0.*.vtu"
