# Oplus candidate comparison

Keep the ported PixelOS-AOSP tree at hardware/oplus. Penguin is not the best complete replacement for Porsche because required primary HAL implementations are absent.

The original A17 reference was already promoted to hardware/oplus; hardware/oplus-a17-ref is not a second checkout. Upstream baseline ff49635 is retained in Git.

The complete module, namespace, VINTF and policy inventory is in
`oplus-comparison.json`. Counts include Blueprint and Make declarations; the
uvite audio module uses the dynamic name `audio_amplifier.$(TARGET_BOARD_PLATFORM)`.

| Component in this repository | PixelOS A17 (active) | Penguin Celerity | AOSPA uvite |
| --- | --- | --- | --- |
| touch | `vendor.lineage.touch-service.oplus`, `vendor.oplus.hardware.touch-headers` | absent here | `KeyHandler`, `tri-state-key-calibrate` |
| fingerprint | `libudfps_extension.oplus`, `libshims_aidl_fingerprint.oplus_defaults`, `libshims_aidl_fingerprint_v2.oplus` (+5 more; see JSON) | `libudfps_extension.oplus`, `libshims_aidl_fingerprint.oplus_defaults`, `libshims_aidl_fingerprint_v2.oplus` (+5 more; see JSON) | `android.hardware.biometrics.fingerprint@2.3-service.oplus`, `libshims_fingerprint.oplus`, `libudfps_extension.oplus` |
| livedisplay | `vendor.lineage.livedisplay-oplus-ab`, `vendor.lineage.livedisplay-oplus-af`, `vendor.lineage.livedisplay-oplus-dm` (+3 more; see JSON) | absent here | absent here |
| vibrator | `vendor.qti.hardware.vibrator.impl.oplus`, `vendor.qti.hardware.vibrator.service.oplus`, `liboplusvibratoreffect` (+2 more; see JSON) | `vendor.qti.hardware.vibrator.impl.oplus`, `vendor.qti.hardware.vibrator.service.oplus`, `liboplusvibratoreffect` (+2 more; see JSON) | `oplus_aospa_vibrator_hal_cc_defaults`, `vibrator_effect_stream_defaults`, `oplus_aospa_vibrator_effect_defaults` (+3 more; see JSON) |
| sensors / fusionlight | `sensors.oplus`, `sensors.ssc_custom_flag`, `sensors.fusionlight` (+1 more; see JSON) | `sensors.oplus`, `sensors.ssc_custom_flag`, `sensors.fusionlight` (+1 more; see JSON) | `sensors.oplus` |
| ltpo | absent here | `OplusLtpo` | absent here |
| nrmodeswitcher | `nrmodeswitcher` | `nrmodeswitcher` | absent here |
| hbp-daemon | `hbp-setup` | `hbp-setup` | absent here |
| oplus-fwk | `oplus-fwk` | `oplus-fwk`, `oplus-fwk-vibrator-lib` | absent here |
| rfs | `rfs_mdm_mpss_readonly_dycnvbk_symlink`, `rfs_msm_mpss_readonly_dycnvbk_symlink` | `rfs_mdm_mpss_readonly_dycnvbk_symlink`, `rfs_msm_mpss_readonly_dycnvbk_symlink` | absent here |
| usb | `oplus_usb_compositions.conf` | `oplus_usb_compositions.conf` | absent here |
| wvmkiller | `wvmkiller` | `wvmkiller` | absent here |
| extract-utils-ext | source / helpers present | source / helpers present | absent here |
| audio amplifier | `audio_amplifier.qcom` | absent here | `audio_amplifier.$(TARGET_BOARD_PLATFORM)` |
| overlays | `TelephonyResCommon`, `FrameworksResCommon`, `SystemUIResCommon` (+4 more; see JSON) | `FrameworksResCommon`, `SettingsProviderResCommon`, `OPlusWifiResCommon` (+1 more; see JSON) | absent here |

Availability in this table is not proof of Porsche hardware support. The old
device tree supplied some features itself; those originals remain in Git.
PixelOS and Penguin both retain HIDL fingerprint 2.3 and AIDL sensor/vibrator
frontends. Penguin is not uniformly AIDL and its newer maintenance history
does not replace its missing touch, LiveDisplay and amplifier implementations.

| Repository | Soong namespaces | Policy entry points |
| --- | --- | --- |
| PixelOS active | `.`, `overlay/qssi`, `overlay/generic` | `sepolicy/qti/SEPolicy.mk` |
| Penguin celerity | `.`, `overlay` | `sepolicy/qti/SEPolicy.mk`, `sepolicy/common/SEPolicy.mk` |
| AOSPA uvite | `.` | `sepolicy/qti/SEPolicy.mk` |

