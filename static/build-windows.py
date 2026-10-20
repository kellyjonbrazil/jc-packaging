#!/usr/bin/env python3
"""Build jc for Windows: jc.exe, its zip archive, and the WiX source of its MSI.

Normally run by build-windows.sh, on Linux or macOS, with the CPython from
distributions.txt for that machine, which must be the same version as the
Windows CPython it builds against:

    python3.14 build-windows.py --version 1.26.2 --python <Windows CPython> \\
        --mingw <llvm-mingw> --site <jc + dependencies for Windows> \\
        --build build/x86_64-pc-windows-msvc --dist ~/dist

python-build-standalone has no statically linked Windows CPython, so the
result cannot be one file. It is as close as Windows allows: jc.exe carries
jc, its dependencies and the whole standard library as frozen modules, like
the Linux and macOS binaries; beside it are python3XX.dll, the Visual C++
runtime it needs, and in "jclib" the few extension modules that Windows
CPython does not build into the DLL. This is the layout the PyOxidizer build
had, without OpenSSL, SQLite, Tcl/Tk and libffi.

What it does, in order:

  1. compiles launcher-windows.c with llvm-mingw and writes the core.json
     that tells build.py how to link it against python3XX.dll;
  2. runs build.py, which embeds the modules and links jc.exe;
  3. picks the extension modules and DLLs to ship, by reading what each one
     imports, and checks that jc.exe needs nothing else;
  4. stages them with COPYING.txt and writes jc-<version>-windows.zip;
  5. writes jc.wxs, the WiX source build-windows.sh turns into the .msi.
"""
import argparse
import json
import re
import shutil
import struct
import subprocess
import sys
import uuid
import zipfile
from pathlib import Path
from xml.sax.saxutils import quoteattr

HERE = Path(__file__).resolve().parent

NAME = 'jc'
RUN = 'import jc.cli; jc.cli.main()'
TARGET_TRIPLE = 'x86_64-pc-windows-msvc'
MINGW_TRIPLE = 'x86_64-w64-mingw32'

# Extension modules (.pyd) are shipped unless they are on this list, or need
# a DLL from the Python distribution other than these. The test helpers and
# the remote debugger are of no use to jc; the DLL rule keeps out _ssl and
# _hashlib (OpenSSL), _sqlite3, _tkinter (Tcl/Tk) and _ctypes (libffi), as
# the Linux and macOS builds leave them out.
EXCLUDED_EXTENSIONS = re.compile(r'^(_test.*|_ctypes_test|xxlimited.*|_remote_debugging)$', re.I)
SHIPPED_DLLS = re.compile(r'^(python3\d+|vcruntime140(_1)?)\.dll$', re.I)

# Standard library packages that are useless without their extension module
# (see build-core.py).
EXCLUDED_STDLIB = ['ctypes', 'curses', 'sqlite3']

# The folder beside jc.exe that holds the extension modules. launcher-windows.c
# puts it on sys.path; the PyOxidizer build used the same name.
EXTENSION_DIR = 'jclib'

# The MSI keeps the identifiers the PyOxidizer installer used, so that it
# upgrades an installed PyOxidizer build in place instead of adding a second
# "jc" beside it. PyOxidizer derived them from the product name.
UPGRADE_CODE = str(uuid.uuid5(uuid.NAMESPACE_DNS, f'tugger.upgrade_code.{NAME}')).upper()
PATH_COMPONENT_GUID = str(uuid.uuid5(uuid.NAMESPACE_DNS, f'tugger.path_component.{NAME}')).upper()
MANUFACTURER = 'Kelly Brazil'


def run(cmd, **kwargs):
    try:
        result = subprocess.run([str(c) for c in cmd], **kwargs)
    except FileNotFoundError:
        sys.exit(f'{cmd[0]} not found')
    if result.returncode:
        sys.exit(f'{Path(str(cmd[0])).name} failed with exit code {result.returncode}')
    return result


