#!/bin/bash
# Reproduce: CDPM2 three-point bending (plane stress), ligament mesh refinement.
# Blog: https://petergrassl.com/blog/<TODO-slug>/
#
# Runs all three meshes (Coarse / Medium / Fine) and builds the mesh-refinement
# comparison figure ld_mesh_compare.{pdf,png}: a peak-region detail panel and a
# full-range panel, all three meshes overlaid.
#
# Each run is a full nonlinear analysis and can take tens of minutes per mesh.
# The committed ld.dat files already hold the results, so if you only want the
# comparison figure you can skip the runs — see SKIP_RUNS below.
#
#   bash run-all.sh            # run all three meshes, then plot
#   SKIP_RUNS=1 bash run-all.sh # plot from the committed ld.dat only
set -e
cd "$(dirname "$0")"

if [ -z "${SKIP_RUNS:-}" ]; then
  for m in Coarse Medium Fine; do
    echo
    echo "============================================================"
    echo "  Running $m"
    echo "============================================================"
    ( cd "$m" && bash run.sh )
  done
else
  echo "SKIP_RUNS set — plotting from committed ld.dat without re-running."
fi

echo
echo "Building mesh-refinement comparison figure..."
# Load[kN] = -col1/1000 ; CMOD[mm] = (u_x(node4) - u_x(node3)) * 1000
gnuplot <<'EOF'
L(c)   = -c/1000.0
M(a,b) = (b-a)*1000.0

do for [t=1:2] {
  if (t==1) { set terminal pdf size 26cm,13cm; set output 'ld_mesh_compare.pdf' }
  if (t==2) { set terminal pngcairo size 1100,620 enhanced font ',11'; set output 'ld_mesh_compare.png' }

  set multiplot layout 1,2 \
    title "Three-point bending (plane stress, CDPM2): ligament mesh refinement"
  set xlabel 'CMOD [mm]'
  set ylabel 'Load [kN]'
  set grid

  set title 'peak region'
  set key top right
  set xrange [0:0.08]; set yrange [3:10]
  plot 'Coarse/ld.dat' u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#2ca02c' t 'Coarse (0.14, 775)', \
       'Medium/ld.dat' u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#1f77b4' t 'Medium (0.07, 961)', \
       'Fine/ld.dat'   u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#d62728' t 'Fine (0.035, 1453)'

  set title 'full range'
  unset key
  set xrange [0:*]; set yrange [0:10]
  plot 'Coarse/ld.dat' u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#2ca02c', \
       'Medium/ld.dat' u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#1f77b4', \
       'Fine/ld.dat'   u (M($2,$3)):(L($1)) w l lw 2 lc rgb '#d62728'

  unset multiplot
}
EOF

echo
echo "Fracture-energy sanity check (work of fracture)..."
# G_F = (1/A_lig) * integral( P d(delta) ), with
#   P     = -col1                 applied load [N]
#   delta = -col4 = -u_y(node17)  load-point deflection [m]
#   A_lig = b*(D-a) = 0.04*(0.5-0.15) = 0.014 m^2   (ligament area)
# Density is d=0, so no self-weight correction is needed.
#
# Input material G_f for the committed con2dpm line (softeningType 1,
# bilinear with defaults ft1 = 0.3*ft, wf1 = 0.15*wf):
#   G_f = 0.5*ft*wf1 + 0.5*ft1*wf = 60.0 J/m^2
# Each run must reach ~complete separation (load -> 0) for the integral to be
# meaningful; with the crack band regularised, G_F should converge to G_f from
# above as the ligament mesh is refined.
printf '  input G_f (bilinear, ft1=0.3ft, wf1=0.15wf): 60.0 J/m^2\n'
printf '  %-8s %8s %10s %10s %8s\n' mesh d_end_mm Pend/Pmax G_F G_F/Gf
for m in Coarse Medium Fine; do
  awk -v M="$m" 'BEGIN{Alig=0.014; Gf=60.0; W=0; Pmax=0; first=1}
    {P=-$1; d=-$4;
     if(P>Pmax)Pmax=P;
     if(!first)W += 0.5*(P+prevP)*(d-prevd);
     prevP=P; prevd=d; dend=d; Pend=P; first=0}
    END{g=W/Alig; printf "  %-8s %8.3f %10.3f %10.1f %8.2f\n", M, dend*1000, Pend/Pmax, g, g/Gf}' \
    "$m/ld.dat"
done

echo
echo "Done."
echo "  Per-mesh plots:    {Coarse,Medium,Fine}/ld.pdf"
echo "  Comparison figure: ld_mesh_compare.pdf / ld_mesh_compare.png"
