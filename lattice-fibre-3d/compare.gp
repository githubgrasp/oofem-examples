#!/usr/bin/env gnuplot
# Load-displacement comparison: periodic SFRC cube in uniaxial tension, the
# SAME matrix lattice, with vs without fibres. Re-plot without re-running:
#   gnuplot compare.gp
#
# ld.dat columns (from extractor reading the #%BEGIN_CHECK% block):
#   1: control-node dof 32 = displacement u_y [m]; strain eps_yy = u_y / l_p
#   2: load level          (total face force; sigma_yy = load level / area)
#   3: time / step
#
# y-axis: column 2 is the CALM load level = total force on the loaded cell face.
# Macroscopic stress sigma_yy = load level / (cross-section area), then Pa -> MPa.
# Cross-section of the 30 mm cube: A = 0.03 * 0.03 = 9e-4 m^2.
YSCALE = 1.0/(9.e-4*1.e6)   # = 1/900 ; load level [N] -> sigma_yy [MPa]

# x-axis: control-node dof 32 is the displacement u_y at the cell corner
# (0.03,0.03,0.03), so u_y = eps_yy * l_p. Recover strain by dividing by the
# periodic cell length l_p, then * 1000 for mm/m.
LP = 0.03                   # periodic cell length [m]

set terminal pdf size 14cm,10cm
set output 'ld-compare.pdf'
set xlabel 'Macroscopic strain eps_{yy} [mm/m]'
set ylabel 'Macroscopic stress sigma_{yy} [MPa]'
set title 'Periodic SFRC cube, uniaxial tension: effect of fibres'
set grid
set key top right

plot \
  'with-fibres/ld.dat'    using ($1/LP*1000):($2*YSCALE) with linespoints lw 2 pt 7 ps 0.4 lc rgb '#1f77b4' title 'with fibres (Vf = 1%)', \
  'without-fibres/ld.dat' using ($1/LP*1000):($2*YSCALE) with linespoints lw 2 pt 7 ps 0.4 lc rgb '#d62728' title 'plain matrix'
