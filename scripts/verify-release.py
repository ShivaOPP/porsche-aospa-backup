#!/usr/bin/env python3
"""Verify a completed backup release by streaming every recorded asset."""
import argparse
import hashlib
import json
import urllib.request

BASE = 'https://github.com/ShivaOPP/porsche-aospa-backup/releases/download/source-20261117/'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--metadata-only', action='store_true', help='Validate the completion record without downloading large assets')
args = parser.parse_args()
with urllib.request.urlopen(BASE + 'COMPLETE.json', timeout=120) as response:
    record = json.load(response)
if not record.get('complete'):
    raise SystemExit('Backup completion record is not sealed.')
if args.metadata_only:
    print('Completion record:', len(record['assets']), 'assets;', record['source_projects'], 'source worktrees')
    print('Large asset bytes were not downloaded in metadata-only mode.')
else:
    for index, asset in enumerate(record['assets'], 1):
        checksum = hashlib.sha256()
        size = 0
        with urllib.request.urlopen(asset['url'], timeout=120) as response:
            for block in iter(lambda: response.read(8 * 1024 * 1024), b''):
                checksum.update(block)
                size += len(block)
        if size != asset['bytes'] or checksum.hexdigest() != asset['sha256']:
            raise SystemExit('Asset mismatch: ' + asset['name'])
        print(f'Verified {index}/{len(record["assets"])}: {asset["name"]}', flush=True)
    print('Every recorded recovery asset passed size and SHA256 verification.')
