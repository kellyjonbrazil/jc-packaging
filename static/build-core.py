#!/usr/bin/env python3
"""Compile the part of the binary that depends only on the Python version.

Normally run by build-core.sh (Linux) or build-binary.sh (macOS):

    python3.14 build-core.py --objects <unpacked "full" archive>/python \\
        --clang <llvm>/bin/clang --output <core folder>

It reads PYTHON.json, which lists every object file and static library the
interpreter was built from, picks the built-in extension modules to keep,
writes a matching built-in module table (config.c) and compiles it together
with launcher.c.

On Linux everything is then pre-linked into one ordinary object file,
core.o. CPython's object files are LLVM bitcode, so this is the step that
needs clang, and clang needs a newer glibc than the oldest machines jc is
built on. core.o is plain machine code that any linker accepts, which lets
build.py finish the job with the system linker, against the system's glibc.

On macOS there is no such constraint, so nothing is pre-linked: build.py
links the bitcode objects directly.

Either way the folder gets a core.json that tells build.py how to link.
"""
import argparse
import json
import platform
import re
import shlex
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

# An extension module is built in only if every static library it needs is
# listed here; system libraries and macOS frameworks are always acceptable.
# This keeps OpenSSL, SQLite, Tcl/Tk and friends out of the binary.
ALLOWED_STATIC_LIBS = {'z', 'expat', 'mpdec'}

# Built-in extension modules that have no place in a command-line filter:
# CPython's own test helpers and the terminal UI modules.
EXCLUDED_EXTENSIONS = re.compile(
    r'^(_test.*|_xxtestfuzz|xxsubtype|xxlimited.*|_ctypes_test|_curses.*|readline)$')

# Standard library packages that are useless without their extension module.
STDLIB_NEEDS_EXTENSION = {'sqlite3': '_sqlite3', 'curses': '_curses', 'ctypes': '_ctypes'}

# Sections only LLVM's own tools understand; dropped so that old linkers
# are not handed something they have never heard of.
LLVM_ONLY_SECTIONS = ('.llvm_addrsig', '.llvm.call-graph-profile')

# C library functions launcher.c and config.c may call. All of them have
# been in glibc since 2.2.5.
LAUNCHER_LIBC_SYMBOLS = {
    'calloc', 'fwrite', 'fputs', 'fputc', 'stderr', 'memcmp', 'bcmp', 'memcpy', 'memset',
    'strlen', '__stack_chk_fail',
}


def select_extensions(info):
    """Return {name: metadata} for the built-in extension modules to link."""
    selected = {}
    for name, candidates in info['build_info']['extensions'].items():
        ext = candidates[0]
        if ext.get('required'):
            selected[name] = ext
            continue
        if ext.get('shared_lib') or EXCLUDED_EXTENSIONS.match(name):
            continue
        static_libs = {link['name'] for link in ext.get('links', [])
                       if not link.get('system') and not link.get('framework')}
        if static_libs <= ALLOWED_STATIC_LIBS:
            selected[name] = ext
    return selected


def write_config_c(info, objects, selected, out):
    """Copy the distribution's built-in module table, minus dropped modules."""
    all_names = set(info['build_info']['extensions'])
    source = (objects / info['build_info']['inittab_source']).read_text()
    dropped_inits = set()
    lines = []
    for line in source.splitlines():
        m = re.match(r'\s*\{"([^"]+)",\s*(\w+)\},', line)
        if m and m.group(1) in all_names and m.group(1) not in selected:
            dropped_inits.add(m.group(2))
            continue
        lines.append(line)
    kept = []
    for line in lines:
        m = re.match(r'extern PyObject\* (\w+)\(void\);', line)
        if m and m.group(1) in dropped_inits:
            continue
        kept.append(line)
    out.write_text('\n'.join(kept) + '\n')


def check_libc_use(clang, objs):
    """Stop if the code compiled here calls anything old glibc might lack.

    launcher.c and config.c are the only parts of the core compiled against
    this machine's C library headers, and newer headers can redirect a call
    to a function that older glibc versions do not have. Everything else was
    compiled by python-build-standalone against an old glibc.
    """
    undefined = set()
    for obj in objs:
        undefined.update(run([clang.with_name('llvm-nm'), '--undefined-only',
                              '--just-symbol-name', obj], capture=True).split())
    unexpected = sorted(name for name in undefined
                        if not name.startswith(('Py', '_Py', 'app_payload'))
                        and name not in LAUNCHER_LIBC_SYMBOLS)
    if unexpected:
        sys.exit('launcher.o/config.o reference C library symbols that are not known to '
                 f'exist in old glibc versions: {" ".join(unexpected)}\n'
                 'Check them and add them to LAUNCHER_LIBC_SYMBOLS if they do.')


