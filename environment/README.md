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
