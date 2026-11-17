# Porsche / AOSPA calcite port

This workspace targets AOSPA `calcite`, confirmed from the synced manifest and
build system as Android 17 (`android-17.0.0_r1`, release configuration `cp2a`).
The registered product is `aospa_porsche`, with
`vendor/aospa/products/porsche/aospa_porsche.mk` as its product makefile.
A full signed OTA has been built and validated. It has not been boot-tested.

## Source ownership

The booting Android 17 Porsche device reference at
`device/realme/porsche-a17-ref` and SM8350 common tree supply device identity,
partition geometry, fstab, properties, overlays, init, kernel configuration and
HAL selections. The original AOSPA uvite device files remain in Git history and
unselected reference files. AOSPA-specific resources, product inheritance and
vendor hooks are preserved and translated to calcite.

`sources.json` records inspected upstream baselines. Every edited repository
uses a local `a17-port` branch; these branches have not been pushed. Upstream
dependency revisions bootstrap the sources and do **not** contain this local
port. Reproducing the port requires applying the local commits in all edited
repositories, including `vendor/aospa`.

| Android 14 path | Active Android 17 path / ownership |
| --- | --- |
| `device/realme/porsche` standalone configuration | `device/realme/porsche` plus `device/oneplus/sm8350-common` |
| `vendor/realme/porsche` within Realme monorepo | Separate `vendor/realme/porsche` plus `vendor/oneplus/sm8350-common` |
| `hardware/oplus` AOSPA uvite | PixelOS-AOSP seventeen at `hardware/oplus`; original at `hardware/oplus-a14-ref` |
| `vendor/oplus/camera` ThankYouMario uvite-porsche | NoPrincessHere seventeen at `vendor/oplus/camera`; original at `vendor/oplus/camera-a14-ref` |
| `kernel/msm-5.4` | `kernel/oneplus/sm8350`; original kernel retained |
| In-tree DolbyManager and old Dolby blobs | `hardware/dolby`, `seventeen-hidl` |
| In-tree sensors / vibrator | Android 17 `hardware/oplus` implementations |
| uvite QCOM audio/display/GPS/media branches | AOSPA calcite-888 / calcite-legacy-component branches at the same active paths |
| uvite NXP HAL repositories | Calcite manifest's `hardware/nxp/nfc/snxxx` AIDL NFC service; old repositories at `*-a14-ref` |

The active A17 vendor blobs come from RMX3312 Android 15
`RMX3312_15.0.0.1670(EX01)` and the A17 common vendor baseline. The reference
product identity is RMX3312 / RE58B2L1, with fingerprint
`realme/RMX3312/RE58B2L1:15/AP3A.240617.008/S.242fe81-7fc3-7fc2:user/release-keys`.
This is a vendor/reference identity, not a claim that the platform is Android 15.

Verified partition geometry: super `11190403072`, dynamic group `11186208768`,
boot and vendor_boot `201326592`, dtbo `25165824`, block size `262144` bytes.
Boot header version is 3. Vendor, ODM and vendor_dlkm use EROFS. The dynamic
group contains odm, product, system, system_ext, vendor and vendor_dlkm.
The unchanged A17 fstab is installed as `fstab.qcom`, which calcite can discover
from the verified `androidboot.hardware=qcom` command line.
The Porsche DTS contains project 21617; the port does not invent a numeric
mapping for the bootloader's `ro.boot.prjname`.

## Dependencies

[`../porsche.dependencies`](../porsche.dependencies) is valid JSON describing
device dependencies. AOSPA's native dependency mechanism is instead
`vendor/aospa/products/porsche/beans.xml`, which includes `platforms/lahaina.xml`.
[`porsche.xml`](porsche.xml) is the flattened local-manifest equivalent for a
fresh checkout. Its remote names are supplied by AOSPA's manifest. The base
manifest already supplies the framework, QCOM interfaces, WLAN, NXP NFC and
other platform projects; these are not redundantly cloned as device repos.

