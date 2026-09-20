#!/usr/bin/env bash
# Build the jc RPM and DEB packages inside a Linux container, running this
# repository's unmodified build-packages.sh. The host does not need fpm,
# rpmbuild, or dpkg.
#
#   container/run.sh <version> <release> [intel|arm]
#
#   e.g.  container/run.sh 1.26.0 1
#         container/run.sh 1.26.0 1 intel
#
# Inputs:  $JC_DIST       binaries jc-<version>-linux-<arch>.tar.gz (default ~/dist)
# Script:  $JC_PACKAGING  checkout containing build-packages.sh (default: this
#                         repository); packages are written to its dist/ folder
# Set CONTAINER_ENGINE=docker to use docker instead of podman.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG=${JC_PACKAGING:-$HERE/..}
DIST=${JC_DIST:-$HOME/dist}
ENGINE=${CONTAINER_ENGINE:-podman}
IMAGE=jc-fpm

if [ ! -f "$PKG/build-packages.sh" ]; then
    echo "error: $PKG/build-packages.sh not found (set JC_PACKAGING)" >&2
    exit 1
fi
if [ ! -d "$DIST" ]; then
    echo "error: binaries folder $DIST not found (set JC_DIST)" >&2
    exit 1
fi
PKG=$(cd "$PKG" && pwd)
DIST=$(cd "$DIST" && pwd)

# The image only holds the toolchain, so it is rebuilt only when the
# Dockerfile changes.
if ! build_log=$("$ENGINE" build --quiet --tag "$IMAGE" "$HERE" 2>&1); then
    echo "$build_log" >&2
    exit 1
fi

# build-packages.sh reads the binaries from ${HOME}/dist and writes to ./dist,
# so run it as root (HOME=/root) with the binaries mounted read-only there.
# label=disable avoids SELinux-relabeling the mounts (Fedora).
exec "$ENGINE" run --rm \
    --security-opt label=disable \
    --volume "$PKG":/work \
    --volume "$DIST":/root/dist:ro \
    --workdir /work \
    "$IMAGE" bash build-packages.sh "$@"
