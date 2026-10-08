#!/usr/bin/env python3
"""Check a new jc binary against a known-good one using jc's test fixtures.

    compare-binaries.py <reference jc> <candidate jc> <jc source checkout>

For every parser the candidate reports, each fixture file whose name matches
the parser (<parser>.out, <parser>-*.out and so on) is fed to both binaries,
with and without -r, and the output and exit code are compared. The
`-h --<parser>` help text is compared too. Differences are listed; the exit
code is 1 if there were any.

Expect a few when the two binaries embed different Python versions. Python
3.13 and later expand tabs in docstrings, which changes some help text, and
parsers that build output from a set can order keys differently run to run.
"""
import json
import os
import subprocess
import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

if len(sys.argv) != 4:
    sys.exit(__doc__)
reference, candidate, repo = sys.argv[1], sys.argv[2], Path(sys.argv[3])
fixture_root = repo / 'tests' / 'fixtures'
if not fixture_root.is_dir():
    sys.exit(f'{fixture_root} not found: the third argument must be a jc source checkout')

# A fixed environment so both binaries see the same locale and time zone
# (the zone jc's own tests use) and neither picks up local parser plugins.
ENV = {'LC_ALL': 'C.UTF-8', 'TZ': 'America/Los_Angeles', 'PATH': '/usr/bin:/bin',
       'HOME': '/nonexistent'}


def run(binary, args, data=b''):
    p = subprocess.run([binary, *args], input=data, capture_output=True, env=ENV, timeout=300)
    return p.returncode, p.stdout


about = json.loads(run(candidate, ['-a'])[1])
fixtures = sorted(f for f in fixture_root.rglob('*') if f.is_file() and f.suffix != '.json')

jobs = []
for parser in about['parsers']:
    arg, name = parser['argument'], parser['name']
    jobs.append((name, 'help', ['-h', arg], b''))
    stems = {name, name.replace('_', '-')}
    for f in fixtures:
        if any(f.name == s + f.suffix or f.name.startswith((s + '-', s + '.')) for s in stems):
            label = str(f.relative_to(fixture_root))
            data = f.read_bytes()
            jobs.append((name, label, [arg], data))
            jobs.append((name, label + ' (raw)', ['-r', arg], data))


def compare(job):
    name, label, args, data = job
    return name, label, run(reference, args, data), run(candidate, args, data)


identical = 0
differences = []
with ThreadPoolExecutor(max_workers=os.cpu_count() or 2) as pool:
    for name, label, a, b in pool.map(compare, jobs):
        if a == b:
            identical += 1
        else:
            differences.append((name, label, a, b))

print(f'{len(jobs)} runs over {len(about["parsers"])} parsers: '
      f'{identical} identical, {len(differences)} different')
if differences:
    print('by parser:', dict(Counter(d[0] for d in differences)))
for name, label, a, b in differences:
    ref, new = a[1].decode('utf-8', 'replace'), b[1].decode('utf-8', 'replace')
    at = next((i for i in range(min(len(ref), len(new))) if ref[i] != new[i]),
              min(len(ref), len(new)))
    print(f'\n{name}: {label} (exit {a[0]} vs {b[0]})')
    print('  reference:', repr(ref[max(0, at - 60):at + 80]))
    print('  candidate:', repr(new[max(0, at - 60):at + 80]))
sys.exit(1 if differences else 0)