Do not install this manifest over the current standalone Git checkouts. Lunch
uses `AOSPA_SKIP_DEPENDENCIES=true` to protect their local port branches.
The current `.repo/local_manifests/zz-existing-aospa.xml` also protects the
existing standalone `vendor/aospa` checkout from Repo replacement.

## Build commands

The host's `/usr/local/bin/repo` wrapper silently injects shallow init and
changes sync options. Bypass it with the function below. All manual/reference
Git clones have full history. The user's later exception permits shallow
platform sync projects; init has no shallow option, and sync always uses 48 jobs.

```bash
cd /home/ubuntu/rom
repo() { /usr/local/lib/repo/repo-real "$@"; }

# New checkout only: this workspace is already initialized and synced.
repo init -u https://github.com/AOSPA/manifest -b calcite
repo sync --current-branch --no-tags -j48

# Retain the existing local port commits in every edited repository.
export AOSPA_SKIP_DEPENDENCIES=true
source /home/ubuntu/.rbe/rbe-auto.sh
rbe_auto /home/ubuntu/rom
lunch aospa_porsche-cp2a-userdebug
m -j16 otapackage check-vintf-all selinux_policy
```

`lunch aospa_porsche-userdebug` also defaults to `cp2a`. Retry a failed sync
with exactly the same sync command. The `-j16` build option is separate from
Repo's required `-j48`. Dependency files describe upstream bootstrap revisions;
a fresh checkout still needs the local `a17-port` commits listed in
`commits.json`. Those local commits have not been pushed.

## Current validation

| Check | Result / evidence |
| --- | --- |
| Lunch and Soong/Kati/Ninja graph | PASS; `.repo/porsche-nothing-passed.log` and subsequent native builds |
| Dependency JSON, XML, Python helpers, shell syntax | PASS; `python3 -m json.tool`, XML parser, Python AST, `bash -n` |
| Blob inventory coverage | PASS: all 2,424 entries have files/install declarations; `blob-audit.json` |
| Radio packaging | PASS: all 23 staged SHA-1 and final payload SHA-256 values match the primary A17 firmware |
| Standalone kernel, modules, DTBs | PASS with r563880c; `kernel-validation.json` |
| ARM and ARM64 display libraries | PASS; `.repo/porsche-rbe-display-02.log` |
| Touch, LiveDisplay, vibrator, fingerprint, sensors, amplifier and UFS recovery | PASS; `.repo/porsche-rbe-hals.log` |
| SELinux | PASS: compilation, neverallows, contexts, Treble compatibility and final `sepolicy_test`; `.repo/porsche-rbe-selinux-02.log` |
| Compiled DSP access audit | PASS: original Binder/FD/memfd permissions remain, normal client discovery retained, isolated discovery absent; `dsp-ipc-validation.json` |
| Integrated boot/vendor_boot/DTBO/vendor_dlkm | PASS; `.repo/porsche-rbe-images.log` and `image-validation.json` |
| AVB chains and filesystem integrity | PASS: all five expected chain keys/index locations, three boot hashes and six filesystem hashtrees; `avb-validation.json` |
| Signed OTA metadata and contents | PASS: text/protobuf identity RE58B2L1, all 35 partitions, six-partition dynamic group, firmware hashes; no userdata; `ota-validation.json` |
| VINTF, including actual kernel requirements | PASS: direct framework/vendor checks and full compatibility; `vintf-validation.json` |
| Full userspace / OTA packaging | PASS; `.repo/porsche-rbe-ota-13.log` (exit 0) and `ota-validation.json` |
| Device boot and hardware operation | Not tested; generated-image checks do not prove runtime success |

The signed archive is `out/target/product/porsche/aospa_porsche-ota.zip`
(2,821,877,963 bytes). `ota-validation.json` records its SHA-256 and the native
signature-verification result. Repeat the OTA audit with:

```bash
python3 device/realme/porsche/porting/validate-ota.py out/target/product/porsche/aospa_porsche-ota.zip
```

