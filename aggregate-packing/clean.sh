#!/bin/bash
# Remove generated artefacts; return folder to git-clean state.
set -e
cd "$(dirname "$0")"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Precise: delete anything not tracked by git
  git clean -fdx .
else
  # Fallback (e.g. inside Docker container): delete known patterns.
  # packing.dat is committed as a precomputed result, so it is NOT removed.
  rm -f packing.vtu *~
fi

echo "Cleaned $(pwd)"
