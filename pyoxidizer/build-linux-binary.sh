#!/bin/bash

# Linux Build Requirements:
#     Centos 7 with Rust and C compilers
#     GCC v4.9 instead of v4.85:
#         yum install centos-release-scl-rh
#         yum install devtoolset-3-gcc devtoolset-3-gcc-c++
#         update-alternatives --install /usr/bin/gcc-4.9 gcc-4.9 /opt/rh/devtoolset-3/root/usr/bin/gcc 10
#         update-alternatives --install /usr/bin/g++-4.9 g++-4.9 /opt/rh/devtoolset-3/root/usr/bin/g++ 10

# run this first to enable gcc v4.9
# scl enable devtoolset-3 bash

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

VERSION=$1

pyoxidizer build --release

cd build/x86_64-unknown-linux-gnu/release/exe
sha256sum jc > ~/jc-"${VERSION}"-linux.sha256
tar -czvf ~/jc-"${VERSION}"-linux.tar.gz jc