`python3 device/realme/porsche/porting/validate-images.py` repeats the image
checks against actual build outputs without deleting inspection artifacts.
The integrated image checks verify header v3, the compiled kernel payload,
the primary A17 fstab at a supported first-stage path, all three Porsche DTBs,
both Porsche overlays in the kernel's 14-entry DTBO table, 88 vendor_dlkm
modules and six boot modules. Both packed depmod graphs have complete dependency
closure, including recovery's audio prerequisites and the WLAN alias. All module
versions match the built kernel,
`5.4.302-qgki-g69a5611a6c17`, and the WLAN alias is present. EROFS integrity
passed; boot, vendor_boot and DTBO fit their verified partitions. AVB's boot
SPL preserves the primary A17 `2025-04-01` setting.

Blob source coverage does not replace Soong ELF validation or a full VINTF
verdict. No ELF-check bypass or SELinux enforcement disable was introduced.

## Integration changes and references

- AOSPA product inheritance, resources, central lunch registration and native
  `beans.xml` dependency hooks are retained. Porsche uses the primary A17
  dual-ABI app/zygote selection supported by calcite's `core_64_bit.mk`.
- The new common/vendor trees own HAL packages, avoiding duplicate QTI bundles.
  Required display and tinycompress Soong selectors are supplied explicitly.
  The booting A17 gesture, effect-stream, PA/SE and sensor selections remain.
- The kernel header aliases export the exact SM8350 kernel's Bionic-clean UAPI,
  separated into shared, ARM and ARM64 paths. Raw snapshots and originals are
  retained. `regenerate-kernel-headers.py` records provenance and hashes.
  Active shared headers are in `device/oneplus/sm8350-common/uapi/kernel-headers`;
  architecture differences are in `kernel-headers/arm` and `kernel-headers/arm64`.
- Legacy audio Make rules select those cleaned userspace headers for Porsche,
  avoiding raw ARM64 type definitions in 32-bit clients. Kernel compilation
  itself is unchanged. PixelStats annotations use calcite's `module_name`.
- All 88 kernel module image inputs are declared before packaging; six recovery
  modules enter vendor_boot. Existing load lists, blocklist and WLAN alias stay.
  Regenerate module inventory after kernel changes with
  `python3 device/oneplus/sm8350-common/record-kernel-modules.py KERNEL_OUT`.
- Calcite discovers the unchanged A17 fstab as `fstab.qcom`, matching the verified
  `androidboot.hardware=qcom`. The UFS recovery helper selects BSG from the
  actual kernel's `CONFIG_SCSI_UFS_BSG=y` and public UAPI.
- GNSS modules use unchanged A17 vendor configuration via filegroups. The source
  FM interface supplies one canonical module; the duplicate blob remains
  available for ABI comparison. Racing old directory recipes are removed while
  native AOSPA RFS and A17 ACDB/WLAN ownership remain.
- Porsche adds framework-matrix entries for the actual retained touch,
  LiveDisplay and HIDL GNSS service versions/instances. Calcite already supplies
  kernel 5.4.302 compatibility requirements; those checks remain enabled.
- The framework FCM 6 matrix referenced four removed AOSP HIDL definitions.
  `hardware/interfaces` retains the actual frozen API sources and hash records
  from AOSP Android 16 r4; no legacy service implementation is installed.
  `legacy-api-provenance.json` records every restored file hash and source.
- Calcite treats `TARGET_OTA_ASSERT_DEVICE` as one literal identity. The primary
  A17 tree's `RMX3312,RE58B2L1` string would reject installation, so the port uses
  native identity derivation from the actual `RE58B2L1` partition properties.
  `validate-ota.py` checks final metadata against those properties.
- The generated A17 vendor firmware calls a Lineage SHA-1 helper absent from
  calcite. A Porsche-only bridge validates each original hash and calls native
  `add-radio-file`, keeping all 23 firmware images in OTA staging.
- The RMNET library enables its real legacy data API, matching both the
  primary CAF hooks and calcite's 5.4 telephony setup; ELF checks stay enabled.
- The shared service-context patch changes only the two stale QMS/IIop entries.
  Current CLO Binder QMS and HIDL IPerf mapping files remain hash-identical.
  The original narrow attempt was reverted as requested; after expanded
  authorization the fix was reapplied as `acc799a`. DSP policy changes retain
  CLO IPC/buffer behavior under calcite's isolated-compute restrictions.
  `context-fix-validation.json` records the attempts and protected hashes.
