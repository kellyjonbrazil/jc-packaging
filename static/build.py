#!/usr/bin/env python3
"""Freeze an application and link the single-file executable.

Normally run by build-binary.sh. Run it with the same CPython version as the
core it links against, because the marshalled code it embeds is only valid
for that version:

    python3.14 build.py --core <core folder> --source <app + dependencies> \\
        --run "import jc.cli; jc.cli.main()" --output build/jc

What it does, in order:

  1. compiles every pure-Python module (the --source folders, then this
     interpreter's own standard library) to marshalled code and writes it,
     with an index and the statement to run, to payload.bin;
  2. turns payload.bin into an object file with the assembler;
  3. links it with the core that build-core.py prepared, as core.json in
     that folder says to.

Steps 2 and 3 need only an assembler and a C compiler driver to link with,
whatever the system has, which is what lets this run on old distributions.
"""
import argparse
import json
import marshal
import os
import platform
import shutil
import struct
import subprocess
import sys
import sysconfig
from pathlib import Path

import _imp

# Top-level standard library names left out of the payload.
EXCLUDED_STDLIB = {
    'test', 'idlelib', 'tkinter', 'turtledemo', 'turtle', 'ensurepip', 'venv',
    'site-packages', 'lib-dynload', '__phello__',
}
STDLIB_TEST_DIRS = {'tests', 'test', 'idle_test'}

COMPILED_SUFFIXES = ('.so', '.pyd', '.dylib')

# payload.bin layout, read by launcher.c. Keep the two in step.
PAYLOAD_MAGIC = b'JCFROZEN'
PAYLOAD_VERSION = 1
HEADER = struct.Struct('<8sIIII')  # magic, version, entry count, run command, reserved
ENTRY = struct.Struct('<IIII')     # name, code, size, is_package


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


def compile_modules(roots):
    """Return {module name: (is_package, marshalled code)} for every module."""
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

    size = sum(len(data) for _, data in entries.values())
    print(f'python modules: {len(entries)} embedded, {size / 1e6:.1f} MB '
          f'(plus {already_frozen} the interpreter already carries)')
    return entries


def write_payload(entries, run_command, out):
    """Write payload.bin: header, index, names, run command, then the code."""
    names = sorted(entries)
    name_blob = b''.join(name.encode('ascii') + b'\0' for name in names)
    run_blob = run_command.encode('utf-8') + b'\0'
    names_start = HEADER.size + ENTRY.size * len(names)
    run_start = names_start + len(name_blob)
    code_start = (run_start + len(run_blob) + 15) & ~15

    index = []
    name_offset, code_offset = names_start, code_start
    for name in names:
        is_pkg, data = entries[name]
        index.append(ENTRY.pack(name_offset, code_offset, len(data), int(is_pkg)))
        name_offset += len(name) + 1
        code_offset += len(data)

    with open(out, 'wb') as f:
        f.write(HEADER.pack(PAYLOAD_MAGIC, PAYLOAD_VERSION, len(names), run_start, 0))
        f.write(b''.join(index))
        f.write(name_blob)
        f.write(run_blob)
        f.write(b'\0' * (code_start - f.tell()))
        for name in names:
            f.write(entries[name][1])


def write_payload_asm(macos, out):
    """Write the assembler file that places payload.bin in the executable."""
    if macos:
        lines = ['.section __TEXT,__const', '.globl _app_payload', '.globl _app_payload_end',
                 '.p2align 4', '_app_payload:', '.incbin "payload.bin"', '_app_payload_end:']
    else:
        lines = ['.section .rodata.app_payload,"a",%progbits', '.globl app_payload',
                 '.globl app_payload_end', '.balign 16', 'app_payload:',
                 '.incbin "payload.bin"', 'app_payload_end:',
                 '.section .note.GNU-stack,"",%progbits']
    out.write_text('\n'.join(lines) + '\n')


def run(cmd, cwd=None):
    try:
        result = subprocess.run([str(c) for c in cmd], cwd=cwd)
    except FileNotFoundError:
        sys.exit(f'{cmd[0]} not found; it is needed to build the binary')
    if result.returncode:
        sys.exit(f'{Path(str(cmd[0])).name} failed with exit code {result.returncode}')


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--core', required=True, type=Path,
                   help='folder written by build-core.py (holds core.json)')
    p.add_argument('--source', action='append', default=[], type=Path,
                   help='folder of application and dependency modules (repeatable)')
    p.add_argument('--run', required=True, help='Python statement executed at startup')
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--work', type=Path, help='scratch folder (default: <output>.build)')
    p.add_argument('--cc', help='C compiler driver to link with, where the core does not '
                                'name one (default: cc)')
    args = p.parse_args()

    core_dir = args.core.resolve()
    core = json.loads((core_dir / 'core.json').read_text())
    running = platform.python_version()  # includes any pre-release tag, e.g. 3.15.0rc2
    if core['python_version'] != running:
        sys.exit(f"the core is CPython {core['python_version']} but this is CPython "
                 f"{running}; run build.py with the matching interpreter")
    macos = 'apple-darwin' in core['target_triple']
    work = (args.work or args.output.with_name(args.output.name + '.build')).resolve()
    work.mkdir(parents=True, exist_ok=True)

    # 1. python modules
    stdlib = Path(sysconfig.get_paths()['stdlib'])
    excluded = EXCLUDED_STDLIB | set(core['excluded_stdlib'])
    excluded |= {d.name for d in stdlib.iterdir() if d.name.startswith('config-')}
    roots = [(src.resolve(), (), ()) for src in args.source]
    roots.append((stdlib, excluded, STDLIB_TEST_DIRS))
    for src in args.source:
        compiled = find_compiled(src)
        if compiled:
            print(f'note: {len(compiled)} compiled extension file(s) in {src} cannot be '
                  f'embedded and are ignored: {" ".join(compiled)}')
    write_payload(compile_modules(roots), args.run, work / 'payload.bin')

    # 2. payload.bin as an object file
    write_payload_asm(macos, work / 'payload.s')
    assemble = core['assemble'] or ['as']
    run([*assemble, '-o', 'payload.o', 'payload.s'], cwd=work)  # cwd: .incbin is relative

    # 3. link
    def in_core(arg):
        return str(core_dir / arg) if (core_dir / arg).is_file() else arg
    cc = core['cc'] or args.cc or 'cc'
    linked = work / (args.output.name + '.linked')
    run([cc, *core['flags'], *map(in_core, core['inputs']), work / 'payload.o',
         *core['libs'], '-o', linked])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    if core['strip']:
        run(['strip', '-o', args.output, linked])
    else:
        shutil.copy2(linked, args.output)
    print(f'{args.output}: {args.output.stat().st_size / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
