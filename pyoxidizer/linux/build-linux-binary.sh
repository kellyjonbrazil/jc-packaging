#!/bin/bash

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

NAME=jc
VERSION=$1

if [[ $(uname -m) == "x86_64" ]]; then
    ARCH=x86_64
else
    ARCH=aarch64
fi

pyoxidizer build --release

cd "build/${ARCH}-unknown-linux-gnu/release/install"
sha256sum "${NAME}" > "${HOME}/dist/${NAME}-${VERSION}-linux-${ARCH}.sha256"
tar -czvf "${HOME}/dist/${NAME}-${VERSION}-linux-${ARCH}.tar.gz" "${NAME}"
