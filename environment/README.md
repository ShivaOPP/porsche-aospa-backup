# Current build mode

Follow ../SOURCE-BUILD.md for a normal local build with USE_RBE=false.
Custom RBE client binaries and credentials are not published. Source helper
scripts and the earlier environment notes below are retained for reference.
Archive downloads described in historical notes are retired.

---

# Build environment

The validated host used Ubuntu 22.04 x86_64. Recovery requires git, git-lfs,
Python 3, GNU tar and zstd. packages.tsv records its installed
package versions. Source toolchains, kernel headers, vendor blobs and the
additional BuildBuddy binaries are preserved in the source snapshot. The
BuildBuddy binaries are also supplied as a separate release asset for a fresh
network checkout.

The RBE scripts are provided after a secret scan. Configure your own BuildBuddy
credentials before enabling RBE; authentication credentials are not needed for
a local build and are not part of this source backup. The helper expects its
runtime configuration under ~/.rbe. The original scripts' fixed checkout paths
may need adjusting on a new host.

Local build after restoring the snapshot:

```bash
export AOSPA_SKIP_DEPENDENCIES=true
source build/envsetup.sh
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

For RBE on a fresh network checkout, first extract the separate
buildbuddyfix.tar.zst release asset at the source root. Source-snapshot recovery
already includes it. Install the supplied helper scripts under your own ~/.rbe,
adjust their checkout path and configure fresh credentials, then run:

```bash
export AOSPA_SKIP_DEPENDENCIES=true
source ~/.rbe/rbe-auto.sh
rbe_auto "$PWD"
source build/envsetup.sh
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

The full snapshot supports an offline source recovery and local build. A fresh
network sync still depends on upstream hosting/access, including CodeLinaro.
The source Git databases and cached LFS payloads are preserved so that recovery
does not depend on those upstream servers remaining available.
