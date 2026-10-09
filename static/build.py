#!/usr/bin/env python3
"""Link a single-file executable from a python-build-standalone distribution.

Normally run by build-binary.sh. Run it with the same CPython version as the
distribution being linked, because the marshalled code it embeds is only
valid for that version:

    python3.14 build.py --objects <unpacked "full" archive>/python \\
        --clang <llvm>/bin/clang --source <app + dependencies> \\
        --run "import jc.cli; jc.cli.main()" --output build/jc

What it does, in order:

  1. reads PYTHON.json, which lists every object file and static library
     the interpreter was built from;
  2. picks the built-in extension modules to keep and writes a matching
     built-in module table (config.c);
  3. compiles every pure-Python module (the --source folders, then the
     standard library) to marshalled code and concatenates it into
     payload.bin, with an index (frozen_index.h);
  4. compiles launcher.c, which embeds payload.bin, and links everything
     with the interpreter's own link flags.
"""
import argparse
import json
import marshal
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

import _imp

HERE = Path(__file__).resolve().parent

# An extension module is built in only if every static library it needs is
# listed here; system libraries and macOS frameworks are always acceptable.
# This keeps OpenSSL, SQLite, Tcl/Tk and friends out of the binary.
ALLOWED_STATIC_LIBS = {'z', 'expat', 'mpdec'}

# Built-in extension modules that have no place in a command-line filter:
# CPython's own test helpers and the terminal UI modules.
EXCLUDED_EXTENSIONS = re.compile(
    r'^(_test.*|_xxtestfuzz|xxsubtype|xxlimited.*|_ctypes_test|_curses.*|readline)$')

# Top-level standard library names left out of the payload.
EXCLUDED_STDLIB = {
    'test', 'idlelib', 'tkinter', 'turtledemo', 'turtle', 'ensurepip', 'venv',
    'site-packages', 'lib-dynload', '__phello__',
}
# Standard library packages that are useless without their extension module.
STDLIB_NEEDS_EXTENSION = {'sqlite3': '_sqlite3', 'curses': '_curses', 'ctypes': '_ctypes'}
STDLIB_TEST_DIRS = {'tests', 'test', 'idle_test'}

COMPILED_SUFFIXES = ('.so', '.pyd', '.dylib')


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


def iter_modules(root, excluded_top=(), excluded_dirs=()):
    """Yield (module name, is_package, path) for the .py files under root."""
    for dirpath, dirnames, filenames in os.walk(root):
        parts = Path(dirpath).relative_to(root).parts
        skip = set(excluded_dirs) | {'__pycache__'} | (set() if parts else set(excluded_top))
        dirnames[:] = sorted(d for d in dirnames if d.isidentifier() and d not in skip)
        for f in sorted(filenames):
            stem, suffix = os.path.splitext(f)
            # Module names need not be identifiers, e.g.
            # _sysconfigdata__linux_x86_64-linux-gnu, but cannot contain dots.
            if suffix != '.py' or '.' in stem or (not parts and stem in excluded_top):
                continue
            if stem == '__init__':
                if parts:
                    yield '.'.join(parts), True, Path(dirpath) / f
            else:
                yield '.'.join(parts + (stem,)), False, Path(dirpath) / f


def find_compiled(root):
    """Return the compiled extension files under an application source root."""
    return sorted(str(p.relative_to(root)) for p in Path(root).rglob('*')
                  if p.name.endswith(COMPILED_SUFFIXES))


def build_payload(roots, work):
    """Compile every module, write payload.bin and return the index entries."""
    entries = {}
    already_frozen = 0
    for root, excluded_top, excluded_dirs in roots:
        for name, is_pkg, path in iter_modules(root, excluded_top, excluded_dirs):
            if name in entries:
                continue  # earlier roots win
            if _imp.is_frozen(name):
                already_frozen += 1  # already compiled into the interpreter
                continue
            filename = str(path.relative_to(root))
            try:
                code = compile(path.read_bytes(), filename, 'exec',
                               dont_inherit=True, optimize=1)
            except (SyntaxError, ValueError) as e:
                sys.exit(f'cannot compile {path}: {e}')
            entries[name] = (is_pkg, marshal.dumps(code))

    # A folder that holds only sub-packages (the "ruamel" namespace package)
    # has no entry yet, and a frozen module needs every parent to exist.
    empty = marshal.dumps(compile('', '<namespace package>', 'exec', optimize=1))
    for name in list(entries):
        parent = name.rpartition('.')[0]
        while parent and parent not in entries and not _imp.is_frozen(parent):
            entries[parent] = (True, empty)
            parent = parent.rpartition('.')[0]

    index = []
    offset = 0
    with open(work / 'payload.bin', 'wb') as f:
        for name in sorted(entries):
            is_pkg, data = entries[name]
            f.write(data)
            index.append((name, offset, len(data), is_pkg))
            offset += len(data)
    print(f'python modules: {len(index)} embedded, {offset / 1e6:.1f} MB '
          f'(plus {already_frozen} the interpreter already carries)')
    return index


def write_index_h(index, run_command, out):
    escaped = run_command.replace('\\', '\\\\').replace('"', '\\"')
    lines = [
        f'#define RUN_COMMAND L"{escaped}"',
        f'#define APP_ENTRY_COUNT {len(index)}',
        'static const struct {',
        '    const char *name; unsigned int offset; unsigned int size; int is_package;',
        '} app_index[] = {',
    ]
    lines += [f'    {{"{n}", {off}u, {size}u, {int(pkg)}}},' for n, off, size, pkg in index]
    lines.append('};')
    out.write_text('\n'.join(lines) + '\n')


