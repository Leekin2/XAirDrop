# XAirDrop 1.2.1 test (code155)

## Changes since v1.2-test (code130)

- Added a Xiaomi 15 Ultra profile for HyperOS OS4.0.3.0.XOACNXM. The module checks the exact kernel release (6.6.118-android15-8-gf72a02f47f4b-abogki551678766-4k) and stock WLAN driver and dependency identities.
- Added support for stock Mi Share 5.5.0, including APK identity and network permission checks. The ZIP does not include the Mi Share APK. Earlier 5.4.2 and 5.4.4 profiles remain available, with a version-specific Ask fix for 5.4.4.
- Moved firmware selection to post-fs-data, removing the preinit requirement. Improved automatic startup, clean shutdown, and recovery guards.
- The module's Action button opens the stock Apple receive screen when the service is active. Failed peer setup is rolled back, and shutdown prevents new work from being queued.
- The stock Gallery sharing component already handles the AirDrop target on the verified OS4.0.3.0 build, so the older Gallery patch is skipped on that build.
- Reduced the download from about 22 MiB to 8 MiB using lossless compression.

## Verification

The repaired code154 runtime passed API10 startup, three receive sessions, Wi-Fi reconnection, and automatic startup after a clean reboot on Xiaomi 15 Ultra with OS4.0.3.0. The last session stayed active for 35 seconds of monitoring with no recorded firmware crash. All 1,006 symbol imports matched, along with 541 field offsets across 16 structures.

The published code155 ZIP passed local archive, checksum, and shell syntax checks. It ships the same kernel modules, firmware, and XOS files as the tested runtime. Code155 was not separately installed on the phone.

**iPhone discovery, transfers in both directions, and transfer speed on this ROM remain unverified.** Earlier ROM profiles were not retested for this release. IPA remains disabled in this diagnostic build.

## Installation and use

1. Keep a supported original Mi Share version installed. Start from a stock-driver boot for a first install or when recovering an unhealthy installation.
2. Install the ZIP in KernelSU or SukiSU and reboot normally.
3. Enable Wi-Fi and Bluetooth, then open Mi Share's Apple-device receive screen. Accept incoming requests on the Xiaomi device.
4. Close the screen normally and check that Wi-Fi reconnects.

Unresolved driver and shutdown guards are preserved. If you encounter a problem, disable the module and reboot. Collect logs with: su -c "sh /data/adb/modules/xairdrop/collect-log.sh"

ZIP SHA256: 6534ab6c104c3e4afad254f5dc29ad972b476059a396c5634afdeeabb3cb2be3

By [Leekin2](https://github.com/Leekin2) and [mertcqnkld](https://github.com/mertcqnkld). Credits include Qualcomm CLO WLAN, Google Wonder 3.6.5, [Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), the MiAirDrop reference, and Xiaomi components.
