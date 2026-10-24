#!/bin/bash
# Wipe per-case generated artefacts: oofem.out, ld.dat, *.vtu, stdout.log.
# Leaves oofem.in, README, plot.gp, and the Imran*.dat reference data alone.

set -e
cd "$(dirname "$0")"

for c in 0 2p15 4p3 8p6 17p2 30p1 43; do
    rm -f "$c"/oofem.out "$c"/oofem.out.* "$c"/ld.dat "$c"/stdout.log "$c"/std.out "$c"/*.vtu "$c"/*.pvtu "$c"/*.pvd
done

rm -f stress-strain.png volumetric.png std.out tri17p2.out

echo "cleaned generated artefacts in all seven case folders"
