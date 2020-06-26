#!/bin/bash

# usage:
# build-packages.sh <version>
# 
# e.g.:
# build-packages.sh 1.10.5 1

if [[ $1 == "" ]]; then
    echo "Please enter the version to build."
    exit
fi

if [[ $2 == "" ]]; then
    echo "Please enter the release number."
    exit
fi

VERSION=$1
RELEASE=$2
NAME=jc
DESCRIPTION="This tool serializes the output of popular gnu linux command line tools and file types to structured JSON output"
URL="https://github.com/kellyjonbrazil/jc"
MAINTAINER="kellyjonbrazil@gmail.com"

rm dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.*
rm -rf linux/*
curl -o linux/jc-"${VERSION}"-linux.tar.gz https://jc-packages.s3-us-west-1.amazonaws.com/bin/jc-"${VERSION}"-linux.tar.gz
tar -xvf linux/jc-"${VERSION}"-linux.tar.gz -C linux/
rm linux/*.tar.gz
chmod +x linux/jc

fpm \
    --verbose \
    -t rpm \
    -s dir \
    -C linux \
    --prefix /usr/local/bin \
    -n "${NAME}" \
    -v "${VERSION}" \
    -m "${MAINTAINER}" \
    --description "${DESCRIPTION}" \
    --url "${URL}" \
    --license MIT \
    --vendor "${MAINTAINER}" \
    -a x86_64 \
    --rpm-os linux \
    -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm \
    "${NAME}"

fpm \
    --verbose \
    -t deb \
    -s dir \
    -C linux \
    --prefix /usr/local/bin \
    -n "${NAME}" \
    -v "${VERSION}" \
    -m "${MAINTAINER}" \
    --description "${DESCRIPTION}" \
    --url "${URL}" \
    --license MIT \
    --vendor "${MAINTAINER}" \
    -a x86_64 \
    -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.deb \
    "${NAME}"


echo "RPM info:"
rpm -q -i -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo
echo "included files:"
rpm -q -l -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo
shasum -a 256 dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo

echo "DEB info:"
dpkg --info dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.deb
echo "included files:"
dpkg --contents dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.deb
echo
shasum -a 256 dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.deb
echo