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
#   JC_MAX_GLIBC     Linux only: fail if the binary needs a newer glibc than
#                    this (default: 2.28, "any" to accept whatever results)

set -euo pipefail

if [[ ${1:-} == "" ]]; then
    echo "Please enter the version to build."
    exit 1
fi

NAME=jc
VERSION=$1
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CACHE=${JC_STATIC_CACHE:-$HOME/.cache/jc-static}
DIST=${JC_DIST:-$HOME/dist}
BUILD=$HERE/build

case "$(uname -s)" in
    Linux)
        OS=linux
        PLATFORM=unknown-linux-gnu
        SHA256="sha256sum"
        ;;
    Darwin)
        OS=darwin
        PLATFORM=apple-darwin
        SHA256="shasum -a 256"
        # The toolchain is not Apple's clang, so tell it where the SDK is.
        SDKROOT=${SDKROOT:-$(xcrun --show-sdk-path)}
        export SDKROOT
        ;;
    *)
        echo "Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

# Under Rosetta uname reports x86_64, which builds the Intel macOS binary.
case "$(uname -m)" in
    x86_64)
        ARCH=x86_64
        ;;
    aarch64 | arm64)
        ARCH=aarch64
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

TRIPLE=$ARCH-$PLATFORM

# fetch <kind>
# Download, verify and unpack the archive pinned in distributions.txt for this
# machine, unless that was already done, and print the folder it is in.
# It runs inside $(...), where bash does not apply "set -e", so every step
# checks for failure itself.
fetch() {
    local kind=$1 sha="" url="" dir file
    read -r sha url < <(awk -v triple="$TRIPLE" -v kind="$kind" \
        '$1 == triple && $2 == kind { print $3, $4 }' "$HERE/distributions.txt") || true
    if [[ $url == "" ]]; then
        echo "error: no $kind download is pinned for $TRIPLE in distributions.txt" >&2
        exit 1
    fi

    dir=$CACHE/$sha
    if [[ ! -e $dir/.unpacked ]]; then
        file=$CACHE/${url##*/}.part
        echo "Downloading ${url##*/}" >&2
        mkdir -p "$CACHE" || exit 1
        curl -fsSL --retry 3 -o "$file" "$url" || exit 1
        echo "$sha  $file" | $SHA256 -c - >&2 || exit 1

        rm -rf "$dir"
        mkdir -p "$dir" || exit 1
        case $url in
            *.tar.gz)
                tar -xzf "$file" -C "$dir" || exit 1
                ;;
            *.tar.zst)
                # CPython 3.14 reads zstandard itself, so no zstd tool is needed.
                "$PYTHON" -I -c '
import sys, tarfile
from compression import zstd
with zstd.open(sys.argv[1], "rb") as z, tarfile.open(fileobj=z, mode="r|") as t:
    t.extractall(sys.argv[2], filter="tar")
' "$file" "$dir" || exit 1
                ;;
            *)
                echo "error: do not know how to unpack ${url##*/}" >&2
                exit 1
                ;;
        esac
        rm -f "$file"
        touch "$dir/.unpacked" || exit 1
    fi
    echo "$dir"
}

fail() {
    echo
    echo "error: $*" >&2
    exit 1
}

PYTHON=$(fetch python)/python/bin/python3
OBJECTS=$(fetch objects)/python
CLANG=$(fetch llvm)/llvm/bin/clang

rm -rf "$BUILD"
mkdir -p "$BUILD"

if [[ ${JC_SITE_DIR:-} != "" ]]; then
    SITE=$JC_SITE_DIR
else
    SITE=$BUILD/site
    "$PYTHON" -m pip install --disable-pip-version-check --no-compile \
        --target "$SITE" -r "$HERE/requirements.txt" "$NAME==$VERSION"
fi

"$PYTHON" -I "$HERE/build.py" \
    --objects "$OBJECTS" \
    --clang "$CLANG" \
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
    glibc=$("$(dirname "$CLANG")/llvm-objdump" -T "$NAME" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)
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
