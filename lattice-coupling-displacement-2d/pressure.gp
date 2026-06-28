# Pressure figure (transport lattice vs logarithmic profile).
# Edit anything here freely: axis ranges, labels, title, colours, point size, key.
# Reads pres_lattice.dat / pres_analytic.dat (written by compare.py; columns: r/ri  P_f/Pa).
# Run standalone:   gnuplot pressure.gp      ->  pressure.pdf
#
# The guard below only sets a default PDF output when run on its own; the blog
# build sets its own terminal first (term_set=1), so you can ignore this line.
if (!exists("term_set")) { set terminal pdfcairo size 16cm,12cm font ',12'; set output 'pressure.pdf' }

set grid
set xlabel 'normalised radius  r / r_i'
set ylabel 'normalised pore pressure  P_f / P_a'
set key top right
set title "Displacement-driven coupling: transport lattice vs logarithmic P_f"

plot 'pres_lattice.dat'  using 1:2 with points pt 6 ps 0.35 lc rgb '#1f77b4' title 'lattice (transport)', \
     'pres_analytic.dat' using 1:2 with lines  lw 2.5        lc rgb '#d62728' title 'P_a ln(b/r)/ln(b/a_p)'
