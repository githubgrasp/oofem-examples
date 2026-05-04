#!/bin/bash
# Open an interactive shell in the private OOFEM image with:
#   - the current directory mounted at /work
#   - X11 forwarding so T3d's GUI shows up on the host (macOS / Linux)
#
# macOS prereq: XQuartz running. Once per XQuartz session, run on the host:
#   xhost +localhost
#
# Windows: install VcXsrv or X410, set DISPLAY accordingly. GUI is harder on
# Windows; for headless work just drop the -e DISPLAY / -v X11 lines below.

set -e
cd "$(dirname "$0")"

IMAGE="${1:-oofem-private:dev}"

docker run --rm -it \
  -e DISPLAY=host.docker.internal:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$PWD":/work \
  "$IMAGE" bash
