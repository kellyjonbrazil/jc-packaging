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

- Linux: `bash`, `curl`, `tar`, `awk`, binutils (GNU `ld`), the glibc
  development files and zlib. No compiler, Python or Rust is required.
- macOS: the Xcode command line tools.

The first run downloads about 430 MB (CPython, its object files and the
matching clang) and unpacks it to 2.1 GB under `~/.cache/jc-static`. After
that a build takes about two minutes, nearly all of it link-time optimization.

| Variable | Purpose |
| --- | --- |
| `JC_DIST` | Output folder. Default `$HOME/dist`. |
| `JC_STATIC_CACHE` | Where the downloads are unpacked. Default `$HOME/.cache/jc-static`. |
| `JC_SITE_DIR` | A folder with `jc` and its dependencies already installed (`pip install --target`). Skips the pip step, for offline builds or an unreleased `jc`. |
| `JC_MAX_GLIBC` | Linux only. The build fails if the binary needs a newer glibc than this. Default `2.28`; `any` disables the check. |

## How it works

1. `build-binary.sh` downloads the three archives pinned in
   `distributions.txt`, checks their SHA-256 and unpacks them.
2. pip installs `jc==<version>` and `requirements.txt` into `build/site`.
3. `build.py` compiles those modules and the standard library to bytecode and
   packs them into one blob, then links `launcher.c` with CPython's object
   files using the interpreter's own link flags.
4. At startup `launcher.c` hands the blob to CPython as its frozen-module
   table (`PyImport_FrozenModules`), so imports are served from memory by the
   interpreter's built-in `FrozenImporter`. There is no custom importer.
5. `build-binary.sh` then runs the binary: it must report the requested
   version and parse YAML, XML and CSV, or the build fails.

As with the PyOxidizer build, modules have no `__file__`, and parser plugins
in the user's `jcparsers` folder are still imported from disk.

Extension modules that need a large third-party library are left out, as the
PyOxidizer `no-libraries` filter did on Linux: `_ssl`, `_hashlib`, `_sqlite3`,
`_bz2`, `_lzma`, `_zstd`, `_uuid` and `_ctypes`. `hashlib` falls back to
CPython's built-in implementations. To include one, add its library to
`ALLOWED_STATIC_LIBS` in `build.py`. CPython's test helpers, `curses` and
`readline` are left out as well.

## Minimum glibc (Linux)

The oldest glibc the binary runs on is decided by the machine it is linked
on, because the linker binds each glibc function to the newest version that
machine offers. CPython's object files themselves need nothing newer than
glibc 2.17.

`build-binary.sh` prints the result and fails above `JC_MAX_GLIBC`. To
support older distributions, build on an older distribution or in a container
of one. The clang toolchain's bundled C++ runtime needs glibc 2.18, so the
build machine cannot be older than that.

## Updating Python

Edit `distributions.txt`. For each of the four targets it pins three
downloads that must go together:

- `python` and `objects` are the `install_only_stripped` and `pgo+lto-full`
  archives of one CPython version from one python-build-standalone release.
  Their hashes are in that release's `SHA256SUMS` file.
- `llvm` is the toolchain that release was built with. Its URL and hash are
  in `pythonbuild/downloads.json` at the release's tag, and its version is
  the `object_file_format` recorded in the archive's `PYTHON.json`. With the
  wrong version the link step fails with an LLVM bitcode error.

## Checking a build

`compare-binaries.py` runs two binaries over the fixtures in a `jc` checkout
and reports any difference in output or exit code:

    static/compare-binaries.py <reference jc> static/build/jc <jc checkout>

To run `jc`'s own unit tests inside the frozen interpreter, link a variant
that executes its first argument and point it at the tests. `<python>`,
`<objects>` and `<llvm>` are the folders in the cache, named after the hashes
in `distributions.txt`:

    <python>/python/bin/python3 static/build.py \
        --objects <objects>/python --clang <llvm>/llvm/bin/clang \
        --source static/build/site --run "import sys; exec(sys.argv.pop(1))" \
        --output /tmp/jc-test
    /tmp/jc-test "import unittest; unittest.main(module=None)" \
        discover -s <jc checkout>/tests -t <jc checkout>

## Windows

Not covered. python-build-standalone no longer publishes statically linked
Windows builds, so a Windows binary cannot be a single file this way. The
`pyoxidizer/windows` build is unchanged.
