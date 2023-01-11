#!/bin/bash

# OSX Build Requirements:
#     Mojave

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

NAME=jc
VERSION=$1

# export MACOSX_DEPLOYMENT_TARGET=10.11
pyoxidizer build --release

cd build/x86_64-apple-darwin/release/install
shasum -a 256 "${NAME}" > ~/"${NAME}"-"${VERSION}"-darwin-x86_64.sha256
tar -czvf ~/"${NAME}"-"${VERSION}"-darwin-x86_64.tar.gz "${NAME}"
