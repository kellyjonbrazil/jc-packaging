#!/bin/bash

# Rewrite distributions.txt to pin another CPython version.
#
# usage:
# update-pins.sh <python-build-standalone release> <python version>
#
# e.g.:
# update-pins.sh 20261001 3.14.8
#
# Releases, and the Python versions each one carries, are listed at
# https://github.com/astral-sh/python-build-standalone/releases
#
# Needs curl, git and python3.

set -euo pipefail

if [[ ${2:-} == "" ]]; then
    echo "usage: update-pins.sh <release> <python version>"
    echo "e.g.:  update-pins.sh 20261001 3.14.8"
    exit 1
fi

TAG=$1
VERSION=$2
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=https://github.com/astral-sh/python-build-standalone
TARGETS="x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu aarch64-apple-darwin x86_64-apple-darwin"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "error: $*" >&2
    exit 1
}

# python and objects: every release publishes the SHA-256 of each of its files.
curl -fsSL -o "$TMP/SHA256SUMS" "$REPO/releases/download/$TAG/SHA256SUMS" \
    || fail "could not download SHA256SUMS for release $TAG"

awk -v base="$REPO/releases/download/$TAG" -v prefix="cpython-$VERSION+$TAG-" '
    {
        file = $2
        sub(/^\*/, "", file)
        if (index(file, prefix) != 1) next
        triple = substr(file, length(prefix) + 1)
        if (sub(/-install_only_stripped\.tar\.gz$/, "", triple)) kind = "python"
        else if (sub(/-pgo\+lto-full\.tar\.zst$/, "", triple)) kind = "objects"
        else next
        gsub(/\+/, "%2B", file)
        print triple, kind, $1, base "/" file
    }' "$TMP/SHA256SUMS" > "$TMP/pins"

# llvm: the toolchain a release was built with is recorded in its source tree.
# Fetch only that one file from the tag.
git clone -q --depth 1 --branch "$TAG" --filter=blob:none --no-checkout \
    "$REPO.git" "$TMP/source" 2> /dev/null \
    || fail "could not fetch tag $TAG of $REPO"
git -C "$TMP/source" show HEAD:pythonbuild/downloads.json > "$TMP/downloads.json" \
    || fail "pythonbuild/downloads.json is not in release $TAG"

python3 - "$TMP/downloads.json" >> "$TMP/pins" << 'EOF'
import json
import sys

downloads = json.load(open(sys.argv[1]))
for key, triple in (
    ("llvm-x86_64-linux", "x86_64-unknown-linux-gnu"),
    ("llvm-aarch64-linux", "aarch64-unknown-linux-gnu"),
    ("llvm-aarch64-macos", "aarch64-apple-darwin"),
    ("llvm-x86_64-macos", "x86_64-apple-darwin"),
):
    entry = downloads.get(key)
    if entry:
        print(triple, "llvm", entry["sha256"], entry["url"].replace("+", "%2B"))
EOF

{
    cat << 'EOF'
# Pinned downloads for build-binary.sh, one per line:
#
#   <target triple> <kind> <sha256> <url>
#
#   python   install-only CPython; runs pip and build.py on the build machine
#   objects  the matching "full" archive: the object files and static
#            libraries that get linked into the binary
#   llvm     the clang toolchain those object files were compiled with (they
#            are LLVM bitcode, so the linker needs the same LLVM version)
#
EOF
    echo "# CPython $VERSION from python-build-standalone release $TAG."
    echo "# Written by update-pins.sh; run it again rather than editing the lines below."

    for triple in $TARGETS; do
        echo
        for kind in python objects llvm; do
            line=$(awk -v triple="$triple" -v kind="$kind" \
                '$1 == triple && $2 == kind' "$TMP/pins")
            if [[ $(grep -c . <<< "$line") != 1 ]]; then
                echo "$triple $kind" >> "$TMP/missing"
            fi
            echo "$line"
        done
    done
} > "$TMP/distributions.txt"

if [[ -e $TMP/missing ]]; then
    echo "error: release $TAG does not have these downloads for CPython $VERSION:" >&2
    sed 's/^/  /' "$TMP/missing" >&2
    echo "CPython versions in release $TAG:" >&2
    awk '{ print $2 }' "$TMP/SHA256SUMS" \
        | sed -n 's/^\*\{0,1\}cpython-\([^+]*\)+.*/\1/p' | sort -uV | tr '\n' ' ' >&2
    echo >&2
    exit 1
fi

mv "$TMP/distributions.txt" "$HERE/distributions.txt"
echo "distributions.txt now pins CPython $VERSION from release $TAG."
echo "Rebuild with build-binary.sh and check the result before committing."
