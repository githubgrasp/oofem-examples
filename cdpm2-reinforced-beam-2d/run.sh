#!/bin/bash
# Reproduce: CDPM2 reinforced concrete shear beam with bond-slip and the
# reinforcement as frame elements (plane stress, crack band).
# Blog: https://petergrassl.com/blog/cdpm2-reinforced-beam-2d/
#
# Runs OOFEM on the committed standalone input (oofem.in), extracts the
# load-deflection data and plots it against the bond-slip result with truss
# reinforcement (ld-truss.dat, from ../cdpm2-bondslip-2d), the perfect-bond
# result (ld-perfect.dat, from ../cdpm2-reinforced-2d) and the experiment.
# No mesh generation is needed: oofem.in already carries the full mesh,
# including the reinforcement frame elements, the duplicated nodes and the
# bond links. To regenerate it (private image only):
#   t3d -d 0.02 -p 8 -i mesh.in -o mesh.out
#   t3d2oofem oofem.t3d.ctrl mesh.out oofemTemp.in
#   duplicate oofemTemp.in oofem.in --diameter 0.052 --bond 3 4
#
#   bash run.sh             # run the analysis (about 13 min), then plot
#   SKIP_RUN=1 bash run.sh  # plot from the committed ld.dat only
#
# Outputs:
#   std.out        OOFEM stdout
#   oofem.out      OOFEM solver output (+ .vtu every 5th step)
#   ld.dat         cols: loadlevel[N]  u_y(node 4)  u_y(node 15)  [m]
#   ld.pdf/png     load vs midspan deflection: frame, truss, perfect bond, experiment
set -e
cd "$(dirname "$0")"

if [ -z "${SKIP_RUN:-}" ]; then
  echo "Running OOFEM (about 13 min)..."
  oofem -f oofem.in > std.out
  echo "Extracting load-deflection data..."
  extractor.py -f oofem.in > ld.dat
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
  set title 'Reinforced shear beam, reinforcement as frame (plane stress, CDPM2 crack band)'
  set xlabel 'Deflection [mm]'
  set ylabel 'Load P [kN]'
  set grid
  set key bottom right
  set xrange [0:3.5]; set yrange [0:80]
  plot 'ld.dat' u (D($2)):(L($1)) w l lw 2 lc rgb '#2ca02c' t 'bond-slip, frame', \
       'ld-truss.dat' u (D($2)):(L($1)) w l lw 2 lc rgb '#d62728' t 'bond-slip, truss', \
       'ld-perfect.dat' u (D($2)):(L($1)) w l lw 2 dt 2 lc rgb '#1f77b4' t 'perfect bond, truss', \
       'experiment.dat' u ($2*1000):1 w lp pt 7 ps 0.8 lc rgb 'black' t 'experiment'
}
GNUEOF

echo "Done. Outputs in $(pwd)"
