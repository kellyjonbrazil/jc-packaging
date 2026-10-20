# Shared by build-binary.sh and build-core.sh. Not run on its own:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CACHE=${JC_STATIC_CACHE:-$HOME/.cache/jc-static}

# The clang toolchain's bundled C++ runtime needs at least this glibc to run.
TOOLCHAIN_MIN_GLIBC=2.18

fail() {
    echo >&2
    echo "error: $*" >&2
    exit 1
}

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
        fail "unsupported operating system: $(uname -s)"
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
        fail "unsupported architecture: $(uname -m)"
        ;;
esac

TRIPLE=$ARCH-$PLATFORM

# pin <kind>
# Print "<sha256> <url>" of the download pinned for this machine.
pin() {
    awk -v triple="$TRIPLE" -v kind="$1" \
        '$1 == triple && $2 == kind { print $3, $4 }' "$HERE/distributions.txt"
}

# fetch <kind>
# Download, verify and unpack the archive pinned in distributions.txt for this
# machine, unless that was already done, and print the folder it is in.
# It runs inside $(...), where bash does not apply "set -e", so every step
# checks for failure itself.
fetch() {
    local kind=$1 sha="" url="" dir file
    read -r sha url < <(pin "$kind") || true
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
            *.tar.xz)
                "$PYTHON" -I -c '
import sys, tarfile
with tarfile.open(sys.argv[1], mode="r|xz") as t:
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

# Linux only: the core is the part of the binary that depends on the Python
# version but not on jc (see build-core.py). Its name changes whenever
# something that goes into it does: the pins for this machine, the launcher,
# or the script that builds it. The mingw pin only builds the Windows
# executable, so it is not part of the name.
CORE_NAME=core-$TRIPLE-$(
    {
        awk -v triple="$TRIPLE" '$1 == triple && $2 != "mingw"' "$HERE/distributions.txt"
        cat "$HERE/launcher.c" "$HERE/build-core.py"
    } | $SHA256 | cut -c1-16
)