- `resource-migrations.json` maps removed uvite resources to calcite behavior.
  Native AOSPA handles gestures; UDFPS and secure NFC use current resource/hooks.
  `android17-overrides.json` records the verified A17 values that override uvite.

`lg-reference-review.md` and its JSON report cover the exact LG reference
commits. Their matching PenguinOS Celerity manifest targets Android 17 and
AOSPA calcite platform projects, not an older Android 13 ROM base. The stock
Android 13 fingerprint describes blobs. The comparison informed the UAPI export
structure and dual-ABI product review; no LG hardware values/code/blobs were
copied. Upstream AOSPA conventions take precedence over the fork.

`oplus-comparison.md` and its complete JSON inventory compare all requested
HALs, namespaces, policy, VINTF fragments, overlays and options. The ported
PixelOS-AOSP tree stays active at `hardware/oplus`: Penguin removed touch,
LiveDisplay and amplifier implementations required by the primary Porsche
layout, despite retaining related README entries. All copies remain on disk.
No unverified LTPO/HBP/FusionLight or stock touch backend was enabled.
The A17 sensors config still loads `sensors.ssc.so` and `sensors.oplus.so`.

`giulia-reference-review.md` covers the additional CLO SM8650 references. Their
Oplus fork shares 766 ancestral commits with Penguin but diverges and removes
required Porsche frontends. Its structure confirms the common/device ownership
and firmware bridge. It prompted packed depmod inventory/dependency checks,
which pass for all six boot and 88 vendor modules. No SM8650 settings were copied.
The references are excluded with `ref-giulia/.find-ignore`; a fresh native
`m nothing` passed after all five full-history checkouts completed.

The obsolete DTB recipe concern was resolved by checking generated Ninja:
Kati correctly defers its `find` commands to execution after the kernel build.
No patch to those recipes is needed. Native image builds have now confirmed it.

## Remaining TODO(porsche)

- The new V7 ADPF `AUDIO_PERFORMANCE` session mode is correctly enumerated but
  unadvertised until the primary PowerHintSession implements it. Existing global
  audio streaming hints remain. Do not claim the new mode is functional.
- Test boot, recovery, encryption, suspend, UDFPS/HBM/press behavior, NFC/eSE,
  camera, audio, display, sensors, VoLTE, GPS, WLAN and Dolby on hardware.
  Retain isolated-compute DSP handle delivery on the runtime test list.
- Test Bluetooth/FM behavior on hardware. The primary service's required FM
  export is present in the built AOSPA source interface; the original comparison
  blob is preserved (`blob-layout-adjustments.json`).
- OEM fast-charge status has no exact calcite overlay resource. Calcite derives
  battery charging speed from health HAL wattage; validate the runtime indicator.
- Optional touch glove mode, extra LiveDisplay controls, vibrator overrides and
  FusionLight backend remain at primary-reference defaults with TODO comments
  until Porsche-specific support can be verified.

Needs device confirmation, without waiting or guessing:

- The primary userdata size `237598617600` is for the 256 GB variant. The 128 GB
  userdata image size is unverified. OTA images do not contain userdata.
- Preserve the actual bootloader `ro.boot.prjname`; do not equate it with DTS
  project 21617 or write a guessed numeric property.

## Disk cleanup and reference recovery

`disk-cleanup.json` records reversible sparse checkout of unrelated devices
from the old Realme vendor worktree (about 5.15 GiB), plus prior abandoned
platform sync-pack/history cleanup. Active Porsche/common/camera/Dolby blobs
and manually cloned Git histories remain intact. Restore reference payloads:

```bash
git -C vendor/realme-a14-ref sparse-checkout disable
git -C vendor/realme-a17-ref/porsche sparse-checkout disable
```

`.find-ignore` markers and product source exclusions keep preserved Android14,
LG, Giulia and Penguin references out of both Soong and Make scans. Remove those guards
only when intentionally reactivating a reference.
