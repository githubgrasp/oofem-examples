#!/bin/bash
# Run both capacity variants (lumped + consistent) of the homogeneous
# 2D lattice unsaturated-flow example, then plot lumped vs consistent
# suction profiles side-by-side at four time steps.
#
# NOTE: the consistent run is expected to oscillate or struggle to
# converge — that is the demonstration. If it fails outright, the
# pipeline still produces compare.pdf showing whatever steps did run.
set -e
cd "$(dirname "$0")"

for sub in lumped consistent; do
  echo
  echo "============================================================"
  echo "  Running $sub"
  echo "============================================================"
  ( cd "$sub" && bash run.sh ) || echo "  >>> $sub run failed; continuing"
done

echo
echo "Extracting (y, p) profiles from VTUs..."
python3 compare.py

echo "Generating compare.pdf and compare.png..."
# Layout: square canvas (LinkedIn-friendly 1:1), 2x2 panels, large fonts,
# bold lines, horizontal reference at the IC bound (p = 2000) so the
# consistent-mass overshoot reads at a glance even on mobile.
gnuplot <<'EOF'
TITLE = "Homogeneous 2D lattice van Genuchten flow: lumped vs consistent capacity"
STEPS_STR = "10 30 50 80"

set multiplot_layout = ''  # placeholder so the heredoc reads cleanly

do for [out in "pdf png"] {
    if (out eq "pdf") {
        set terminal pdfcairo size 24cm,24cm enhanced font ',16'
        set output 'compare.pdf'
    } else {
        set terminal pngcairo size 1200,1200 enhanced font ',18'
        set output 'compare.png'
    }

    set multiplot layout 2,2 title TITLE font ',20' margins 0.10,0.97,0.08,0.93 spacing 0.10,0.10
    set grid lw 1.5
    set xlabel 'y [m]'        font ',18'
    set ylabel 'suction p'    font ',18'
    set tics font ',14'
    set xrange [0:0.1]
    set yrange [-100:2500]
    set key top right font ',14' box opaque

    do for [i=1:4] {
        s = word(STEPS_STR, i)
        set title sprintf("step = %s", s) font ',18'
        set arrow 1 from 0,2000 to 0.1,2000 nohead lw 2 dt 3 lc rgb '#888888' front
        set label 1 "IC bound" at first 0.094, 2080 right font ',12' tc rgb '#555555' front
        plot 'lumped/profile_'.s.'_binned.dat'     using 1:3 with lines lw 4 dt 1 lc rgb '#1f77b4' title 'lumped',     \
             'consistent/profile_'.s.'_binned.dat' using 1:3 with lines lw 4 dt (4,3) lc rgb '#d62728' title 'consistent'
        unset arrow 1
        unset label 1
    }
    unset multiplot
    unset output
}
EOF

echo
echo "Done."
echo "  Per-variant VTU: lumped/oofem.out.m0.*.vtu  consistent/oofem.out.m0.*.vtu"
echo "  Profile data:    lumped/profile_*.dat  consistent/profile_*.dat"
echo "  Comparison plot: compare.pdf, compare.png (LinkedIn-friendly)"