def pe_imports(path):
    """Return the names of the DLLs a Windows executable or DLL imports."""
    data = Path(path).read_bytes()
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    if data[:2] != b'MZ' or data[pe:pe + 4] != b'PE\0\0':
        sys.exit(f'{path} is not a Windows executable')
    sections_count, = struct.unpack_from('<H', data, pe + 6)
    optional_size, = struct.unpack_from('<H', data, pe + 20)
    optional = pe + 24
    magic, = struct.unpack_from('<H', data, optional)
    directories = optional + (112 if magic == 0x20b else 96)
    import_rva, _ = struct.unpack_from('<II', data, directories + 8)
    sections = []
    for i in range(sections_count):
        s = optional + optional_size + 40 * i
        vsize, vaddr, rawsize, rawptr = struct.unpack_from('<IIII', data, s + 8)
        sections.append((vaddr, max(vsize, rawsize), rawptr))

    def offset(rva):
        for vaddr, size, rawptr in sections:
            if vaddr <= rva < vaddr + size:
                return rawptr + rva - vaddr
        sys.exit(f'{path}: address {rva:#x} is outside every section')

    names = []
    if import_rva:
        entry = offset(import_rva)
        while True:
            fields = struct.unpack_from('<5I', data, entry)
            if not any(fields):
                break
            start = offset(fields[3])
            names.append(data[start:data.index(b'\0', start)].decode('ascii'))
            entry += 20
    return names


def python_version(python):
    text = (python / 'include' / 'patchlevel.h').read_text()
    return re.search(r'#define\s+PY_VERSION\s+"([^"]+)"', text).group(1)


def prepare_core(python, mingw, core):
    """Compile the launcher and write core.json for build.py (step 1)."""
    clang = mingw / 'bin' / f'{MINGW_TRIPLE}-clang'
    version = python_version(python)
    dll = f"python{''.join(version.split('.')[:2])}"
    core.mkdir(parents=True, exist_ok=True)
    run([clang, '-c', '-O2', '-municode', f"-I{python / 'include'}",
         HERE / 'launcher-windows.c', '-o', core / 'launcher.o'])
    (core / 'core.json').write_text(json.dumps({
        'python_version': version,
        'target_triple': TARGET_TRIPLE,
        'excluded_stdlib': EXCLUDED_STDLIB,
        'cc': [str(clang)],
        'assemble': [str(clang), '-c'],
        # -s: no symbols; no timestamp, so the same inputs give the same file.
        'flags': ['-municode', '-s', '-Wl,--no-insert-timestamp'],
        'inputs': ['launcher.o'],
        'libs': [str(python / 'libs' / f'{dll}.lib')],
        'strip': False,
    }, indent=1) + '\n')
    return dll + '.dll'


def pick_files(python, exe):
    """Return (extension modules, DLLs) to ship beside jc.exe (step 3)."""
    provided = {p.name.lower(): p for p in [*python.glob('*.dll'), *(python / 'DLLs').glob('*.dll')]}

    def bundled_needs(path):
        return [d for d in pe_imports(path) if d.lower() in provided]

    extensions, left_out = [], []
    for pyd in sorted((python / 'DLLs').glob('*.pyd'), key=lambda p: p.name.lower()):
        if EXCLUDED_EXTENSIONS.match(pyd.stem):
            continue
        if all(SHIPPED_DLLS.match(d) for d in bundled_needs(pyd)):
            extensions.append(pyd)
        else:
            left_out.append(pyd.stem)

    dlls, todo = {}, [exe, *extensions]
    while todo:
        for name in bundled_needs(todo.pop()):
            path = provided[name.lower()]
            if path.name.lower() not in dlls:
                if not SHIPPED_DLLS.match(path.name):
                    sys.exit(f'{name} is needed but is not meant to be shipped')
                dlls[path.name.lower()] = path
                todo.append(path)
    print(f'extension modules: {len(extensions)} shipped; left out: {" ".join(left_out)}')
    print(f'DLLs: {" ".join(p.name for p in dlls.values())}')
    return extensions, sorted(dlls.values(), key=lambda p: p.name.lower())


