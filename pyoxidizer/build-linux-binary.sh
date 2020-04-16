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

pyoxidizer build --release
