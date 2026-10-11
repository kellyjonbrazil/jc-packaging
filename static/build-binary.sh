#!/bin/bash

# Build the single-file jc binary for this machine (Linux or macOS) from a
# statically linked CPython. See README.md in this folder.
#
# usage:
# build-binary.sh <version>
#
# e.g.:
# build-binary.sh 1.26.0
#
# Writes jc-<version>-<linux|darwin>-<arch>.tar.gz and .sha256 to $HOME/dist,
# the same files the pyoxidizer build scripts produce.
#
# Optional environment variables:
#   JC_DIST          output folder (default: $HOME/dist)
#   JC_STATIC_CACHE  where downloads are unpacked (default: $HOME/.cache/jc-static)
#   JC_SITE_DIR      folder with jc and its dependencies already installed;
#                    skips the pip step (offline builds, unreleased versions)
#   JC_CORE_ARCHIVE  Linux only: a core archive made by build-core.sh on
#                    another machine, if it is not in the cache folder
#   JC_MAX_GLIBC     Linux only: fail if the binary needs a newer glibc than
#                    this (default: 2.28, "any" to accept whatever results)

set -euo pipefail

if [[ ${1:-} == "" ]]; then
    echo "Please enter the version to build."
    exit 1
fi

NAME=jc
VERSION=$1

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

DIST=${JC_DIST:-$HOME/dist}
BUILD=$HERE/build

PYTHON=$(fetch python)/python/bin/python3

rm -rf "$BUILD"
mkdir -p "$BUILD"

if [[ $OS == linux ]]; then
    # CPython and the launcher come pre-linked as the core, so that this
    # machine only needs its own assembler and linker. Use the cached core,
    # or one copied from another machine, or build it now.
    CORE=$CACHE/$CORE_NAME
    if [[ ! -e $CORE/core.json ]]; then
        ARCHIVE=${JC_CORE_ARCHIVE:-$CACHE/jc-$CORE_NAME.tar.gz}
        if [[ -e $ARCHIVE ]]; then
            echo "Unpacking $ARCHIVE"
            tar -xzf "$ARCHIVE" -C "$CACHE"
            [[ -e $CORE/core.json ]] || fail "$ARCHIVE is not the core this build needs" \
                "($CORE_NAME). It was made from different pins or scripts; build it" \
                "again with build-core.sh from this checkout."
        elif [[ ${JC_CORE_ARCHIVE:-} != "" ]]; then
            fail "JC_CORE_ARCHIVE is set but $ARCHIVE does not exist"
        else
            "$HERE/build-core.sh"
        fi
    fi

    # The C compiler driver is only used to run the linker.
    LLVM_DIR=$CACHE/$(pin llvm | cut -d' ' -f1)
    if command -v cc > /dev/null; then
        CC=cc
    elif [[ -x $LLVM_DIR/llvm/bin/clang ]]; then
        CC=$LLVM_DIR/llvm/bin/clang
    else
        fail "no C compiler driver (cc) found. Install gcc; it is only used to link."
    fi
else
    # macOS links CPython's object files directly, with the pinned clang.
    OBJECTS=$(fetch objects)/python
    CLANG=$(fetch llvm)/llvm/bin/clang
    CORE=$BUILD/core
    CC=$CLANG
    "$PYTHON" -I "$HERE/build-core.py" --objects "$OBJECTS" --clang "$CLANG" --output "$CORE"
fi

if [[ ${JC_SITE_DIR:-} != "" ]]; then
    SITE=$JC_SITE_DIR
else
    SITE=$BUILD/site
    "$PYTHON" -m pip install --disable-pip-version-check --no-compile \
        --target "$SITE" -r "$HERE/requirements.txt" "$NAME==$VERSION"
fi

# A private bytecode cache makes the interpreter start in the same state on
# every run, which keeps the embedded bytecode, and so the binary, identical
# from build to build.
"$PYTHON" -I -X pycache_prefix="$BUILD/pycache" "$HERE/build.py" \
    --core "$CORE" \
    --cc "$CC" \
    --source "$SITE" \
    --run "import jc.cli; jc.cli.main()" \
    --output "$BUILD/$NAME" \
    --work "$BUILD/work"

echo
echo "Checking the binary..."
cd "$BUILD"

about=$(./$NAME -v)
echo "$about" | sed -n '1,2p'
# First line is "jc version:  <version>".
[[ $(awk 'NR == 1 { print $NF }' <<< "$about") == "$VERSION" ]] \
    || fail "the binary is not jc $VERSION"

# One parser per optional library, so a dependency that did not make it into
# the binary fails the build instead of a user's pipeline.
[[ $(echo 'a: 1' | ./$NAME --yaml) == '[{"a":1}]' ]] || fail "the YAML parser does not work"
[[ $(echo '<a>1</a>' | ./$NAME --xml) == '{"a":"1"}' ]] || fail "the XML parser does not work"
[[ $(echo 'a: 1' | ./$NAME --yaml -C) == *$'\033['* ]] || fail "colored output does not work"
[[ $(printf 'a,b\n1,2\n' | ./$NAME --csv) == '[{"a":"1","b":"2"}]' ]] || fail "the CSV parser does not work"

if [[ $OS == linux ]]; then
    # The oldest glibc the binary runs on is decided by the machine it was
    # linked on, so check it rather than ship a surprise.
    glibc=$(objdump -T "$NAME" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)
    glibc=${glibc#GLIBC_}
    max=${JC_MAX_GLIBC:-2.28}
    echo "minimum glibc:  $glibc"
    if [[ $max != any && $(printf '%s\n%s\n' "$glibc" "$max" | sort -V | tail -1) != "$max" ]]; then
        fail "the binary needs glibc $glibc, newer than the allowed $max." \
            "Build on a machine or in a container with an older glibc, or set" \
            "JC_MAX_GLIBC=$glibc (or JC_MAX_GLIBC=any) to accept it."
    fi
fi

mkdir -p "$DIST"
$SHA256 "$NAME" > "$DIST/$NAME-$VERSION-$OS-$ARCH.sha256"
tar -czvf "$DIST/$NAME-$VERSION-$OS-$ARCH.tar.gz" "$NAME"

echo
echo "Built $DIST/$NAME-$VERSION-$OS-$ARCH.tar.gz"
