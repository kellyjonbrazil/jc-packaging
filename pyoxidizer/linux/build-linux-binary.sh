#!/bin/bash

# Linux Build Requirements:
#     CentOS 7

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

NAME=jc
VERSION=$1

pyoxidizer build --release

cd build/x86_64-unknown-linux-gnu/release/install
sha256sum "${NAME}" > ~/"${NAME}"-"${VERSION}"-linux-x86_64.sha256
tar -czvf ~/"${NAME}"-"${VERSION}"-linux-x86_64.tar.gz "${NAME}"