def check_exe_imports(exe, dll):
    """jc.exe may only need python3XX.dll and DLLs that come with Windows 10."""
    unexpected = [d for d in pe_imports(exe)
                  if d.lower() != dll.lower() and not re.match(
                      r'^(api-ms-win-.*|kernel32)\.dll$', d, re.I)]
    if unexpected:
        sys.exit(f'{exe.name} imports DLLs that are not shipped: {" ".join(unexpected)}')


def license_text(python, site):
    """COPYING.txt: the licenses of jc, its dependencies and Python."""
    parts = []
    infos = sorted(site.glob('*.dist-info'), key=lambda p: (not p.name.startswith(f'{NAME}-'),
                                                           p.name.lower()))
    for info in infos:
        files = sorted(p for p in info.rglob('*') if p.is_file()
                       and re.match(r'(LICEN[CS]E|COPYING|NOTICE|AUTHORS)', p.name, re.I))
        for f in files:
            parts.append((f'{info.name[:-len(".dist-info")]}: {f.name}', f.read_text('utf-8')))
    parts.append((f'Python {python_version(python)}', (python / 'LICENSE.txt').read_text('utf-8')))
    rule = '=' * 78
    return ''.join(f'{rule}\n{title}\n{rule}\n\n{text.strip()}\n\n' for title, text in parts)


def stage(stage_dir, exe, extensions, dlls, copying):
    """Lay out the files as they are installed (step 4)."""
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    (stage_dir / EXTENSION_DIR).mkdir(parents=True)
    shutil.copy2(exe, stage_dir / f'{NAME}.exe')
    for path in dlls:
        shutil.copy2(path, stage_dir / path.name)
    for path in extensions:
        shutil.copy2(path, stage_dir / EXTENSION_DIR / path.name)
    (stage_dir / 'COPYING.txt').write_text(copying, 'utf-8', newline='\r\n')


def write_zip(stage_dir, out):
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(stage_dir.rglob('*')):
            z.write(path, Path(stage_dir.name) / path.relative_to(stage_dir))


def msi_version(version):
    if not re.fullmatch(r'\d+(\.\d+){1,3}', version):
        sys.exit(f'an MSI version must be numbers only, like 1.26.2, not {version}')
    return version


