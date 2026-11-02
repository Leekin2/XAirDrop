# XAirDrop 1.2 test — Unpatched Mi Share (code130)

Apple-device sharing through Xiaomi Share for selected Xiaomi 15 and Xiaomi 15
Ultra ROMs. Requires KernelSU/SukiSU; no LSPosed/Xposed.
This is a **test prerelease** with an **IPA DISABLED — DIAGNOSTIC** driver build.

## Device and ROM profiles

| Device | ROM | Status |
|---|---|---|
| Xiaomi 15 Ultra (`xuanyuan`) | `OS4.0.0.18.XOACNXM` | **Tested:** session operation, normal close, Wi-Fi recovery and automatic startup after a normal reboot passed. |
| Xiaomi 15 (`dada`) | `OS4.0.0.61.XOCCNXM` | Device profile added; physical testing on this device is pending. |

Exact kernel required for both profiles:
`6.6.118-android15-8-gb9cc6ec16bc8-abogki536571621-4k`.
The installer also verifies the stock WLAN/mac80211 files and the loaded driver
identity. An unsupported device, ROM, kernel or stock driver is rejected before
firmware or driver changes. A matching kernel name alone does not guarantee compatibility.

## Changes

- Uses the **original installed Mi Share 5.4.2 or 5.4.4**. The ZIP does not include,
  modify or bind-mount the Mi Share APK.
- Adds the two required network permissions through a PRODUCT signature-permission
  XML and verifies that the permissions are actually granted.
- Fixes automatic startup, normal shutdown and startup after a normal system reboot.
- Retains the separate **MiIntentResolver patch** for the Gallery share sheet.
- Uses the Qualcomm CLO passthru driver, Wonder 3.6.5/API10 and the FW2 stack.
- Module size: approximately **22 MiB**, about **12.6 MiB smaller** than the previous
  package with the patched Mi Share APK.

## Test results

**Tested on Xiaomi 15 Ultra:** with the original Mi Share 5.4.4, two sessions
remained active for 62.92 and 62.60 seconds. Normal close, Wi-Fi/IP recovery,
ping and automatic startup after a normal system reboot passed. API10,
firmware `200c002e` and self-peer authorization were verified.

These physical test results are from code129. Published code130 adds the device
profile, installer messages and notes; its driver, firmware, XOS and session/shutdown
code are identical. Code130 was not separately installed on a phone.
**82 offline checks passed.**

**iPhone discovery, sending and receiving have not yet been tested with this
unpatched variant.** Transfer results from the previous patched version do not
establish transfer support for this variant. Mi Share 5.4.2 is accepted by its
known file identity; physical testing used 5.4.4.

## Installation and use

1. Install the original Mi Share 5.4.2 or 5.4.4 if it is not already installed.
2. Disable the old XAirDrop module and reboot with the stock driver.
3. Install `XAirDrop-1.2-MiShare-Yamasiz-test.zip` in KernelSU/SukiSU and reboot
   through the normal system power menu. Preinit support is required.
4. With Wi-Fi and Bluetooth enabled, open Mi Share's Apple-device sharing screen.
   On the iPhone, enable AirDrop → Everyone for 10 Minutes. Start with a small photo.
5. Close the Apple-device screen normally and check that Wi-Fi reconnects.

You do not need to reinstall the module or press Action for each session.
Do not use it alongside other AirDrop/WLAN modules.

## Recovery and logs

If a problem occurs, disable the module and reboot. Do not unload the candidate
driver live or blindly delete protection records. If boot gets stuck, power the
phone off and start it while holding Volume Down; disable the module in SukiSU safe mode.

In a root terminal:
`su -c "sh /data/adb/modules/xairdrop/collect-log.sh"`

Log file: `Download/xairdrop-1.2-test-*.log`. Send logs privately for support;
check for personal information before attaching them to a public issue.

## Authors and support

[Leekin2](https://github.com/Leekin2) · [mertcqnkld](https://github.com/mertcqnkld)

Telegram: [@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle)
· [HyperVoltron](https://t.me/HyperVoltron).

Credits: Qualcomm CLO WLAN.LA.1.0.r1-09900-pakala.0, Google Wonder 3.6.5,
[Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), the supplied MiAirDrop
firmware/controller reference, and Xiaomi's service/application binaries.
This release includes the module ZIP and usage documentation. The local development
tree and QCA/WLAN source archive are not included.

SHA256: `b2ba59f785fc0b203a3c888c70a7dc4de9bf764def82535a828c260ffb0a7c98`