def run(cmd):
    result = subprocess.run([str(c) for c in cmd])
    if result.returncode:
        sys.exit(f'{Path(str(cmd[0])).name} failed with exit code {result.returncode}')


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--objects', required=True, type=Path,
                   help='unpacked python-build-standalone "full" archive (folder with PYTHON.json)')
    p.add_argument('--clang', required=True, type=Path,
                   help="clang from the LLVM release the archive's object files were built with")
    p.add_argument('--source', action='append', default=[], type=Path,
                   help='folder of application and dependency modules (repeatable)')
    p.add_argument('--run', required=True, help='Python statement executed at startup')
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--work', type=Path, help='scratch folder (default: <output>.build)')
    args = p.parse_args()

    objects = args.objects.resolve()
    info = json.loads((objects / 'PYTHON.json').read_text())
    running = platform.python_version()  # includes any pre-release tag, e.g. 3.15.0rc2
    if info['python_version'] != running:
        sys.exit(f"the objects are CPython {info['python_version']} but this is CPython "
                 f"{running}; run build.py with the matching interpreter")
    build_info = info['build_info']
    config_vars = info['python_config_vars']
    macos = 'apple-darwin' in info['target_triple']
    work = (args.work or args.output.with_name(args.output.name + '.build')).resolve()
    work.mkdir(parents=True, exist_ok=True)

    # 1. extension modules and the built-in module table
    selected = select_extensions(info)
    left_out = sorted(name for name, c in build_info['extensions'].items()
                      if name not in selected and not c[0].get('shared_lib')
                      and not EXCLUDED_EXTENSIONS.match(name))
    print(f'extension modules: {len(selected)} built in; left out: {" ".join(left_out)}')
    write_config_c(info, objects, selected, work / 'config.c')

    # 2. python modules
    stdlib = objects / info['python_paths']['stdlib']
    excluded = set(EXCLUDED_STDLIB)
    excluded |= {pkg for pkg, ext in STDLIB_NEEDS_EXTENSION.items() if ext not in selected}
    excluded |= {d.name for d in stdlib.iterdir() if d.name.startswith('config-')}
    roots = [(src.resolve(), (), ()) for src in args.source]
    roots.append((stdlib, excluded, STDLIB_TEST_DIRS))
    for src in args.source:
        compiled = find_compiled(src)
        if compiled:
            print(f'note: {len(compiled)} compiled extension file(s) in {src} cannot be '
                  f'embedded and are ignored: {" ".join(compiled)}')
    index = build_payload(roots, work)
    write_index_h(index, args.run, work / 'frozen_index.h')

    # 3. compile
    target_flags = []
    if macos:
        arch = 'arm64' if info['target_triple'].startswith('aarch64') else 'x86_64'
        target_flags = ['-arch', arch,
                        f"-mmacosx-version-min={info['apple_sdk_deployment_target']}"]
    include = objects / info['python_paths']['include']
    run([args.clang, '-c', '-O2', '-fPIC', '-std=c23', *target_flags, f'-I{include}',
         f'-I{work}', f'--embed-dir={work}', HERE / 'launcher.c', '-o', work / 'launcher.o'])
    run([args.clang, '-c', '-O2', '-fPIC', *build_info['inittab_cflags'], *target_flags,
         f'-I{include}', work / 'config.c', '-o', work / 'config.o'])

    # 4. link, with the flags the interpreter itself was linked with
    # The distribution's own built-in table is replaced by the one from step 1.
    stock_inittab = build_info['inittab_object']
    objs = [objects / o for o in build_info['core']['objs'] if o != stock_inittab]
    links = list(build_info['core']['links'])
    for name in sorted(selected):
        ext = selected[name]
        if not ext['in_core']:
            objs += [objects / o for o in ext['objs']]
        links += ext.get('links', [])
    libs = []
    for link in links:
        if link.get('framework'):
            arg = ('-framework', link['name'])
        elif link.get('system'):
            arg = (f"-l{link['name']}",)
        else:
            arg = (str(objects / link['path_static']),)
        if arg not in libs:
            libs.append(arg)
    libs = [a for arg in libs for a in arg]
    objs = list(dict.fromkeys(objs))
    # The object list can miss a file (CPython 3.15's JIT shim is only in the
    # static library). Offering that library last is safe: being an archive,
    # it contributes only members that resolve a still-undefined symbol.
    static_lib = build_info['core'].get('static_lib')
    fallback = [objects / static_lib] if static_lib else []

    ldflags = shlex.split(config_vars.get('LDFLAGS') or '')
    ldflags += shlex.split(config_vars.get('LINKFORSHARED') or '')
    if macos:
        ldflags.append('-Wl,-export_dynamic')
    rsp = work / 'objects.rsp'
    rsp.write_text('\n'.join(f'"{o}"' for o in objs) + '\n')
    linked = work / (args.output.name + '.linked')
    print(f'linking {len(objs) + 2} object files (link-time optimization, takes a few minutes)')
    run([args.clang, '-pthread', '-flto=full', *ldflags,
         work / 'launcher.o', work / 'config.o', f'@{rsp}', *fallback, *libs, '-lm',
         '-o', linked])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    if macos:
        # Stripping would invalidate the linker's ad-hoc code signature.
        shutil.copy2(linked, args.output)
    else:
        run([args.clang.with_name('llvm-strip'), '-o', args.output, linked])
    print(f'{args.output}: {args.output.stat().st_size / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
