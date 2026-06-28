# Displacement figure (matrix lattice vs poroelastic annulus).
# Edit anything here freely: axis ranges, labels, title, colours, point size, key.
# Reads disp_lattice.dat / disp_analytic.dat (written by compare.py; columns: r/ri  u_r/ri).
# Run standalone:   gnuplot displacement.gp  ->  displacement.pdf
#
# The guard below only sets a default PDF output when run on its own; the blog
# build sets its own terminal first (term_set=1), so you can ignore this line.
if (!exists("term_set")) { set terminal pdfcairo size 16cm,12cm font ',12'; set output 'displacement.pdf' }

set grid
set xlabel 'normalised radius  r / r_i'
set ylabel 'normalised radial displacement  u_r / r_i'
set yrange [:]
set key bottom right
set title "Displacement-driven inclusion: matrix lattice vs poroelastic annulus"

plot 'disp_lattice.dat'  using 1:2 with points pt 6 ps 0.35 lc rgb '#1f77b4' title 'lattice (matrix)', \
     'disp_analytic.dat' using 1:2 with lines  lw 2.5        lc rgb '#d62728' title 'poroelastic (predicted from P_a)'
