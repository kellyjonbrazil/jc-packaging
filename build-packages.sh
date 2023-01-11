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
URL="https://github.com/kellyjonbrazil/${NAME}"
MAINTAINER="kellyjonbrazil@gmail.com"
RAW_URL="https://raw.githubusercontent.com/kellyjonbrazil/${NAME}"
BIN_PATH="${HOME}/dist/${NAME}-${VERSION}-linux-x86_64.tar.gz"

rm "dist/${NAME}-${VERSION}-${RELEASE}.x86_64.*"
rm -rf linux/*

# move binary to build directory
mkdir -p linux/usr/local/bin
cp "${BIN_PATH}" linux/usr/local/bin
tar -xvf "linux/usr/local/bin/${NAME}-${VERSION}-linux-x86_64.tar.gz" -C linux/usr/local/bin/
rm linux/usr/local/bin/*.tar.gz
chmod +x "linux/usr/local/bin/${NAME}"

# download man page for this version (version must be tagged in github)
mkdir -p linux/usr/share/man/man1
curl -f -o "linux/usr/share/man/man1/${NAME}.1" "${RAW_URL}/v${VERSION}/man/${NAME}.1" || { echo 'curl man download failed' ; exit 1; }

# download shell completions for this version (version must be tagged in github)
mkdir -p linux/etc/bash_completion.d
curl -f -o "linux/etc/bash_completion.d/${NAME}" "${RAW_URL}/v${VERSION}/completions/${NAME}_bash_completion.sh" || { echo 'curl bash completion download failed' ; exit 1; }

mkdir -p linux/usr/share/zsh/site-functions
curl -f -o "linux/usr/share/zsh/site-functions/_${NAME}" "${RAW_URL}/v${VERSION}/completions/${NAME}_zsh_completion.sh" || { echo 'curl zsh completion download failed' ; exit 1; }

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