VINTF fragments are listed per component in the JSON, including the conditional
LiveDisplay PA/SE and touch HTPR/TG fragments. The active PixelOS policy is
already translated to current CLO types and has passed native SELinux tests.
Its root imports point to the verified SM8350 header provider; its settings
apps use AOSPA resources. No Penguin policy, overlays or extra HALs were enabled.

| Namespace | Option | Porsche value | Evidence / reason |
| --- | --- | --- | --- |
| `OPLUS_LINEAGE_LIVEDISPLAY_HAL` | `ENABLE_AB/ENABLE_AF/ENABLE_DM` | `unset (false)` | No A17 Porsche override; not enabled without verified device controls. TODO(porsche). |
| `OPLUS_LINEAGE_LIVEDISPLAY_HAL` | `ENABLE_PA/ENABLE_SE` | `true / true` | Preserve the primary A17 service defaults and selected VINTF fragments. |
| `OPLUS_LINEAGE_TOUCH_HAL` | `ENABLE_GM` | `unset (false)` | No verified Porsche glove-mode enable in the A17 reference. TODO(porsche). |
| `OPLUS_LINEAGE_TOUCH_HAL` | `ENABLE_HTPR/ENABLE_TG` | `true / true` | Primary HAL defaults; Porsche DTS declares game_switch_support and black_gesture_indep_support. |
| `OPLUS_LINEAGE_TOUCH_HAL` | `GESTURE_ENABLE_INDEP_NODES` | `/proc/touchpanel/double_tap_enable_indep` | Exact primary HAL default and kernel proc node. |
| `OPLUS_LINEAGE_TOUCH_HAL` | `HTPR_ENABLE_NODE/HTPR_ENABLE_VALUE` | `default GAME_SWITCH_ENABLE_NODE / 1` | These select the unused stock AIDL backend; direct mode uses game_switch_enable with 1/0. |
| `OPLUS_LINEAGE_TOUCH_HAL` | `INCLUDE_DIR` | `device/realme/porsche/touch/include` | Unchanged primary Porsche TouchscreenGestureConfig.h; no added gesture IDs. |
| `OPLUS_LINEAGE_TOUCH_HAL` | `USE_OPLUSTOUCH` | `false` | Keep the primary direct proc-node backend, not an unverified stock AIDL server. |
| `OPLUS_LINEAGE_VIBRATOR_HAL` | `USE_EFFECT_STREAM` | `true` | Explicit setting in the booting A17 Porsche device product. |
| `OPLUS_LINEAGE_VIBRATOR_HAL` | `INCLUDE_DIR` | `unset` | Primary A17 uses module defaults; the uvite effect header is not a verified override for this implementation. TODO(porsche). |
| `OPLUS_SENSORS_FUSIONLIGHT` | `BACKEND_SUBHAL_LIB_NAME` | `unset; wrapper not selected` | Primary hals.conf loads sensors.ssc.so and sensors.oplus.so. No verified FusionLight wrapper/backend. TODO(porsche). |

Optional LTPO, HBP and FusionLight components remain unselected; the primary
Porsche product provides no verified configuration for them. The existing
fingerprint, audio, sensors, touch and vibrator implementations are preserved.
`wvmkiller` remains selected. `oplus-fwk.mk` is inherited; the current Porsche
blob lists do not select AONService, so its Penguin-specific wrapper additions
were not imported without a dependency. Existing native QCOM RFS/USB ownership
is retained.

Conflicts and gaps:
- Penguin README advertises touch/livedisplay options whose implementations were removed in f90ff97.
- Penguin lacks audio_amplifier.qcom, required by primary SM8350 common audio selection.
- Penguin overlay namespace is overlay/, while the primary tree uses overlay/generic and overlay/qssi.
- Penguin splits policy into common and qti hooks; replacing the tree would require translating existing verified CLO policy adaptations.
- Unselected reference copies would duplicate module names without source exclusions; each reference is excluded.

The native RBE build passed all selected targets:
`vendor.lineage.touch-service.oplus`, `vendor.lineage.livedisplay-service.oplus`,
`vendor.qti.hardware.vibrator.service.oplus`,
`android.hardware.biometrics.fingerprint@2.3-service.oplus`,
`android.hardware.sensors-service.oplus-multihal`, `audio_amplifier.qcom`,
`librecovery_updater` and `selinux_policy` (`.repo/porsche-rbe-hals.log`).
The generated graph contains no Penguin reference modules. Integrated boot,
vendor_boot, DTBO and vendor_dlkm images now pass consistency checks; full
VINTF compatibility now passes, including actual kernel requirements
(`vintf-validation.json`). The full signed OTA and its partition/firmware audit now pass
(`ota-validation.json`).

The additional Giulia CLO fork is reviewed in `giulia-reference-review.md`. It
shares 766 ancestral commits with Penguin but has diverged, and removes the
fingerprint/vibrator frontends Porsche retains. It is a structure reference;
the active PixelOS choice remains supported by the completed native build.
