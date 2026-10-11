# Static CPython build

Builds the single-file `jc` binary for Linux and macOS without PyOxidizer.
PyOxidizer is no longer maintained and its last release stops at Python 3.10;
this build links `jc` against a current CPython from
[python-build-standalone](https://github.com/astral-sh/python-build-standalone),
which is the same source of interpreters PyOxidizer used.

The result behaves like the PyOxidizer binary: one executable, every module
loaded from memory, nothing unpacked to disk at startup.

## Building

    static/build-binary.sh <version>

    e.g.  static/build-binary.sh 1.26.0

This writes `jc-<version>-<linux|darwin>-<arch>.tar.gz` and its `.sha256` to
`$HOME/dist`, the names `build-packages.sh` expects. It builds for the machine
it runs on. On an Apple Silicon Mac, run it under Rosetta for the Intel binary.

The build machine needs:

- Linux: `bash`, `curl`, `tar`, `awk`, binutils (`as`, `ld`), the glibc
  development files, and a C compiler driver such as `gcc` installed as `cc`.
  The driver is only used to run the linker; nothing is compiled with it.
- macOS: the Xcode command line tools.

On Linux the first run also builds the *core* (next section), which downloads
about 430 MB and takes a few minutes. After that a build takes a few seconds.
On macOS every build links CPython from scratch and takes a few minutes. The
linker warns there that `-stack_size` is not implemented; that is expected,
and python-build-standalone's own interpreter is linked the same way.
Downloads are unpacked under `~/.cache/jc-static`, up to 2.1 GB.

| Variable | Purpose |
| --- | --- |
| `JC_DIST` | Output folder. Default `$HOME/dist`. |
| `JC_STATIC_CACHE` | Where the downloads are unpacked. Default `$HOME/.cache/jc-static`. |
| `JC_SITE_DIR` | A folder with `jc` and its dependencies already installed (`pip install --target`). Skips the pip step, for offline builds or an unreleased `jc`. |
| `JC_CORE_ARCHIVE` | Linux only. A core archive made by `build-core.sh` on another machine, if it is not in the cache folder. |
| `JC_MAX_GLIBC` | Linux only. The build fails if the binary needs a newer glibc than this. Default `2.28`; `any` disables the check. |

## The core, and old Linux build machines

CPython's object files are LLVM bitcode, so turning them into machine code
needs the pinned clang, and that clang only runs on glibc 2.18 or newer.
CentOS 7, with glibc 2.17, cannot run it.

The Linux build is therefore split in two:

- `build-core.sh` compiles CPython and the launcher into one ordinary object
  file, the core. It depends on the Python pinned in `distributions.txt` but
  not on `jc`, so it is built once per Python update. This is the step that
  needs clang.
- `build-binary.sh` adds `jc` to the core with the machine's own assembler
  and linker. That works on any distribution, and because the binary is
  linked against that machine's glibc, it runs on that glibc and newer.

`build-binary.sh` looks for the core in the cache folder and runs
`build-core.sh` itself if it is missing, so on a machine that can run clang
there is nothing extra to do. On one that cannot, it stops and names the file
it needs. Make that file on a newer machine or container of the same
architecture, from the same checkout:

    static/build-core.sh

and copy the `jc-core-<target>-<id>.tar.gz` it reports into
`~/.cache/jc-static/` on the old machine. A container works, for example:

    docker run --rm -v "$PWD":/work -v "$HOME/.cache/jc-static":/root/.cache/jc-static \
        -w /work ubuntu:24.04 bash -c 'apt-get update &&
        apt-get install -y curl ca-certificates binutils libc6-dev && static/build-core.sh'

The `<id>` in the name changes whenever the pins for that target,
`launcher.c` or `build-core.py` change, so a stale core is never picked up;
the build asks for the new one instead.

## How it works

1. The scripts download the archives pinned in `distributions.txt`, check
   their SHA-256 and unpack them: an interpreter to run the build with, and
   for the core also CPython's object files and the matching clang.
2. `build-core.py` picks the built-in extension modules, compiles
   `launcher.c`, and on Linux pre-links everything into `core.o`.
3. pip installs `jc==<version>` and `requirements.txt` into `build/site`.
4. `build.py` compiles those modules and the standard library to bytecode,
   packs them into one blob with the statement to run, and links the blob
   with the core.
5. At startup `launcher.c` hands the blob to CPython as its frozen-module
   table (`PyImport_FrozenModules`), so imports are served from memory by the
   interpreter's built-in `FrozenImporter`. There is no custom importer.
6. `build-binary.sh` then runs the binary: it must report the requested
   version and parse YAML, XML and CSV, or the build fails.

On one machine, the same inputs give a byte-for-byte identical binary.

As with the PyOxidizer build, modules have no `__file__`, and parser plugins
in the user's `jcparsers` folder are still imported from disk.

Extension modules that need a large third-party library are left out, as the
PyOxidizer `no-libraries` filter did on Linux: `_ssl`, `_hashlib`, `_sqlite3`,
`_bz2`, `_lzma`, `_zstd`, `_uuid` and `_ctypes`. `hashlib` falls back to
CPython's built-in implementations. To include one, add its library to
`ALLOWED_STATIC_LIBS` in `build-core.py`. CPython's test helpers, `curses` and
`readline` are left out as well.

## Minimum glibc (Linux)

The oldest glibc the binary runs on is decided by the machine that runs
`build-binary.sh`, because the linker binds each glibc function to the newest
version that machine offers. The core itself needs nothing newer than glibc
2.17, wherever it was built.

`build-binary.sh` prints the result and fails above `JC_MAX_GLIBC`. To
support older distributions, run it on an older distribution.

## Updating Python

    static/update-pins.sh <release> <python version>

    e.g.  static/update-pins.sh 20261001 3.14.8

`<release>` is a python-build-standalone release tag, which is a date. The
[releases page](https://github.com/astral-sh/python-build-standalone/releases)
lists them with the Python versions each one carries. The script rewrites
`distributions.txt` and needs `curl`, `git` and `python3`. If the release
does not have that version, it says which versions it does have and changes
nothing.

Afterwards rebuild on each machine and check the result (next section)
before committing the new pins. New pins need a new core: machines that can
run clang build it on the next `build-binary.sh`, the others need it copied
over again as described above.

A new minor version of Python can also need a small change to
`build-core.py`, because CPython's build layout shifts between versions. For
3.15 an object file had moved out of the list it reads.

`distributions.txt` pins three downloads per target, and this is where the
script gets them, should a line ever need changing by hand:

- `python` and `objects` are the `install_only_stripped.tar.gz` and
  `pgo+lto-full.tar.zst` archives of one CPython version from one release.
  Their hashes are in the `SHA256SUMS` file attached to that release.
- `llvm` is the toolchain the release was compiled with. Its URL and hash are
  in `pythonbuild/downloads.json` in the python-build-standalone source at
  the release's tag, under the keys `llvm-x86_64-linux`,
  `llvm-aarch64-linux`, `llvm-aarch64-macos` and `llvm-x86_64-macos`. It
  changes far less often than Python does. With the wrong version the link
  step fails with an LLVM bitcode error.

## Checking a build

`compare-binaries.py` runs two binaries over the fixtures in a `jc` checkout
and reports any difference in output or exit code:

    static/compare-binaries.py <reference jc> static/build/jc <jc checkout>

To run `jc`'s own unit tests inside the frozen interpreter, link a variant
that executes its first argument and point it at the tests. `<python>` is the
cache folder named after the hash of the `python` line in
`distributions.txt`, and `<core>` is the `core-<target>-<id>` folder beside
it (on macOS, `static/build/core`):

    <python>/python/bin/python3 static/build.py --core <core> \
        --source static/build/site --run "import sys; exec(sys.argv.pop(1))" \
        --output /tmp/jc-test
    /tmp/jc-test "import unittest; unittest.main(module=None)" \
        discover -s <jc checkout>/tests -t <jc checkout>

## Windows

Not covered. python-build-standalone no longer publishes statically linked
Windows builds, so a Windows binary cannot be a single file this way. The
`pyoxidizer/windows` build is unchanged.
