# XAirDrop

Apple-device sharing through Xiaomi Share for selected Xiaomi 15 and Xiaomi 15 Ultra ROMs.
By [Leekin2](https://github.com/Leekin2) and [mertcqnkld](https://github.com/mertcqnkld).
A KernelSU/SukiSU module. No LSPosed/Xposed.

**[Download: XAirDrop 1.2 test — Unpatched Mi Share](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2-test)**

| Device | ROM | Status |
|---|---|---|
| Xiaomi 15 Ultra (`xuanyuan`) | `OS4.0.0.18.XOACNXM` | **Tested:** session operation, normal close, Wi-Fi recovery and automatic startup after a normal reboot. |
| Xiaomi 15 (`dada`) | `OS4.0.0.61.XOCCNXM` | Device profile added; physical testing pending. |

Exact kernel: `6.6.118-android15-8-gb9cc6ec16bc8-abogki536571621-4k`.
The installer also checks the stock driver identity and stops before changing
firmware/drivers if the identity is unsupported.

**Test prerelease. iPhone discovery, sending and receiving have not yet been tested
with this unpatched variant.** See the release notes for the exact test scope.

## Installation

1. Have the original **Mi Share 5.4.2 or 5.4.4** installed. The ZIP does not include or patch Mi Share.
2. Disable the old XAirDrop module and reboot with the stock driver.
3. Install the latest ZIP in KernelSU/SukiSU and reboot through the normal system power menu.
4. With Wi-Fi/Bluetooth enabled, open Mi Share's Apple-device sharing screen.
   Close it normally to restore the Wi-Fi connection.

Preinit support is required. You do not need to reinstall or press Action for each
session. The separate MiIntentResolver Gallery patch is retained.
Driver configuration: **IPA DISABLED — DIAGNOSTIC**.

[Installation, test results, recovery and logs](releases/1.2-test/README.md) ·
[Quick usage guide](releases/1.2-test/USAGE-EN.txt) ·
[Previous 1.0 beta](https://github.com/Leekin2/XAirDrop/releases/tag/v1.0)

## Support

[@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle)
· [HyperVoltron](https://t.me/HyperVoltron).

## Credits

Qualcomm CLO WLAN.LA.1.0.r1-09900-pakala.0, Google Wonder 3.6.5,
[Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), the supplied MiAirDrop
firmware/controller reference, and Xiaomi's service/application binaries. LICENSE
and per-file upstream notices apply. Historical project source remains in this
repository. The current local development tree is not included in this release.
