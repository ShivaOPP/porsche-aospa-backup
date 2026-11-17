# Porsche AOSPA calcite source backup

This preserves the Realme GT 2 (porsche, SM8350) port validated with a complete
signed AOSPA calcite / Android 17 OTA build. It has not been boot-tested.

The porsche-aospa-shiva branches in the linked ShivaOPP repositories contain the port.
Older port branches are preserved in recovery bundles before their remote removal.
Only porsche-aospa-shiva remains as the active/default port branch.
default.xml pins every synced project to its
exact source commit and includes every custom device/platform dependency.
reports/ contains the device facts, validation results and reference reviews.

## Recover the complete source snapshot

Use scripts/restore-source.py on a new empty directory. It downloads the source
snapshot metadata from the source-20261117 release, checks every part's SHA-256,
and streams the archive into that directory. The snapshot preserves the complete Git object stores and metadata, root
links, cached LFS/vendor payloads, extra build tools and inspected references.
The recovery script materializes every source worktree from its exact HEAD.
Each tracked file is stored in its Git database; it is not duplicated as a
second full checkout in the archive.

```bash
python3 scripts/restore-source.py /path/to/new/rom
cd /path/to/new/rom
export AOSPA_SKIP_DEPENDENCIES=true
source build/envsetup.sh
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

The source snapshot excludes regenerable out/ outputs. The validated signed OTA,
boot images and firmware are backed up separately in the release. Operational
authentication credentials are not source dependencies; supply fresh GitHub or
RBE credentials when needed. See environment/README.md.

A backup is complete only when the release has COMPLETE.json and every asset
listed there passes its recorded size and SHA-256. Never infer completion from
a partially populated release.

## Fresh network checkout

The source snapshot is the recovery option that does not depend on upstream
repositories remaining available. A network checkout uses the pinned manifest:

```bash
repo init -u https://github.com/AOSPA/manifest -b calcite
# Copy manifests/pinned-local.xml from this backup into the new checkout:
mkdir -p .repo/local_manifests
cp /path/to/porsche-aospa-backup/manifests/pinned-local.xml .repo/local_manifests/porsche-pinned.xml
repo sync --current-branch --no-tags -j48
export AOSPA_SKIP_DEPENDENCIES=true
source build/envsetup.sh
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

Use the official launcher saved as environment/repo if the host has a wrapper.
Initialize without shallow options. Retry a failed sync with the same 48-job
command. The source snapshot retains the Git history available on this server;
every published custom/modified source branch has full history. Unmodified
platform projects retain their original synced history depth in the snapshot.

## Validation and limitations

The full native OTA build, ELF checks, SELinux, VINTF including kernel
requirements, AVB chains, module dependencies and final OTA signature passed.
The OTA contains 35 partitions and 23 verified A17 firmware images, with no
userdata payload. Its device assertion is RE58B2L1 in text and protobuf metadata.

Hardware boot, recovery, encryption, fingerprint, NFC/eSE, camera, audio,
display, sensors, VoLTE, GPS and Dolby need runtime tests. The 128 GB userdata
image size is unverified. Source-author attribution and already-public upstream
development keys and historical examples are retained with user authorization.