def run(cmd, capture=False):
    result = subprocess.run([str(c) for c in cmd], stdout=subprocess.PIPE if capture else None,
                            universal_newlines=True)
    if result.returncode:
        sys.exit(f'{Path(str(cmd[0])).name} failed with exit code {result.returncode}')
    return result.stdout


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--objects', required=True, type=Path,
                   help='unpacked python-build-standalone "full" archive (folder with PYTHON.json)')
    p.add_argument('--clang', required=True, type=Path,
                   help="clang from the LLVM release the archive's object files were built with")
    p.add_argument('--output', required=True, type=Path, help='folder to write the core to')
    args = p.parse_args()

    objects = args.objects.resolve()
    clang = args.clang.resolve()
    info = json.loads((objects / 'PYTHON.json').read_text())
    running = platform.python_version()  # includes any pre-release tag, e.g. 3.15.0rc2
    if info['python_version'] != running:
        sys.exit(f"the objects are CPython {info['python_version']} but this is CPython "
                 f"{running}; run build-core.py with the matching interpreter")
    build_info = info['build_info']
    config_vars = info['python_config_vars']
    macos = 'apple-darwin' in info['target_triple']
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)

    # 1. extension modules and the built-in module table
    selected = select_extensions(info)
    left_out = sorted(name for name, c in build_info['extensions'].items()
                      if name not in selected and not c[0].get('shared_lib')
                      and not EXCLUDED_EXTENSIONS.match(name))
    print(f'extension modules: {len(selected)} built in; left out: {" ".join(left_out)}')
    write_config_c(info, objects, selected, out / 'config.c')

    # 2. compile the launcher and the module table
    target_flags = []
    if macos:
        arch = 'arm64' if info['target_triple'].startswith('aarch64') else 'x86_64'
        target_flags = ['-arch', arch,
                        f"-mmacosx-version-min={info['apple_sdk_deployment_target']}"]
    include = objects / info['python_paths']['include']
    run([clang, '-c', '-O2', '-fPIC', *target_flags, f'-I{include}',
         HERE / 'launcher.c', '-o', out / 'launcher.o'])
    run([clang, '-c', '-O2', '-fPIC', *build_info['inittab_cflags'], *target_flags,
         f'-I{include}', out / 'config.c', '-o', out / 'config.o'])

    # 3. everything CPython itself consists of
    # The distribution's own built-in table is replaced by the one from step 1.
    stock_inittab = build_info['inittab_object']
    objs = [objects / o for o in build_info['core']['objs'] if o != stock_inittab]
    links = list(build_info['core']['links'])
    for name in sorted(selected):
        ext = selected[name]
        if not ext['in_core']:
            objs += [objects / o for o in ext['objs']]
        links += ext.get('links', [])
    objs = list(dict.fromkeys(objs))
    # The object list can miss a file (CPython 3.15's JIT shim is only in the
    # static library). Offering that library last is safe: being an archive,
    # it contributes only members that resolve a still-undefined symbol.
    static_lib = build_info['core'].get('static_lib')
    if static_lib:
        objs.append(objects / static_lib)

    static_libs, system_libs = [], []
    for link in links + [{'name': 'm', 'system': True}]:
        if link.get('framework'):
            arg, group = ('-framework', link['name']), system_libs
        elif link.get('system'):
            arg, group = (f"-l{link['name']}",), system_libs
        else:
            arg, group = (str(objects / link['path_static']),), static_libs
        if arg not in group:
            group.append(arg)
    static_libs = [a for arg in static_libs for a in arg]
    system_libs = [a for arg in system_libs for a in arg]

    # The flags the interpreter itself was linked with.
    ldflags = shlex.split(config_vars.get('LDFLAGS') or '')
    ldflags += shlex.split(config_vars.get('LINKFORSHARED') or '')

    core = {
        'python_version': info['python_version'],
        'target_triple': info['target_triple'],
        'excluded_stdlib': sorted(pkg for pkg, ext in STDLIB_NEEDS_EXTENSION.items()
                                  if ext not in selected),
    }
    if macos:
        core.update(
            cc=str(clang),
            assemble=[str(clang), '-c', *target_flags],
            flags=['-flto=full', *ldflags, '-Wl,-export_dynamic'],
            inputs=['launcher.o', 'config.o', *map(str, objs)],
            libs=[*static_libs, *system_libs],
            # Stripping would invalidate the linker's ad-hoc code signature.
            strip=False,
        )
    else:
        # 4. pre-link into one native object file (see the module docstring).
        # libgcc goes in too, so the result does not depend on how old the
        # compiler runtime of the machine doing the final link is.
        check_libc_use(clang, [out / 'launcher.o', out / 'config.o'])
        libgcc = run([clang, '-print-libgcc-file-name'], capture=True).strip()
        rsp = out / 'objects.rsp'
        rsp.write_text('\n'.join(f'"{o}"' for o in objs) + '\n')
        print(f'pre-linking {len(objs) + 2} object files '
              '(link-time optimization, takes a few minutes)')
        run([clang, '-flto=full', '-r', '-nostdlib', out / 'launcher.o', out / 'config.o',
             f'@{rsp}', *static_libs, libgcc, '-o', out / 'core.unstripped.o'])
        run([clang.with_name('llvm-objcopy'), '--strip-debug',
             *(f'--remove-section={name}' for name in LLVM_ONLY_SECTIONS),
             out / 'core.unstripped.o', out / 'core.o'])
        for leftover in ('core.unstripped.o', 'launcher.o', 'config.o', 'objects.rsp'):
            (out / leftover).unlink()
        core.update(
            cc=None,        # build.py uses the system's C compiler driver
            assemble=None,  # ... and the system assembler
            flags=['-pthread', '-pie', *ldflags],
            inputs=['core.o'],
            libs=system_libs,
            strip=True,
        )
        print(f"core.o: {(out / 'core.o').stat().st_size / 1e6:.1f} MB")

    (out / 'core.json').write_text(json.dumps(core, indent=1) + '\n')


if __name__ == '__main__':
    main()
