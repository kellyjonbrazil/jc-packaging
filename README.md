# JC Packages and Binaries

Find the latest `jc` packages at [Github Releases](https://github.com/kellyjonbrazil/jc/releases)

## Package build instructions

### Binaries
Linux and macOS: run `static/build-binary.sh <version>`. It links `jc` against
a current CPython and does not need PyOxidizer; see `static/README.md`.

The `pyoxidizer` folder holds the earlier PyOxidizer builds, which are limited
to Python 3.10, and the Windows build, which the static build does not cover.
Use the build script or instructions there.

### RPM and DEB packages
Use the `build-via-container.sh` script. The binary must exist in `$HOME/dist`.

    ./build-via-container.sh <version> <release>

The binaries are read from `$HOME/dist` and the packages are written to `dist/`.
