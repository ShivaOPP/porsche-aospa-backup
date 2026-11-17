# Giulia CLO reference review

All five supplied repositories were absent locally and were cloned from the
exact supplied URLs on `celerity`, with full history. They remain clean,
read-only references under `ref-giulia/`. Exact commits and inventories are in
`giulia-reference-review.json`. No SM8650 hardware code, values, blobs, headers,
kernel fragments or firmware were copied into Porsche.

## Oplus ancestry and implementation differences

Giulia Oplus `08bcbf6` and Penguin Oplus `81e2ad9` share **766 ancestral commits**.
Their nearest shared commit is `4831486321f0b21c5d396f9a1c2b07ff8e40eeb3`.
Giulia has 44 commits after that ancestor and Penguin has 100. They share
lineage but have diverged; they are not interchangeable checkouts.

| Component | Giulia celerity | Penguin celerity | Porsche decision |
| --- | --- | --- | --- |
| Lineage touch / LiveDisplay services | Absent | Absent | Keep complete PixelOS A17 implementations |
| HIDL fingerprint 2.3 frontend | Removed | Present | Keep primary Porsche frontend |
| Oplus vibrator frontend | Removed; device selects QTI vibrator | Present | Keep primary effect-stream Oplus service |
| Audio amplifier frontend | Absent | Absent | Keep required PixelOS amplifier |
| FusionLight / ALS capture | AreaCapture and wake-sensor changes | Separate evolving implementation | Keep verified Porsche sensor sub-HALs |
| LTPO / recovery HBP | Removed in `7f6e6c9` | Present | Unselected without Porsche evidence |
| Power extension | New stock OplusTouch AIDL integration | No matching power directory | Keep Porsche native AOSPA extension |
| Namespace / overlays | Root plus `overlay`, QTI QSSI overlay integration | Root plus `overlay` | Keep active PixelOS root, generic and QSSI namespaces |

Giulia's `2696c7c` removes Lineage components, and `8947a19` removes obsolete
HIDL fingerprint declarations for its layout. Those are not Porsche fixes.
The JSON inventories list actual modules, policy hooks, fragments and overlays.

The README retains the four requested legacy option namespaces. Neither
Giulia's device nor common makefiles assigns any of them. Their current
selectors instead include `oplus_sensors.uses_als_capture`, wake sensor flags,
and `qti_vibrator` effect-stream controls and an SM8650 effect library.
FusionLight still declares its backend selector, but these device/common
makefiles do not supply a backend assignment. README defaults therefore do not
establish Porsche hardware support.

Porsche keeps its independently verified `OPLUS_LINEAGE_*` selections and
leaves the unverified FusionLight backend unset. See `oplus-comparison.md` for
each Porsche value and its primary-source evidence.

## Common/device, policy and VINTF conventions

The device inherits its common product and then proprietary vendor product;
its BoardConfig includes common configuration and then device vendor settings.
Common imports `hardware/oplus`, its overlay makefile, framework support and
framework compatibility matrix. Policy includes separate common and QTI hooks;
device additions stay in the device tree. Service modules attach their own
VINTF fragments. This supports Porsche's existing common/device ownership and
explicit namespace, policy and merged-matrix checks.

Giulia has no local AndroidProducts.mk in the inspected checkout. Porsche
retains calcite's central product registration. Giulia's `aospa.dependencies`
still requests Oplus `calcite2` despite the supplied `celerity` checkout, so it
is not a dependency manifest to copy verbatim.

Giulia's duplicate-rule/property-namespace allowances and disabled OTA VINTF
kernel enforcement were not imported. Porsche passes its native SELinux,
VINTF kernel requirements and complete OTA build with those checks enabled.
The two-file QMS/IIop fix remains unchanged; active CLO QMS/IPerf mappings still
match their protected hashes.

Giulia independently defines a SHA-1-checked firmware helper that calls native
`add-radio-file`, corroborating Porsche's existing calcite firmware bridge.
No further firmware change was needed from this reference.

## Kernel pipeline and module checks

The reference kernel is Linux 6.1.190. `build.config.msm.pineapple` inherits
common/AArch64 settings and MSM GKI configuration. The latter merges
`gki_defconfig`, vendor/Pineapple and OnePlus fragments, including an explicit
`vendor/oplus/caihong.config`. That Caihong selection is a reference limitation:
these five checkouts alone do not establish a complete booting Giulia assembly.

The separate build repository provides Kleaf/Bazel/DDK helpers, configuration
editing and environment setup. `_setup_env.sh` sources `BUILD_CONFIG` and
`BUILD_CONFIG_FRAGMENTS`. Its `build.config` symlink points outside that checkout
to `../../build.config`; the production assembly supplies the missing context.
The common device tree refers to `kernel_platform/msm-kernel` load lists.
Calcite's kernel-platform adapter consumes staged Image, DTB/DTBO, headers and
separate module groups. The isolated reference paths are not a ready-to-build
kernel-platform manifest.

This flow uses header v4, init_boot and system_dlkm. Porsche keeps its verified
SM8350 Linux 5.4 Make flow, header v3, DTB in vendor_boot and separate DTBO.
No SM8650 partitions, fragments, CPU tuning, DTBs or module names were imported.

Giulia documents boot loops caused by absent recovery audio prerequisites and
missing WLAN depmod inputs. This prompted an extra Porsche validation:
`validate-images.py` now checks complete depmod node inventories and dependency
closure inside both packed module sets, as well as load-list membership.
All **six boot modules and 88 vendor modules** pass; the vendor load list has
82 entries, and the WLAN alias remains present. No runtime configuration change
was required.

## Changes and verification

- Added `ref-giulia/.find-ignore` before checkout to exclude every reference
  from native source discovery.
- Extended and committed the packed module dependency audit (`ceb53f6`).
- Added this review and exact Git/module provenance.
- After all checkouts completed, lunch and `m nothing` passed. All 11 generated
  module-path lists exclude `ref-giulia/` (`.repo/porsche-reference-check.log`).
- The final Porsche signed OTA, metadata, firmware, AVB, SELinux and VINTF
  checks pass. Hardware boot and feature operation remain untested.
