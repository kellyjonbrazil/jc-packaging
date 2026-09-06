#!/bin/bash

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

NAME=jc
VERSION=$1

if [[ $(uname -m) == "x86_64" ]]; then
    # Running under Rosetta on my Apple Silicon Mac
    ARCH=x86_64
    pyox_binary="${HOME}/.local/bin/pyoxidizer"
    SDKROOT=$(xcrun --show-sdk-path) $pyox_binary build --target-triple x86_64-apple-darwin --release

else
    ARCH=aarch64
    pyox_binary="/usr/local/bin/pyoxidizer"
    $pyox_binary build --release
fi

cd "build/${ARCH}-apple-darwin/release/install"
shasum -a 256 "${NAME}" > "${HOME}/dist/${NAME}-${VERSION}-darwin-${ARCH}.sha256"
tar -czvf "${HOME}/dist/${NAME}-${VERSION}-darwin-${ARCH}.tar.gz" "${NAME}"
