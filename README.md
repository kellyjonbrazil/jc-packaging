# JC Packages and Binaries

Find the latest `jc` packages at [Github Releases](https://github.com/kellyjonbrazil/jc/releases)

## Package build instructions

### Binaries
Use the build script or instructions under the `pyoxidizer` folder.

### RPM and DEB packages
Use the `build-packages.sh` script. The binary must exist in `$HOME/dist`.

To build the packages in a Linux container instead, so that `fpm`, `rpmbuild`,
and `dpkg` do not need to be installed on the host, run the same script through
`container/run.sh`:

    container/run.sh <version> <release> [intel|arm]

This needs podman or docker (set `CONTAINER_ENGINE=docker`). The binaries are
read from `$HOME/dist` (override with `JC_DIST`) and the packages are written
to `dist/`.
