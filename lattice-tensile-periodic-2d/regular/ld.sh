#!/bin/bash
# Re-extract ld.dat (load-displacement) from an existing std.out, without
# re-running OOFEM. Useful when only the post-processing changed.
set -e
cd "$(dirname "$0")"
awk '/^NRSolver:[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[+-]/ {print $4, $5}' std.out > ld.dat
echo "Wrote $(pwd)/ld.dat"
