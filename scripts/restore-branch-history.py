#!/usr/bin/env python3
"""Restore archived branch references into a corrected full-history clone."""
import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('repository', type=Path)
parser.add_argument('recovery_directory', type=Path)
parser.add_argument('source_path', help='Original source path, for example device/realme/porsche')
args = parser.parse_args()
rows = json.loads((args.recovery_directory / 'index.json').read_text())
row = next(x for x in rows if x['path'] == args.source_path)
git = ['git', '-C', str(args.repository.resolve())]
subprocess.run(git + ['cat-file', '-e', row['corrected_head'] + '^{commit}'], check=True)
if row['bundle']:
    bundle = args.recovery_directory.resolve() / row['bundle']
    subprocess.run(git + ['bundle', 'verify', str(bundle)], check=True)
    subprocess.run(git + ['fetch', str(bundle),
                         'refs/backup-precleanup/ShivaOPP/*:refs/backup-precleanup/ShivaOPP/*'], check=True)
for name, expected in row['old_branches'].items():
    ref = 'refs/backup-precleanup/ShivaOPP/' + name
    subprocess.run(git + ['cat-file', '-e', expected + '^{commit}'], check=True)
    current = subprocess.run(git + ['rev-parse', '--verify', ref], capture_output=True, text=True)
    if current.returncode == 0:
        if current.stdout.strip() != expected:
            raise SystemExit('Existing recovery ref differs; no overwrite: ' + ref)
    else:
        subprocess.run(git + ['update-ref', ref, expected, '0' * 40], check=True)
    print(ref, expected)
print('Archived branch references restored. Active build branch is unchanged.')
