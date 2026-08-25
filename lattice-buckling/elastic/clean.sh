#!/bin/bash
# Remove generated artefacts; return folder to git-clean state.
set -e
cd "$(dirname "$0")"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Precise: delete anything not tracked by git
  git clean -fdx .
else
  # Fallback (e.g. inside Docker container): delete known patterns
  rm -f *.out *.out.* *.vtu *.pvd *.log *~ tmp_model_info ld.dat
fi

echo "Cleaned $(pwd)"
