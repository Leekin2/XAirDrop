# XAirDrop

Xiaomi Share üzerinden Xiaomi 15 / Xiaomi 15 Ultra için Apple cihazlarıyla paylaşım.
[Leekin2](https://github.com/Leekin2) ve [mertcqnkld](https://github.com/mertcqnkld).
KernelSU/SukiSU modülü; LSPosed/Xposed kullanılmaz.

**[Güncel indirme: XAirDrop 1.2 test — Mi Share yamasız](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2-test)**

| Cihaz | ROM | Durum |
|---|---|---|
| Xiaomi 15 Ultra (`xuanyuan`) | `OS4.0.0.18.XOACNXM` | **Test edildi:** oturum, normal kapanış, Wi-Fi dönüşü ve yeniden başlatma sonrası otomatik çalışma. |
| Xiaomi 15 (`dada`) | `OS4.0.0.61.XOCCNXM` | Cihaz profili eklendi; fiziksel test bekleniyor. |

Tam kernel: `6.6.118-android15-8-gb9cc6ec16bc8-abogki536571621-4k`.
Kurulum ayrıca stok sürücü kimliklerini denetler; farklı kimlikte sürücüye geçmeden durur.
**Test/ön sürümdür. Bu yamasız varyantta iPhone keşif/gönderme/alma henüz test edilmedi.**

## Kurulum

1. Orijinal Mi Share **5.4.2 veya 5.4.4** kurulu olmalı; ZIP Mi Share APK içermez ve yamalamaz.
2. Eski XAirDrop'u kapatıp stok sürücüyle yeniden başlatın.
3. Güncel ZIP'i KernelSU/SukiSU'dan kurup normal sistem güç menüsüyle yeniden başlatın.
4. Wi-Fi/Bluetooth açıkken Mi Share → Apple cihazları sayfasını açın.
   Normal kapatınca Wi-Fi geri döner.

Preinit desteği gerekir. Her oturumda ZIP kurulumu veya Action gerekmez.
Galeri için ayrı MiIntentResolver yaması korunur. **IPA KAPALI - TEŞHİS** yapılandırmasıdır.

[Kurulum, test ayrıntıları, kurtarma ve log](releases/1.2-test/README.md) ·
[Türkçe kısa kullanım notu](releases/1.2-test/KULLANIM-TR.txt) ·
[Eski 1.0 beta](https://github.com/Leekin2/XAirDrop/releases/tag/v1.0)

## Destek

[@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle)
· [HyperVoltron](https://t.me/HyperVoltron).

## English

Latest: **1.2 test**, using the original installed Mi Share 5.4.2/5.4.4 APK.
Xiaomi 15 Ultra session/close/Wi-Fi-return/normal-reboot autostart tests passed;
Xiaomi 15 hardware validation and iPhone discovery/transfer on this unpatched
variant remain pending. See the release notes for the exact test scope and kernel.
No LSPosed/Xposed; separate Gallery resolver patch retained.

## Credits

Qualcomm CLO WLAN.LA.1.0.r1-09900-pakala.0, Google Wonder 3.6.5,
[Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), the supplied MiAirDrop
firmware/controller reference, and Xiaomi's services/app binaries. LICENSE and
per-file upstream notices apply. Historical project source remains in this
repository. The current local development tree is not included in this release.