def write_wxs(stage_dir, version, out):
    """WiX source for the MSI (step 5). wixl and WiX 3 both read it.

    It installs what the PyOxidizer installer did, where it did: every file
    under "Program Files\\jc", and that folder at the end of the system PATH.
    """
    def component_id(rel):
        return 'c_' + re.sub(r'[^A-Za-z0-9_.]', '_', rel)

    def guid(rel):
        return str(uuid.uuid5(uuid.NAMESPACE_URL, f'jc-packaging:windows:{rel}')).upper()

    def files_in(folder, indent):
        lines = []
        for path in sorted(p for p in folder.iterdir() if p.is_file()):
            rel = path.relative_to(stage_dir).as_posix()
            lines += [
                f'{indent}<Component Id="{component_id(rel)}" Guid="{guid(rel)}" Win64="yes">',
                f'{indent}  <File Id="f_{component_id(rel)[2:]}" Name={quoteattr(path.name)} '
                f'Source={quoteattr(str(path))} KeyPath="yes"/>',
                f'{indent}</Component>',
            ]
        return lines

    components = files_in(stage_dir, ' ' * 10)
    components += [f'          <Directory Id="JCLIB" Name="{EXTENSION_DIR}">',
                   *files_in(stage_dir / EXTENSION_DIR, ' ' * 12),
                   '          </Directory>']
    refs = [f'      <ComponentRef Id="{m}"/>'
            for m in re.findall(r'<Component Id="([^"]+)"', '\n'.join(components))]

    out.write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Written by build-windows.py. -->
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="{NAME}" Version="{msi_version(version)}" Manufacturer="{MANUFACTURER}"
           UpgradeCode="{UPGRADE_CODE}" Language="1033" Codepage="1252">
    <Package InstallerVersion="500" Compressed="yes" InstallScope="perMachine"
             Manufacturer="{MANUFACTURER}" SummaryCodepage="1252"
             Description="{NAME} {version}: JSON Convert"/>
    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed. Setup will now exit."/>
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes"/>
    <Property Id="ARPURLINFOABOUT" Value="https://github.com/kellyjonbrazil/jc"/>

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder" Name="PFiles">
        <Directory Id="APPLICATIONFOLDER" Name="{NAME}">
{chr(10).join(components)}
          <Component Id="Path" Guid="{PATH_COMPONENT_GUID}" Win64="yes">
            <!-- The PATH entry must be removed again on uninstall, which in the
                 MSI Environment table is a "-" in front of the name. WiX writes
                 it for Permanent="no", but wixl (msitools) has the attribute
                 backwards and writes it for Permanent="yes". This file is
                 built with wixl. -->
            <Environment Id="PATH" Name="PATH" Value="[APPLICATIONFOLDER]" Permanent="yes"
                         Part="last" Action="set" System="yes"/>
          </Component>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="MainProgram" Title="Application" Description="Installs all application files"
             Level="1" ConfigurableDirectory="APPLICATIONFOLDER" AllowAdvertise="no"
             Display="expand" Absent="disallow">
{chr(10).join(refs)}
      <Feature Id="Environment" Title="PATH Environment Variable"
               Description="Add the install location to the PATH system environment variable"
               Level="1" Absent="allow">
        <ComponentRef Id="Path"/>
      </Feature>
    </Feature>
  </Product>
</Wix>
''', 'utf-8')


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--version', required=True, help='jc version being built')
    p.add_argument('--python', required=True, type=Path,
                   help='unpacked Windows CPython (python-build-standalone install_only)')
    p.add_argument('--mingw', required=True, type=Path, help='unpacked llvm-mingw toolchain')
    p.add_argument('--site', required=True, type=Path,
                   help='jc and its dependencies, installed for Windows (pip install --target)')
    p.add_argument('--build', required=True, type=Path, help='scratch folder')
    p.add_argument('--dist', required=True, type=Path, help='output folder')
    args = p.parse_args()

    python, build = args.python.resolve(), args.build.resolve()
    core = build / 'core'

    # 1. + 2. jc.exe
    dll = prepare_core(python, args.mingw.resolve(), core)
    exe = build / f'{NAME}.exe'
    # A private bytecode cache keeps the embedded bytecode identical from
    # build to build, as in build-binary.sh.
    run([sys.executable, '-I', '-X', f"pycache_prefix={build / 'pycache'}",
         HERE / 'build.py', '--core', core, '--source', args.site.resolve(),
         '--stdlib', python / 'Lib', '--run', RUN, '--output', exe, '--work', build / 'work'])
    check_exe_imports(exe, dll)

    # 3. + 4. the files beside it, and the zip
    extensions, dlls = pick_files(python, exe)
    stage_dir = build / f'{NAME}-{args.version}-windows'
    stage(stage_dir, exe, extensions, dlls, license_text(python, args.site.resolve()))
    args.dist.mkdir(parents=True, exist_ok=True)
    archive = args.dist / f'{NAME}-{args.version}-windows.zip'
    write_zip(stage_dir, archive)
    print(f'{archive}: {archive.stat().st_size / 1e6:.1f} MB')

    # 5. the MSI's source
    write_wxs(stage_dir, args.version, build / f'{NAME}.wxs')


if __name__ == '__main__':
    main()
