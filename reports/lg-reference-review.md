# LG AOSPA integration comparison

These `v60-archive` forks are reference-only and stay on `aospa` with full
history. They were absent from the workspace, so the exact supplied repositories
were cloned under `ref-lg`. `.find-ignore` and Porsche's source exclusions keep
them out of Soong and Make.

The matching [maintainer local manifest](https://github.com/v60-archive/manifest/blob/penguin17/timelm.xml)
selects all four `aospa` branches. Its [PenguinOS Celerity platform manifest](https://github.com/Project-PenguinOS/manifest/blob/celerity/default.xml)
uses Android 17 (`android-17.0.0_r1`) and AOSPA `calcite` remotes. This is the same
Android generation as our target, with custom ROM branding and some older
SM8250 HAL branches. The Android 13 fingerprints describe stock blobs. This
does not establish an official AOSPA maintenance designation for the forks.

| Area | LG convention | Porsche / upstream calcite decision |
| --- | --- | --- |
| Product | `aospa_timelm.mk`, late identity after `aospa-target.mk` | Keep the matching upstream calcite product pattern and verified Porsche identity. |
| App ABI | Dual-ABI `core_64_bit.mk` | Restore the same setting from the primary A17 Porsche product; calcite supports it. |
| Registration | Device-local `AndroidProducts.mk` and `aospa_timelm-userdebug` | Keep calcite's existing central registration and `aospa_porsche-userdebug`; no duplicate local product. |
| QCOM | Select `device/qcom/common` components through AOSPA | Preserve new common/vendor HAL ownership; set required calcite display selectors without inheriting duplicate bundles. |
| Namespaces | Root header aliases and explicit device/vendor namespaces | Retain Porsche namespaces; export real SM8350 headers per architecture through existing root aliases. |
| Headers | Shared/ARM/ARM64 UAPI, cleaned for Bionic | Adopt the export structure using only the exact Porsche kernel's generated UAPI and local Bionic cleaner. Preserve raw originals and techpack inline helpers. |
| Policy | Separate private Binder and vendor HIDL context files, CLO vendor policy | Keep verified current CLO types/managers; LG supplies no QMS or IIop replacement. Native Porsche SELinux tests and DSP IPC audit passed. |
| VINTF | Device manifest plus OEM framework matrix | Keep the A17 Porsche/common/Dolby manifests and the Oplus matrix; validate their merged output. |
| Extraction | Python 3 `ExtractUtilsModule`, namespaces and library fixups | Keep Porsche/common Python 3 helpers, verified namespace imports, and supported FILEGROUP annotations. |
| Dependencies | Maintainer local manifest, no device dependency JSON | Keep native calcite `beans.xml`, valid JSON inventory and flattened local-manifest artifact. |

No LG kernel, blobs, hardware policy, driver headers, firmware or audio/camera/
display values were copied. In particular, LG's header-v2/no-vendor-boot layout,
5.15 prebuilt kernel, SM8250 HAL revisions and duplicate-rule bypass are not
Porsche settings. `lg-reference-review.json` records exact reference commits.

The new header exports and native display selectors passed a focused RBE build
of `libdrmutils` and `libgrallocutils` for **both ARM and ARM64**
(`.repo/porsche-rbe-display-02.log`). The shared export ends in `kernel-headers`
as required by calcite's config checks. The new graph contains no LG modules.
