#!/bin/bash
# Reproduce: CDPM2 reinforced concrete shear beam (plane stress, crack band).
# Blog: https://petergrassl.com/blog/cdpm2-reinforced-2d/
#
# Runs OOFEM on the committed standalone input (oofem.in), extracts the
# load-deflection data and plots it against the experiment.
# No mesh generation is needed: oofem.in already carries the full mesh,
# including the reinforcement truss elements. To regenerate it from the T3D
# source (private image only):
#   t3d -d 0.02 -p 8 -i mesh.in -o mesh.out
#   t3d2oofem oofem.t3d.ctrl mesh.out oofem.in
#
#   bash run.sh             # run the analysis (about 4 min), then plot
#   SKIP_RUN=1 bash run.sh  # plot from the committed ld.dat only
#
# Outputs:
#   std.out        OOFEM stdout
#   oofem.out      OOFEM solver output (+ .vtu every 5th step)
#   ld.dat         cols: loadlevel[N]  u_y(node 4)  u_y(node 15)  u_y(node 18)  u_y(node 19)  [m]
#   ld.pdf/png     load vs midspan deflection, with the experiment
set -e
cd "$(dirname "$0")"

if [ -z "${SKIP_RUN:-}" ]; then
  echo "Running OOFEM (about 4 min)..."
  oofem -f oofem.in > std.out
  echo "Extracting load-deflection data..."
  extractor -f oofem.in > ld.dat
else
  echo "SKIP_RUN set: plotting from the committed ld.dat."
fi

echo "Plotting ld.pdf / ld.png..."
# Load[kN] = -col1/1000 ; deflection[mm] = -col2*1000 (bottom of midspan, node 4)
gnuplot <<'GNUEOF'
L(c) = -c/1000.0
D(u) = -u*1000.0
do for [t=1:2] {
  if (t==1) { set terminal pdf size 16cm,11cm; set output 'ld.pdf' }
  if (t==2) { set terminal pngcairo size 900,620 enhanced font ',11'; set output 'ld.png' }
  set title 'Reinforced shear beam (plane stress, CDPM2 crack band)'
  set xlabel 'Deflection [mm]'
  set ylabel 'Load P [kN]'
  set grid
  set key bottom right
  set xrange [0:3.5]; set yrange [0:80]
  plot 'ld.dat' u (D($2)):(L($1)) w l lw 2 lc rgb '#d62728' t 'CDPM2', \
       'experiment.dat' u ($2*1000):1 w lp pt 7 ps 0.8 lc rgb 'black' t 'experiment'
}
GNUEOF

echo "Done. Outputs in $(pwd)"
