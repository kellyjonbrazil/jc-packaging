#!/bin/bash

# old:
    # usage:
    # build-rpm.sh

    # if [[ $1 == "" ]]; then
    #     echo "Please enter the version to build."
    #     exit
    # fi

    # VERSION=$1

    # build the SRPM
    # pyp2rpm jc --srpm

    # build the RPM
    # rpmbuild --rebuild ~/rpmbuild/SRPMS/python-jc-"${VERSION}"-1.fc32.src.rpm

# get the source
cd ~/rpmbuild/SOURCES
pip download --no-deps --no-binary :all: jc
cd ~

# build the RPM and SRPM
rpmbuild -bb ~/rpmbuild/SPECS/jc.spec
rpmbuild -bs ~/rpmbuild/SPECS/jc.spec
