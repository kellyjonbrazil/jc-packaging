#!/bin/bash

# Build the "core" for this Linux machine's architecture: CPython and the
# launcher, pre-linked into one object file. See README.md in this folder.
#
# usage:
# build-core.sh
#
# build-binary.sh runs this by itself when it needs to. Run it by hand only
# to prepare a core for a build machine whose glibc is too old for the clang
# toolchain: build it here, then copy the file this reports to that machine.
#
# The core depends on the Python pinned in distributions.txt, not on the jc
# version, so it only has to be rebuilt when the pins change.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ $OS != linux ]]; then
    fail "a separate core is only used on Linux; on macOS run build-binary.sh"
fi

GLIBC=$(getconf GNU_LIBC_VERSION 2> /dev/null || true)
GLIBC=${GLIBC##* }
if [[ $GLIBC == "" || $(printf '%s\n%s\n' "$GLIBC" "$TOOLCHAIN_MIN_GLIBC" | sort -V | head -1) != "$TOOLCHAIN_MIN_GLIBC" ]]; then
    echo >&2
    echo "error: this machine has glibc ${GLIBC:-(unknown)}, and the clang toolchain that" >&2
    echo "builds the core needs $TOOLCHAIN_MIN_GLIBC or newer." >&2
    echo >&2
    echo "Build the core once on a newer $ARCH Linux machine or container, from" >&2
    echo "the same checkout:" >&2
    echo >&2
    echo "    static/build-core.sh" >&2
    echo >&2
    echo "then copy the file it reports, jc-$CORE_NAME.tar.gz," >&2
    echo "into $CACHE/ on this machine and run build-binary.sh again." >&2
    exit 1
fi

PYTHON=$(fetch python)/python/bin/python3
OBJECTS=$(fetch objects)/python
CLANG=$(fetch llvm)/llvm/bin/clang

rm -rf "$CACHE/$CORE_NAME" "$CACHE/$CORE_NAME.tmp"
"$PYTHON" -I "$HERE/build-core.py" \
    --objects "$OBJECTS" \
    --clang "$CLANG" \
    --output "$CACHE/$CORE_NAME.tmp"
mv "$CACHE/$CORE_NAME.tmp" "$CACHE/$CORE_NAME"

tar -czf "$CACHE/jc-$CORE_NAME.tar.gz" -C "$CACHE" "$CORE_NAME"

echo
echo "Core ready: $CACHE/jc-$CORE_NAME.tar.gz"
echo "To build on a machine that cannot run this step, copy that file into its"
echo "cache folder (\$HOME/.cache/jc-static unless JC_STATIC_CACHE is set)."
