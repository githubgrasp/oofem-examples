 awk '/^NRSolver:[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[+-]/ {print $4, $5}' std.out > ld.dat
