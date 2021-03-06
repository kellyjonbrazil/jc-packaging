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
RAW_URL="https://raw.githubusercontent.com/kellyjonbrazil/${NAME}/master"

rm dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.*
rm -rf linux/*

# download binary
mkdir -p linux/usr/local/bin
curl -o linux/usr/local/bin/"${NAME}"-"${VERSION}"-linux-x86_64.tar.gz https://"${NAME}"-packages.s3-us-west-1.amazonaws.com/bin/"${NAME}"-"${VERSION}"-linux-x86_64.tar.gz
tar -xvf linux/usr/local/bin/"${NAME}"-"${VERSION}"-linux-x86_64.tar.gz -C linux/usr/local/bin/
rm linux/usr/local/bin/*.tar.gz
chmod +x linux/usr/local/bin/"${NAME}"

# download latest man page
mkdir -p linux/usr/share/man/man1
curl -o "linux/usr/share/man/man1/${NAME}.1" "${RAW_URL}/master/man/${NAME}.1"

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
    -a x86_64 \
    --rpm-os linux \
    -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm \
    -n "${NAME}"

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
    -a x86_64 \
    -p dist/"${NAME}"_"${VERSION}"-"${RELEASE}"_amd64.deb \
    -n "${NAME}"


echo "RPM info:"
rpm -q -i -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo
echo "included files:"
rpm -q -l -p dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo
shasum -a 256 dist/"${NAME}"-"${VERSION}"-"${RELEASE}".x86_64.rpm
echo

echo "DEB info:"
dpkg --info dist/"${NAME}"_"${VERSION}"-"${RELEASE}"_amd64.deb
echo "included files:"
dpkg --contents dist/"${NAME}"_"${VERSION}"-"${RELEASE}"_amd64.deb
echo
shasum -a 256 dist/"${NAME}"_"${VERSION}"-"${RELEASE}"_amd64.deb
echo
