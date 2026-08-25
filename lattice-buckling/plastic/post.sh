# Extract the load-rotation history into ld.dat. Columns:
#   1      end rotation theta at the pin   (node 1, dof 6)   [rad]
#   2      axial reaction = applied load P (node 1, dof 1)   [N]
#   3      step / pseudo-time
#   4-15   axial (x) displacements of nodes 1-12             [m]
#   16-27  lateral (y) displacements of nodes 1-12           [m]  (midspan = 21/22)
# Normalise column 2 by Pcr = EI = 1.66e6 N to compare with matlabPerfect.dat.
extractor.py -f oofem.in >ld.dat;
