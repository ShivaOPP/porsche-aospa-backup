#!/usr/bin/env python3
"""Restore the verified source snapshot into a new directory."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import urllib.request


BASE = "https://github.com/ShivaOPP/porsche-aospa-backup/releases/download/source-20261117/"


def fetch(name):
    with urllib.request.urlopen(BASE + name, timeout=120) as response:
        return response.read()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    destination = args.destination.resolve()
    if destination.exists() and any(destination.iterdir()):
        raise SystemExit("Use an empty destination; existing source is never overwritten.")
    if not shutil.which("zstd") or not shutil.which("tar"):
        raise SystemExit("Install zstd and GNU tar before restoring.")
    complete = json.loads(fetch("COMPLETE.json"))
    raw = fetch("source-snapshot.json")
    expected = next(a for a in complete["assets"] if a["name"] == "source-snapshot.json")
    if hashlib.sha256(raw).hexdigest() != expected["sha256"]:
        raise SystemExit("Snapshot metadata checksum mismatch.")
    snapshot = json.loads(raw)
    if snapshot.get("requires_git_lfs") and not shutil.which("git-lfs"):
        raise SystemExit("Install git-lfs before restoring the cached vendor payloads.")
    destination.mkdir(parents=True, exist_ok=True)
    decompressor = subprocess.Popen(["zstd", "-d", "-c"], stdin=subprocess.PIPE,
                                    stdout=subprocess.PIPE)
    extractor = subprocess.Popen(["tar", "--no-same-owner", "-xf", "-", "-C", str(destination)],
                                 stdin=decompressor.stdout)
    decompressor.stdout.close()
    archive_hash = hashlib.sha256()
    with tempfile.TemporaryDirectory(prefix="porsche-restore-") as temporary:
        for index, part in enumerate(snapshot["parts"], 1):
            path = Path(temporary) / "current-part"
            for attempt in range(3):
                try:
                    checksum = hashlib.sha256()
                    size = 0
                    with urllib.request.urlopen(part["url"], timeout=120) as response, path.open("wb") as output:
                        for block in iter(lambda: response.read(1024 * 1024), b""):
                            output.write(block)
                            checksum.update(block)
                            size += len(block)
                    if size != part["bytes"] or checksum.hexdigest() != part["sha256"]:
                        raise RuntimeError("Part checksum mismatch: " + part["name"])
                    break
                except Exception:
                    if attempt == 2:
                        raise
                    time.sleep(3)
            with path.open("rb") as source:
                for block in iter(lambda: source.read(1024 * 1024), b""):
                    archive_hash.update(block)
                    decompressor.stdin.write(block)
            print(f"Verified and restored part {index}/{len(snapshot['parts'])}", flush=True)
    decompressor.stdin.close()
    if decompressor.wait() != 0 or extractor.wait() != 0:
        raise SystemExit("Archive decompression/extraction failed; retain the partial directory for inspection.")
    if archive_hash.hexdigest() != snapshot["sha256"]:
        raise SystemExit("Complete compressed archive checksum mismatch.")
    if snapshot.get("layout") == "git-metadata-plus-checkout-v1":
        projects = sorted(snapshot["projects"], key=lambda p: (p["path"].count("/"), p["path"]))
        environment = dict(os.environ, GIT_LFS_SKIP_SMUDGE="1", GIT_TERMINAL_PROMPT="0")
        for index, project in enumerate(projects, 1):
            path = destination / project["path"]
            command = ["git", "-C", str(path)]
            head = subprocess.check_output(command + ["rev-parse", "HEAD"], text=True).strip()
            if head != project["head"]:
                raise RuntimeError("Git revision mismatch: " + project["path"])
            subprocess.run(command + ["restore", "--source=HEAD", "--worktree", "--", "."],
                           check=True, env=environment)
            if project.get("lfs_files"):
                # checkout uses the archived media cache and does not fetch.
                subprocess.run(command + ["lfs", "checkout"], check=True, env=environment)
                for entry in project["lfs_files"]:
                    value = hashlib.sha256()
                    with (path / entry["path"]).open("rb") as source:
                        for block in iter(lambda: source.read(1024 * 1024), b""):
                            value.update(block)
                    if value.hexdigest() != entry["oid"]:
                        raise RuntimeError("Cached LFS payload mismatch: " + entry["path"])
            status_command = command + [
                "-c", "filter.lfs.process=git-lfs filter-process",
                "-c", "filter.lfs.required=true", "status", "--porcelain", "--untracked-files=no",
            ]
            status = subprocess.check_output(status_command, env=environment, text=True).strip()
            if status:
                raise RuntimeError("Restored tracked files differ from HEAD: " + project["path"])
            if index % 25 == 0 or index == len(projects):
                print(f"Materialized and verified {index}/{len(projects)} Git worktrees", flush=True)
    print("Complete source snapshot restored. Use environment/README.md to build.")


if __name__ == "__main__":
    main()
