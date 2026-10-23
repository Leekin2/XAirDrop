# XAirDrop

**AirDrop between iPhone and Xiaomi 15 / Xiaomi 15 Ultra, through Xiaomi Share.**
A KernelSU module. No LSPosed.

[Türkçe açıklama aşağıda](#türkçe)

> ⚠️ **Only for the Xiaomi 15 (dada) and Xiaomi 15 Ultra (xuanyuan).** It replaces the Wi-Fi
> driver with kernel modules built for this exact kernel. Do not install it on any other phone.

## How it works
Xiaomi added AirDrop to Xiaomi Share on the Xiaomi 18 Pro Max ("Transfer to and from Apple
devices"). The Xiaomi 15 family has the same chip family but not the Wi-Fi driver support
(AWDL), the service or the app version. XAirDrop brings them together, in RAM only, when you
press the module's action button:

- **Wi-Fi driver with AWDL**: the OnePlus 13 AirDrop kernel modules from
  [OPAirDrop](https://github.com/Weverses/OPAirDrop) (same SM8750 platform and kernel), adapted
  to Xiaomi's kernel (symbol CRCs, Wi-Fi config `monitor_mode_concurrency=1`), plus a small
  `wonder_sysctl` module that provides the switch Xiaomi Share looks for.
- **Xiaomi's AirDrop service** (`DomesticXOsComm`, `libxos`) from the Xiaomi 18 Pro Max ROM,
  registered with the system for this boot.
- **Xiaomi Share 5.4.2** (from the Xiaomi 18 Pro Max), patched in place for this boot:
  - the AirDrop Bluetooth advertisement in Apple's format, so iPhones wake up and answer
  - Wi-Fi is paused while the Apple share screen is open (the radio cannot listen on the AirDrop
    channel while it is connected to a network) and reconnected when you leave it
  - the AirDrop network is registered by a root helper, because the Xiaomi 15 ROM does not give
    Xiaomi Share the permission it needs for that
  - no region / international ROM limits
- **Share sheet** (Xiaomi 15 Ultra OS4.0.0.18): sharing from Gallery opens the Apple screen
  instead of looping back to the share sheet.

Nothing is written to the system partitions, nothing runs at boot except a Wi-Fi recovery check,
and a reboot puts the stock driver and apps back.

## Requirements
- Xiaomi 15 or Xiaomi 15 Ultra, HyperOS 4, kernel `6.6.118-android15-8`
- KernelSU / SukiSU (root)
- **Xiaomi Share (MIShare) 5.4.2** from the Xiaomi 18 Pro Max, installed over the built-in one
  (attached to the release). The patches are applied only to this exact APK.
- Bluetooth on; Wi-Fi on (it may be connected to a network)

Tested:
- Xiaomi 15, OS4.0.0.61.XOCCNXM (EU-style ROM): iPhone found and files sent to it, also with
  Wi-Fi connected
- Xiaomi 15 Ultra, OS4.0.0.18.XOACNXM (China ROM): radio, service, patches and Wi-Fi pause
  work; not yet tested with an iPhone nearby
- Receiving from an iPhone has not been confirmed yet.

## Install
1. Install `MIShare-5.4.2.apk` from the release.
2. Install `XAirDrop-vX.zip` in KernelSU / SukiSU and reboot.
3. **After every reboot**, turn off the hotspot and press the module's **action button** once.
   It loads the AirDrop radio and writes a log to `Download/xairdrop-test-*.log`.
4. On a global / EU-style ROM, if Xiaomi Share does not show up in the share sheet, run once as
   root: `setprop persist.sys.sharesheet.region 2`

## Use
- **Send:** Gallery → Share → **Transfer to and from Apple devices**. Keep the screen open until
  the iPhone shows up (iPhone: AirDrop → *Everyone for 10 Minutes*, unlocked, nearby).
- **Receive:** open **Receive files from Apple devices** on the same screen and keep it open;
  send from the iPhone with AirDrop.
- Wi-Fi disconnects while the Apple screen is open and comes back when you leave it. Internet
  goes over mobile data in the meantime.

## Known limits
- The action button is needed after every reboot (the radio is never loaded at boot).
- The phone is visible to iPhones only while the receive page is open, like on the 18 Pro Max.
- Wi-Fi Internet pauses during AirDrop.
- The share-sheet fix only applies to the Xiaomi 15 Ultra OS4.0.0.18 share sheet; on other
  builds share from another app, or use the `persist.sys.sharesheet.region 2` setting.

## Uninstall
Remove the module in KernelSU and reboot. If an AirDrop session was still open, the Wi-Fi network
it paused is turned back on.

## Credits
- [OPAirDrop](https://github.com/Weverses/OPAirDrop) by Weverses: the AWDL Wi-Fi driver and
  `wonder` modules for the OnePlus 13. The hardest part of all of this; XAirDrop would not exist
  without it.
- [mertcqnkld](https://github.com/mertcqnkld): testing on the Xiaomi 15 and the two last fixes: the Bluetooth advertisement
  format and pausing Wi-Fi during AirDrop.
- Xiaomi, for AirDrop in Xiaomi Share on the Xiaomi 18 Pro Max.

## Source
- `module/`: the KernelSU module scripts (binaries are only in the release zip)
- `patches/`: builds the patched Xiaomi Share and share sheet APKs and the root helper
  (`python build.py <out>`; needs apktool, Android SDK build-tools, the original APKs)
- `kmod/wonder_sysctl/`: the `wonder_enable` sysctl module (GitHub Actions build)
- `xosclient/`: small client that keeps Xiaomi's AirDrop service alive
- `tools/`: kernel module CRC / layout fixers, `libxos` patcher

License: GPL-3.0 (the kernel modules are derived from OPAirDrop, GPL-3.0). Xiaomi's binaries in
the release belong to Xiaomi.

---

## Türkçe

**iPhone ile Xiaomi 15 / Xiaomi 15 Ultra arasında AirDrop, Xiaomi Share üzerinden.**
Bir KernelSU modülü. LSPosed gerekmez.

> ⚠️ **Yalnızca Xiaomi 15 (dada) ve Xiaomi 15 Ultra (xuanyuan) için.** Wi-Fi sürücüsünü bu
> çekirdeğe göre hazırlanmış modüllerle değiştirir. Başka bir telefona kurmayın.

### Nasıl çalışır
Xiaomi, Xiaomi 18 Pro Max'te Xiaomi Share'e AirDrop ekledi ("Transfer to and from Apple
devices"). Xiaomi 15 serisinde Wi-Fi sürücüsü desteği (AWDL), servis ve uygulama sürümü yok.
XAirDrop bunları, modülün Action düğmesine bastığında, yalnızca RAM'de bir araya getirir:

- **AWDL destekli Wi-Fi sürücüsü:** [OPAirDrop](https://github.com/Weverses/OPAirDrop)'un
  OnePlus 13 modülleri (aynı SM8750 platformu ve çekirdeği), Xiaomi çekirdeğine uyarlanmış hâli,
  artı Xiaomi Share'in aradığı anahtarı sağlayan küçük `wonder_sysctl` modülü.
- **Xiaomi'nin AirDrop servisi** (`DomesticXOsComm`, `libxos`), Xiaomi 18 Pro Max ROM'undan.
- **Xiaomi Share 5.4.2**, o açılış için yamalanır:
  - AirDrop Bluetooth duyurusu Apple'ın biçiminde, böylece iPhone'lar uyanıp cevap verir
  - Apple ekranı açıkken Wi-Fi bağlantısı duraklatılır (bağlıyken radyo AirDrop kanalını
    dinleyemiyor), ekrandan çıkınca geri bağlanır
  - AirDrop ağı root yardımcısıyla kaydedilir (Xiaomi 15 ROM'u Xiaomi Share'e bu izni vermiyor)
  - bölge / global ROM kısıtlamaları yok
- **Paylaşım menüsü** (Xiaomi 15 Ultra OS4.0.0.18): Galeri'den paylaşınca Apple ekranı açılır,
  menüye geri dönme döngüsü olmaz.

Sistem bölümlerine hiçbir şey yazılmaz; açılışta yalnızca Wi-Fi kurtarma kontrolü çalışır.
Yeniden başlatınca stok sürücü ve uygulamalar geri gelir.

### Gereksinimler
- Xiaomi 15 veya Xiaomi 15 Ultra, HyperOS 4, çekirdek `6.6.118-android15-8`
- KernelSU / SukiSU (root)
- Xiaomi 18 Pro Max'in **Xiaomi Share (MIShare) 5.4.2** sürümü, yerleşik olanın üzerine kurulu
  (sürümde ekli). Yamalar yalnızca bu APK'ya uygulanır.
- Bluetooth açık; Wi-Fi açık (bir ağa bağlı olabilir)

### Kurulum
1. Sürümdeki `MIShare-5.4.2.apk`'yı kur.
2. `XAirDrop-vX.zip`'i KernelSU / SukiSU'dan kur ve yeniden başlat.
3. **Her yeniden başlatmadan sonra** hotspot'u kapatıp modülün **Action** düğmesine bir kez bas.
4. Global / EU benzeri ROM'da Xiaomi Share paylaşım menüsünde çıkmıyorsa root ile bir kez:
   `setprop persist.sys.sharesheet.region 2`

### Kullanım
- **Gönderme:** Galeri → Paylaş → **Transfer to and from Apple devices**. iPhone çıkana kadar
  ekranı açık tut (iPhone: AirDrop → *Herkes (10 dakika)*, kilidi açık, yakında).
- **Alma:** Aynı ekranda **Receive files from Apple devices**'ı açık tut; iPhone'dan AirDrop ile
  gönder.
- Apple ekranı açıkken Wi-Fi kopar, ekrandan çıkınca geri gelir; arada internet mobil veriden gider.

### Bilinen sınırlar
- Her yeniden başlatmadan sonra Action gerekir.
- Telefon iPhone'lara yalnızca alma sayfası açıkken görünür (18 Pro Max'te de böyle).
- AirDrop sırasında Wi-Fi interneti durur.
- Paylaşım menüsü düzeltmesi yalnızca Xiaomi 15 Ultra OS4.0.0.18 içindir; diğer sürümlerde başka
  bir uygulamadan paylaş ya da `persist.sys.sharesheet.region 2` ayarını kullan.

### Teşekkürler
- [OPAirDrop](https://github.com/Weverses/OPAirDrop) (Weverses): AWDL Wi-Fi sürücüsü ve `wonder`
  modülleri. İşin en zor kısmı; o olmasa XAirDrop olmazdı.
- [mertcqnkld](https://github.com/mertcqnkld): Xiaomi 15'te testler ve son iki düzeltme: Bluetooth duyuru biçimi ve AirDrop
  sırasında Wi-Fi'nin duraklatılması.
