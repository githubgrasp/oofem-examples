#!/bin/bash
# Run all seven confinement cases, extract ld.dat, refresh the comparison plots.
#
# Each case folder contains an oofem.in. Per case:
#   1. oofem -f oofem.in           -> oofem.out, *.vtu
#   2. extractor.py -f oofem.in    -> ld.dat (axial strain, lateral strain,
#                                            axial stress[Pa], step)
# Then a single gnuplot pass produces stress-strain.png and volumetric.png
# overlaying all seven OOFEM curves with the Imran experimental data.

set -e
cd "$(dirname "$0")"

CASES="0 2p15 4p3 8p6 17p2 30p1 43"

# Locate extractor.py (assumed installed at OOFEM_ROOT/tools/extractor.py)
EXTRACTOR=$(command -v extractor.py 2>/dev/null || true)
if [ -z "$EXTRACTOR" ]; then
    if [ -n "$OOFEM_ROOT" ] && [ -f "$OOFEM_ROOT/tools/extractor.py" ]; then
        EXTRACTOR="$OOFEM_ROOT/tools/extractor.py"
    elif [ -f "$HOME/Software/oofem/tools/extractor.py" ]; then
        EXTRACTOR="$HOME/Software/oofem/tools/extractor.py"
    else
        echo "ERROR: extractor.py not found. Set OOFEM_ROOT or add to PATH." >&2
        exit 1
    fi
fi

for c in $CASES; do
    echo "=== $c MPa ==="
    cd "$c"
    oofem -f oofem.in > stdout.log 2>&1
    python3 "$EXTRACTOR" -f oofem.in 2>/dev/null > ld.dat
    cd ..
done

echo "=== plotting ==="
gnuplot plot.gp
echo "wrote stress-strain.png and volumetric.png"
