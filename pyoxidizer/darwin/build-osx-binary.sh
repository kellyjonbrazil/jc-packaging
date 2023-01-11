#!/bin/bash

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

NAME=jc
VERSION=$1

pyoxidizer build --release

cd build/x86_64-apple-darwin/release/install
shasum -a 256 "${NAME}" > "${HOME}/dist/${NAME}-${VERSION}-darwin-x86_64.sha256"
tar -czvf "${HOME}/dist/${NAME}-${VERSION}-darwin-x86_64.tar.gz" "${NAME}"
