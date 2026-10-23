# XAirDrop

**AirDrop between iPhone and Xiaomi 15 / Xiaomi 15 Ultra, through Xiaomi Share.**
A KernelSU module. No LSPosed.

By [Leekin2](https://github.com/Leekin2) and [mertcqnkld](https://github.com/mertcqnkld).

[Türkçe açıklama aşağıda](#türkçe)

> ⚠️ **Only for the Xiaomi 15 (dada) and Xiaomi 15 Ultra (xuanyuan).** It replaces the Wi-Fi
> driver with kernel modules built for this exact kernel. Do not install it on any other phone.

## How it works
Xiaomi added AirDrop to Xiaomi Share on the Xiaomi 18 Pro Max ("Transfer to and from Apple
devices"). The Xiaomi 15 family has the same chip family but not the Wi-Fi driver support
(AWDL), the service or the app version. XAirDrop brings them together, in RAM only, after boot:

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

All of this starts by itself about a minute after boot; the AirDrop radio only runs while the
Apple share screen is open. Nothing is written to the system partitions, and removing the module
and rebooting puts the stock driver and apps back.

## Requirements
- Xiaomi 15 or Xiaomi 15 Ultra, HyperOS 4, kernel `6.6.118-android15-8`
- KernelSU / SukiSU (root)
- **Xiaomi Share (MIShare) 5.4.2** from the Xiaomi 18 Pro Max, installed over the built-in one
  (attached to the release). The patches are applied only to this exact APK.
- Bluetooth on; Wi-Fi on (it may be connected to a network)

Tested:
- Xiaomi 15, OS4.0.0.61.XOCCNXM (EU-style ROM): iPhone found and files sent to it with Wi-Fi
  connected
- Xiaomi 15 Ultra, OS4.0.0.18.XOACNXM (China ROM): radio, service, patches and Wi-Fi pause
  work; not yet tested with an iPhone nearby
- **Receiving from an iPhone does not work yet**: the iPhone does not list the Xiaomi phone.
  Until it is fixed, send from the iPhone with Xiaomi's *Xiaomi Interconnectivity* iOS app.

If an earlier test build (`xairdrop_test`) is installed, XAirDrop removes it at the next reboot.

## Install
1. Install `MIShare-5.4.2.apk` from the release.
2. Install `XAirDrop-vX.zip` in KernelSU / SukiSU and reboot.
3. That's it: about a minute after boot the module's description in KernelSU shows
   "✅ AirDrop is on". If it shows ❌ or ⚠️ (for example the hotspot was on), press the module's
   **action button** to start it by hand.
4. On a global / EU-style ROM, if Xiaomi Share does not show up in the share sheet, run once as
   root: `setprop persist.sys.sharesheet.region 2`

## Use
- **Send:** Gallery → Share → **Transfer to and from Apple devices**. Keep the screen open until
  the iPhone shows up (iPhone: AirDrop → *Everyone for 10 Minutes*, unlocked, nearby).
- **Receive:** not working yet (see Known limits).
- Wi-Fi disconnects while the Apple screen is open and comes back when you leave it. Internet
  goes over mobile data in the meantime.

## Known limits
- AirDrop is not available during the first minute after boot. To start it only by hand, run
  once as root `touch /data/adb/xairdrop/no-autostart`.
- If the phone restarts while AirDrop is starting, the next boot skips the automatic start; press
  the action button.
- Receiving with AirDrop from an iPhone does not work yet; use the Xiaomi Interconnectivity
  iOS app on the iPhone for now.
- Wi-Fi Internet pauses during AirDrop.
- The share-sheet fix only applies to the Xiaomi 15 Ultra OS4.0.0.18 share sheet; on other
  builds share from another app, or use the `persist.sys.sharesheet.region 2` setting.

## Troubleshooting
For a full test log, run once as root `touch /data/adb/xairdrop/debug`, press the action button
and keep the Apple screen open: it records 90 seconds of Xiaomi Share logs to
`Download/xairdrop-test-*.log`. Remove the file to turn it off.

## Uninstall
Remove the module in KernelSU and reboot. If an AirDrop session was still open, the Wi-Fi network
it paused is turned back on.

## Support
- Telegram: [@emcleek](https://t.me/emcleek)
- XApps for HyperOS: [t.me/Xgooogle](https://t.me/Xgooogle)
- HyperVoltron channel: [t.me/HyperVoltron](https://t.me/HyperVoltron)

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

Geliştiriciler: [Leekin2](https://github.com/Leekin2) ve [mertcqnkld](https://github.com/mertcqnkld).

> ⚠️ **Yalnızca Xiaomi 15 (dada) ve Xiaomi 15 Ultra (xuanyuan) için.** Wi-Fi sürücüsünü bu
> çekirdeğe göre hazırlanmış modüllerle değiştirir. Başka bir telefona kurmayın.

### Nasıl çalışır
Xiaomi, Xiaomi 18 Pro Max'te Xiaomi Share'e AirDrop ekledi ("Transfer to and from Apple
devices"). Xiaomi 15 serisinde Wi-Fi sürücüsü desteği (AWDL), servis ve uygulama sürümü yok.
XAirDrop bunları açılıştan sonra, yalnızca RAM'de bir araya getirir:

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

Hepsi açılıştan yaklaşık bir dakika sonra kendiliğinden başlar; AirDrop radyosu yalnızca Apple
paylaşım ekranı açıkken çalışır. Sistem bölümlerine hiçbir şey yazılmaz; modülü kaldırıp yeniden
başlatınca stok sürücü ve uygulamalar geri gelir.

### Gereksinimler
- Xiaomi 15 veya Xiaomi 15 Ultra, HyperOS 4, çekirdek `6.6.118-android15-8`
- KernelSU / SukiSU (root)
- Xiaomi 18 Pro Max'in **Xiaomi Share (MIShare) 5.4.2** sürümü, yerleşik olanın üzerine kurulu
  (sürümde ekli). Yamalar yalnızca bu APK'ya uygulanır.
- Bluetooth açık; Wi-Fi açık (bir ağa bağlı olabilir)

Test edildi: Xiaomi 15 (iPhone'a gönderim, Wi-Fi bağlıyken de); Xiaomi 15 Ultra (iPhone olmadan:
radyo, servis, yamalar, Wi-Fi duraklatma). **iPhone'dan alma henüz çalışmıyor:** iPhone, Xiaomi'yi
listede göstermiyor. Düzelene kadar iPhone'dan Xiaomi'nin *Xiaomi Interconnectivity* uygulamasıyla gönderin.
Eski test modülü (`xairdrop_test`) kuruluysa XAirDrop onu sonraki yeniden başlatmada kaldırır.

### Kurulum
1. Sürümdeki `MIShare-5.4.2.apk`'yı kur.
2. `XAirDrop-vX.zip`'i KernelSU / SukiSU'dan kur ve yeniden başlat.
3. Bu kadar: açılıştan yaklaşık bir dakika sonra KernelSU'da modül açıklamasında "✅ AirDrop açık"
   yazar. ❌ ya da ⚠️ görürsen (örneğin hotspot açıktı) modülün **Action** düğmesine basarak elle başlat.
4. Global / EU benzeri ROM'da Xiaomi Share paylaşım menüsünde çıkmıyorsa root ile bir kez:
   `setprop persist.sys.sharesheet.region 2`

### Kullanım
- **Gönderme:** Galeri → Paylaş → **Transfer to and from Apple devices**. iPhone çıkana kadar
  ekranı açık tut (iPhone: AirDrop → *Herkes (10 dakika)*, kilidi açık, yakında).
- **Alma:** henüz çalışmıyor (Bilinen sınırlar'a bakın).
- Apple ekranı açıkken Wi-Fi kopar, ekrandan çıkınca geri gelir; arada internet mobil veriden gider.

### Bilinen sınırlar
- Açılıştan sonraki ilk dakika AirDrop hazır değildir. Yalnızca elle başlatmak için root ile bir kez:
  `touch /data/adb/xairdrop/no-autostart`
- Telefon AirDrop başlatılırken yeniden başlarsa, sonraki açılışta otomatik başlatma atlanır; Action'a basın.
- iPhone'dan AirDrop ile alma henüz çalışmıyor; şimdilik iPhone'da Xiaomi Interconnectivity uygulamasını kullanın.
- AirDrop sırasında Wi-Fi interneti durur.
- Paylaşım menüsü düzeltmesi yalnızca Xiaomi 15 Ultra OS4.0.0.18 içindir; diğer sürümlerde başka
  bir uygulamadan paylaş ya da `persist.sys.sharesheet.region 2` ayarını kullan.

### Destek
- Telegram: [@emcleek](https://t.me/emcleek)
- XApps for HyperOS: [t.me/Xgooogle](https://t.me/Xgooogle)
- HyperVoltron kanalı: [t.me/HyperVoltron](https://t.me/HyperVoltron)

### Sorun giderme
Ayrıntılı test logu için root ile bir kez `touch /data/adb/xairdrop/debug` çalıştırın, Action'a basın ve
Apple ekranını açık tutun: Xiaomi Share'in 90 saniyelik kaydı `Download/xairdrop-test-*.log` dosyasına yazılır.
Kapatmak için dosyayı silin.

### Teşekkürler
- [OPAirDrop](https://github.com/Weverses/OPAirDrop) (Weverses): AWDL Wi-Fi sürücüsü ve `wonder`
  modülleri. İşin en zor kısmı; o olmasa XAirDrop olmazdı.
- [mertcqnkld](https://github.com/mertcqnkld): Xiaomi 15'te testler ve son iki düzeltme: Bluetooth duyuru biçimi ve AirDrop
  sırasında Wi-Fi'nin duraklatılması.
