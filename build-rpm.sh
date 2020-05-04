#!/bin/bash

# usage:
# build-rpm.sh

# if [[ $1 == "" ]]; then
#     echo "Please enter the version to build."
#     exit
# fi

# VERSION=$1

# build the SRPM
pyp2rpm jc --srpm

# build the RPM
# rpmbuild --rebuild ~/rpmbuild/SRPMS/python-jc-"${VERSION}"-1.fc32.src.rpm

# build the RPM
rpmbuild -bb ~/rpmbuild/SPEC/python-jc.spec 
