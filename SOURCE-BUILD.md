# Porsche AOSPA calcite source inventory

This repository contains pinned manifests and validation reports for the Realme
GT 2 (porsche, SM8350) port. Required device/dependency repositories and edited
platform trees are under ShivaOPP on their separate porsche-aospa-shiva branches. Original branches and defaults
are preserved. The unchanged ROM base
comes from the AOSPA manifest and its upstream projects.

[Repository and commit table](reports/repositories.md) lists all 25 required
repositories. Device trees, vendor blobs, camera, hardware and kernel sources
are included. GitLab/CodeLinaro imports and pre-existing user repositories remain
owned copies where a GitHub fork network is unavailable or a repo already exists.
No existing repository was replaced or force-pushed.

All full-source, signed-image and ZIP/archive uploads were deleted at the user's
request. This repository provides source references, not an offline source or
binary archive. Unmodified frameworks/base uses upstream AOSPA directly.

## Build from the published source repositories

Use the official repo launcher (environment/repo is included if the host has a
wrapper). Initialize without shallow options. Copy the pinned local manifest
from this metadata checkout into the new AOSPA checkout before syncing:

```bash
git lfs install
repo init -u https://github.com/AOSPA/manifest -b calcite
mkdir -p .repo/local_manifests
cp /path/to/porsche-aospa-backup/manifests/pinned-local.xml .repo/local_manifests/zzz-porsche-pinned.xml
repo sync --current-branch --no-tags -j48
export AOSPA_SKIP_DEPENDENCIES=true
export USE_RBE=false
source build/envsetup.sh
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

Install git-lfs before syncing so the public vendor repositories hydrate their
modem and camera payloads. For a failed sync, retry the same 48-job command.
The official unmodified base is fetched from its upstream hosts, including
CodeLinaro; custom source paths are pinned to the verified ShivaOPP commits.

Porsche's [dependencies file](https://github.com/ShivaOPP/android_device_realme_porsche/blob/porsche-aospa-shiva/porsche.dependencies)
and local manifest are in the device repository. Android 14-to-17 path mapping,
reference reviews and hardware TODOs are in its porting/ directory.

## Validation

A complete signed native OTA, SELinux, VINTF with kernel requirements, AVB,
image/module consistency and blob/module checks passed. Latest source-only
changes update dependency ownership and documentation; hardware configuration
is unchanged. The built files remain on the server and are not release uploads.

Boot and runtime hardware testing remain outstanding. The 128 GB userdata image
size needs device confirmation; no userdata partition is included in the OTA.
Git author/committer corrections cover local port commits and retain upstream
authorship. reports/ preserves validation and publication evidence.
