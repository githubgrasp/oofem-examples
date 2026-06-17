set -e
genran random.in random.dat
generator mesh.in >stdMeshGenerator.out
qvoronoi p Fv <nodes.dat > voronoi.dat;
converter control.in nodes.dat voronoi.dat >stdMeshConverter.out 
