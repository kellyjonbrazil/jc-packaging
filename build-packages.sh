#!/bin/bash

# usage:
# build-packages.sh <version> <build> [<architecture>]
# architecture options: intel, arm (otherwise will build both)
#
# e.g.:
# build-packages.sh 1.10.5 1 intel

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

if [[ $2 == "" ]]; then
    echo "Please enter the release number."
    exit
fi

ARCHES=("intel" "arm")
VERSION=$1
RELEASE=$2
NAME=jc
DESCRIPTION="This tool serializes the output of popular gnu linux command line tools and file types to structured JSON output"
URL="https://github.com/kellyjonbrazil/${NAME}"
MAINTAINER="kellyjonbrazil@gmail.com"
RAW_URL="https://raw.githubusercontent.com/kellyjonbrazil/${NAME}"

# No longer used since all architectures are now built from a single build machine
# if [[ $(uname -m) == "x86_64" ]]; then
#     ARCH=x86_64
#     ARCHDEB=amd64
# else
#     ARCH=aarch64
#     ARCHDEB=arm64
# fi

if [[ $3 == "intel" ]]; then
    ARCHES=("intel")
fi

if [[ $3 == "arm" ]]; then
    ARCHES=("arm")
fi

mkdir -p dist

echo
echo "Building RPM and DEB packages for the following architectures:"
echo "${ARCHES[@]}"
echo

for archname in "${ARCHES[@]}"; do

    echo
    echo ===========================================================
    echo Building "$archname" environment
    echo ===========================================================
    echo

    if [[ $archname == "intel" ]]; then
        ARCH=x86_64
        ARCHDEB=amd64
    fi

    if [[ $archname == "arm" ]]; then
        ARCH=aarch64
        ARCHDEB=arm64
    fi

    BIN_PATH="${HOME}/dist/${NAME}-${VERSION}-linux-${ARCH}.tar.gz"
    RPM_NAME="${NAME}-${VERSION}-${RELEASE}.${ARCH}.rpm"
    DEB_NAME="${NAME}_${VERSION}-${RELEASE}_${ARCHDEB}.deb"

    rm "dist/${NAME}-${VERSION}-${RELEASE}*"
    rm -rf linux
    mkdir -p linux

    # move binary to build directory
    mkdir -p linux/usr/local/bin
    cp "${BIN_PATH}" linux/usr/local/bin
    tar -xvf "linux/usr/local/bin/${NAME}-${VERSION}-linux-${ARCH}.tar.gz" -C linux/usr/local/bin/
    rm linux/usr/local/bin/*.tar.gz
    chmod 755 "linux/usr/local/bin/${NAME}"

    # download man page for this version (version must be tagged in github)
    mkdir -p linux/usr/share/man/man1
    curl -f -o "linux/usr/share/man/man1/${NAME}.1" "${RAW_URL}/v${VERSION}/man/${NAME}.1" || { echo 'curl man download failed' ; exit 1; }

    # download shell completions for this version (version must be tagged in github)
    mkdir -p linux/etc/bash_completion.d
    curl -f -o "linux/etc/bash_completion.d/${NAME}" "${RAW_URL}/v${VERSION}/completions/${NAME}_bash_completion.sh" || { echo 'curl bash completion download failed' ; exit 1; }

    mkdir -p linux/usr/share/zsh/site-functions
    curl -f -o "linux/usr/share/zsh/site-functions/_${NAME}" "${RAW_URL}/v${VERSION}/completions/${NAME}_zsh_completion.sh" || { echo 'curl zsh completion download failed' ; exit 1; }

    set -eu

    echo
    echo ===========================================================
    echo Building "$archname" RPM
    echo ===========================================================
    echo

    fpm \
        --verbose \
        -t rpm \
        -s dir \
        -C linux/ \
        --prefix / \
        -n "${NAME}" \
        -v "${VERSION}" \
        --iteration "${RELEASE}" \
        -m "${MAINTAINER}" \
        --description "${DESCRIPTION}" \
        --url "${URL}" \
        --license MIT \
        --vendor "${MAINTAINER}" \
        -a "${ARCH}" \
        --rpm-os linux \
        -p "dist/${RPM_NAME}" \
        -n "${NAME}"

    echo
    echo ===========================================================
    echo Building "$archname" DEB
    echo ===========================================================
    echo

    fpm \
        --verbose \
        -t deb \
        -s dir \
        -C linux/ \
        --prefix / \
        -n "${NAME}" \
        -v "${VERSION}" \
        --iteration "${RELEASE}" \
        -m "${MAINTAINER}" \
        --description "${DESCRIPTION}" \
        --url "${URL}" \
        --license MIT \
        --vendor "${MAINTAINER}" \
        -a "${ARCHDEB}" \
        -p "dist/${DEB_NAME}" \
        -n "${NAME}"

    set +eu

    echo
    echo "===== RPM info ($archname):"
    rpm -q -i -p "dist/${RPM_NAME}"
    echo
    echo "===== included files:"
    rpm -q -l -p "dist/${RPM_NAME}"
    shasum -a 256 "dist/${RPM_NAME}" > "dist/${RPM_NAME}.sha256"
    echo

    echo
    echo "===== DEB info ($archname):"
    dpkg --info "dist/${DEB_NAME}"
    echo
    echo "===== included files:"
    dpkg --contents "dist/${DEB_NAME}"
    shasum -a 256 "dist/${DEB_NAME}" > "dist/${DEB_NAME}.sha256"
    echo

done
