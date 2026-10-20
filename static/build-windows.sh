#!/bin/bash

# Build jc for 64-bit Windows from Linux or macOS: the .zip archive and the
# .msi installer. See README.md in this folder.
#
# usage:
# build-windows.sh <version>
#
# e.g.:
# build-windows.sh 1.26.2
#
# Writes jc-<version>-windows.zip and jc-<version>.msi to $HOME/dist, the
# names the PyOxidizer Windows build used.
#
# Optional environment variables:
#   JC_DIST          output folder (default: $HOME/dist)
#   JC_STATIC_CACHE  where downloads are unpacked (default: $HOME/.cache/jc-static)
#   JC_SITE_DIR      folder with jc and its dependencies already installed for
#                    Windows; skips the pip step (offline builds, unreleased versions)
#   JC_NO_MSI        set to 1 to make only the zip archive

set -euo pipefail

if [[ ${1:-} == "" ]]; then
    echo "Please enter the version to build."
    exit 1
fi

NAME=jc
VERSION=$1
WINDOWS_TRIPLE=x86_64-pc-windows-msvc

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

DIST=${JC_DIST:-$HOME/dist}
BUILD=$HERE/build/windows

# The MSI is written by wixl, from msitools. Check for it before the long part.
if [[ ${JC_NO_MSI:-} != 1 ]] && ! command -v wixl > /dev/null; then
    fail "wixl is needed to make the .msi. Install msitools (macOS: brew install" \
        "msitools; Debian/Ubuntu: apt install wixl; Fedora: dnf install msitools)," \
        "or set JC_NO_MSI=1 to make only the zip."
fi

# This machine's CPython runs pip and build.py. It must be the same version
# as the Windows CPython, because build.py embeds bytecode.
PYTHON=$(fetch python)/python/bin/python3
WINDOWS_PYTHON=$(TRIPLE=$WINDOWS_TRIPLE && fetch python)/python
MINGW=$(fetch mingw)
MINGW=$(echo "$MINGW"/llvm-mingw-*)
[[ -x $MINGW/bin/x86_64-w64-mingw32-clang ]] || fail "no llvm-mingw toolchain in $MINGW"

rm -rf "$BUILD"
mkdir -p "$BUILD"

if [[ ${JC_SITE_DIR:-} != "" ]]; then
    SITE=$JC_SITE_DIR
else
    # Wheels for Windows: pip resolves the dependencies as on Windows and
    # never compiles anything here.
    SITE=$BUILD/site
    PY_MINOR=$("$PYTHON" -I -c 'import sys; print("%d%d" % sys.version_info[:2])')
    "$PYTHON" -m pip install --disable-pip-version-check --no-compile \
        --platform win_amd64 --implementation cp --python-version "$PY_MINOR" \
        --abi "cp$PY_MINOR" --only-binary=:all: \
        --target "$SITE" -r "$HERE/requirements.txt" "$NAME==$VERSION"
fi

"$PYTHON" -I "$HERE/build-windows.py" \
    --version "$VERSION" \
    --python "$WINDOWS_PYTHON" \
    --mingw "$MINGW" \
    --site "$SITE" \
    --build "$BUILD" \
    --dist "$DIST"

STAGE=$BUILD/$NAME-$VERSION-windows

# jc.exe cannot run here, but Wine can run it, if it is installed.
if command -v wine > /dev/null; then
    echo
    echo "Checking the binary under Wine..."
    jc() { WINEDEBUG=-all wine "$STAGE/$NAME.exe" "$@" | tr -d '\r'; }
    about=$(jc -v)
    echo "$about" | sed -n '1,2p'
    [[ $(awk 'NR == 1 { print $NF }' <<< "$about") == "$VERSION" ]] \
        || fail "the binary is not jc $VERSION"
    [[ $(echo 'a: 1' | jc --yaml) == '[{"a":1}]' ]] || fail "the YAML parser does not work"
    [[ $(echo '<a>1</a>' | jc --xml) == '{"a":"1"}' ]] || fail "the XML parser does not work"
    [[ $(printf 'a,b\n1,2\n' | jc --csv) == '[{"a":"1","b":"2"}]' ]] || fail "the CSV parser does not work"
else
    echo
    echo "note: jc.exe was not run, as Wine is not installed. Check it on Windows."
fi

if [[ ${JC_NO_MSI:-} != 1 ]]; then
    wixl -a x64 -o "$DIST/$NAME-$VERSION.msi" "$BUILD/$NAME.wxs"
    echo
    echo "Built $DIST/$NAME-$VERSION-windows.zip and $DIST/$NAME-$VERSION.msi"
else
    echo
    echo "Built $DIST/$NAME-$VERSION-windows.zip"
fi
