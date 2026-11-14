# XAirDrop

Apple-device sharing through Xiaomi Share on selected Xiaomi 15 and Xiaomi 15 Ultra ROMs. A KernelSU/SukiSU module by [Leekin2](https://github.com/Leekin2) and [mertcqnkld](https://github.com/mertcqnkld). No LSPosed or Xposed required.

**[Download XAirDrop 1.2.1 test (code155)](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2.1-test)**

The new verified profile is **Xiaomi 15 Ultra on OS4.0.3.0.XOACNXM**, with kernel 6.6.118-android15-8-gf72a02f47f4b-abogki551678766-4k. The module checks exact stock WLAN driver and dependency identities.

This release adds stock Mi Share 5.5.0 support, startup without preinit, and improvements to receive sessions and shutdown. The download is about 8 MiB.

**Test release with IPA disabled.** The repaired code154 runtime passed startup, receive session, Wi-Fi recovery, and reboot tests. The code155 ZIP passed local checks. iPhone discovery and bidirectional transfer remain unverified on this ROM.

## Usage

1. Keep a supported original Mi Share version installed.
2. Install the ZIP through KernelSU or SukiSU and reboot normally.
3. Enable Wi-Fi and Bluetooth, then open Mi Share's Apple-device receive screen.
4. Close the screen normally and verify that Wi-Fi reconnects.

[Release notes and compatibility](releases/1.2.1-test/README.md) · [Quick guide](releases/1.2.1-test/USAGE-EN.txt) · [Previous v1.2-test release](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2-test)

## Support and credits

[@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle) · [HyperVoltron](https://t.me/HyperVoltron)

Credits include Qualcomm CLO WLAN, Google Wonder 3.6.5, [Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), the MiAirDrop reference, and Xiaomi components.
