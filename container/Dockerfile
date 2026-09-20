FROM docker.io/library/fedora:latest

# fpm builds the RPM with rpmbuild and the DEB in pure Ruby. build-packages.sh
# also uses rpm and dpkg to print package info, and shasum for the checksums.
RUN dnf -y install --setopt=install_weak_deps=False \
        ruby rubygems rubygem-json rpm-build rpm dpkg curl tar findutils perl-Digest-SHA \
 && dnf clean all

# Leave FPM_VERSION empty for the latest fpm, or pin it with
# `--build-arg FPM_VERSION=1.15.1`.
ARG FPM_VERSION=
RUN gem install --no-document fpm ${FPM_VERSION:+-v "${FPM_VERSION}"} \
 && fpm --version

WORKDIR /work
