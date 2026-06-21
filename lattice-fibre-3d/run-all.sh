#!/bin/bash
# Run the SFRC comparison: identical matrix, with vs without fibres.
# For each case: full pipeline -> oofem, then extract ld.dat (macroscopic
# strain eps_yy vs load level). Finally a combined load-displacement plot
# ld-compare.pdf for the blog post.
set -e
cd "$(dirname "$0")"

# Locate a working extractor. The Docker image ships `extractor` on PATH; a
# local install may be a python2 script with a broken shebang, so prefer the
# python3 tools/extractor.py when it exists.
EXTRACTOR=""
for cand in "${OOFEM_ROOT:-}/tools/extractor.py" "$HOME/Software/oofem/tools/extractor.py"; do
  [ -f "$cand" ] && { EXTRACTOR="python3 $cand"; break; }
done
[ -z "$EXTRACTOR" ] && EXTRACTOR="extractor"
echo "Using extractor: $EXTRACTOR"

for sub in with-fibres without-fibres; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh )
  echo "Extracting load-displacement ($sub/ld.dat)..."
  ( cd "$sub" && $EXTRACTOR -f oofem.in > ld.dat )
done

echo
echo "Generating comparison plot ld-compare.pdf..."
gnuplot compare.gp

echo
echo "Done."
echo "  Per-case data:   {with,without}-fibres/ld.dat"
echo "  Comparison plot: ld-compare.pdf"
