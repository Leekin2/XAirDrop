# XAirDrop 1.2 test — Mi Share yamasız (code130)

Xiaomi 15 ve Xiaomi 15 Ultra için Xiaomi Share üzerinden Apple cihazlarıyla
paylaşım modülü. KernelSU/SukiSU içindir; LSPosed/Xposed kullanılmaz.
Bu bir **test / ön sürümdür**. Sürücü **IPA KAPALI - TEŞHİS** yapılandırmasındadır.

## Cihaz ve ROM

| Cihaz | ROM | Durum |
|---|---|---|
| Xiaomi 15 Ultra (`xuanyuan`) | `OS4.0.0.18.XOACNXM` | **Test edildi:** oturum, normal kapanış, Wi-Fi dönüşü ve yeniden başlatma sonrası otomatik çalışma geçti. |
| Xiaomi 15 (`dada`) | `OS4.0.0.61.XOCCNXM` | Güncel cihaz profili eklendi; bu cihazda fiziksel test bekleniyor. |

Tam kernel her iki profil için:
`6.6.118-android15-8-gb9cc6ec16bc8-abogki536571621-4k`.
Kurulum ayrıca stok WLAN/mac80211 dosya ve çalışan sürücü kimliklerini denetler.
Farklı cihaz/ROM/kernel veya farklı stok sürücüde firmware/sürücü değiştirilmeden
“desteklenmiyor” diyerek durur. Aynı kernel adı tek başına kurulum garantisi değildir.

## Değişiklikler

- Telefonda kurulu **orijinal Mi Share 5.4.2 veya 5.4.4** kullanılır. Mi Share APK'sı
  ZIP'te yoktur, değiştirilmez veya bind-mount edilmez.
- Gerekli iki ağ izni PRODUCT signature XML'iyle tanımlanır; gerçek izin kontrolü yapılır.
- Otomatik açılış, normal kapanış ve yeniden başlatma sonrası çalışma düzeltildi.
- Galeri paylaşım menüsü için ayrı **MiIntentResolver yaması korunur**.
- Qualcomm CLO passthru sürücüsü, Wonder 3.6.5/API10 ve FW2 yığını kullanılır.
- Modül yaklaşık **22 MiB**; önceki yamalı paketten yaklaşık **12,6 MiB** küçük.

## Test sonucu

**Xiaomi 15 Ultra'da test edildi:** orijinal Mi Share 5.4.4 ile iki oturum
62,92 ve 62,60 saniye açık kaldı. Normal kapanış, Wi-Fi/IP dönüşü, ping ve
normal sistem yeniden başlatması sonrası otomatik çalışma geçti. API10,
firmware `200c002e` ve self-peer yetkilendirmesi doğrulandı.

Bu fiziksel sonuçlar code129'a aittir. Yayımlanan code130 yalnız cihaz profili,
kurulum mesajı ve notlarını genişletir; sürücü/FW/XOS ve oturum/kapanış kodu
aynıdır. code130'un ayrıca telefona kurulumu yapılmadı. **82 bilgisayar
kontrolü geçti.**

**Bu yamasız varyantta iPhone keşif/gönderme/alma henüz test edilmedi.**
Önceki yamalı sürümün hızlı gönderim sonucu bu varyanta aktarım kanıtı sayılmaz.
Mi Share 5.4.2 için dosya kimliği kabul edilir; fiziksel test 5.4.4 ile yapıldı.

## Kurulum ve kullanım

1. Orijinal Mi Share 5.4.2 veya 5.4.4 telefonda kurulu olmalı.
2. Eski XAirDrop'u devre dışı bırakıp stok sürücüyle yeniden başlatın.
3. `XAirDrop-1.2-MiShare-Yamasiz-test.zip` dosyasını KernelSU/SukiSU'dan kurup
   normal sistem güç menüsüyle yeniden başlatın. Preinit desteği gerekir.
4. Wi-Fi ve Bluetooth açıkken Mi Share → Apple cihazları sayfasını açın.
   iPhone'da AirDrop → Herkes için 10 dakika açık olsun. Önce küçük bir fotoğrafla deneyin.
5. Apple sayfasını normal kapatın; Wi-Fi bağlantısının geri geldiğini kontrol edin.

Her açıp kapatmada modülü yeniden kurmak veya Action'a basmak gerekmez.
Diğer AirDrop/WLAN modülleriyle birlikte kullanmayın.

## Kurtarma ve log

Sorunda modülü devre dışı bırakıp yeniden başlatın. Aday sürücüyü canlı sökmeyin;
koruma kayıtlarını kör silmeyin. Açılış takılırsa telefonu kapatıp ses kısma basılı
açın; SukiSU güvenli moddan modülü devre dışı bırakın.

Root terminalde: `su -c "sh /data/adb/modules/xairdrop/collect-log.sh"`.
Log: `Download/xairdrop-1.2-test-*.log`. Destek için özel olarak gönderin;
herkese açık bir issue'ya eklemeden önce kişisel bilgileri kontrol edin.

## Geliştirenler ve destek

[Leekin2](https://github.com/Leekin2) · [mertcqnkld](https://github.com/mertcqnkld)

Telegram: [@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle)
· [HyperVoltron](https://t.me/HyperVoltron).

Kaynak/katkılar: Qualcomm CLO WLAN.LA.1.0.r1-09900-pakala.0, Google Wonder 3.6.5,
[Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), sağlanan MiAirDrop
firmware/denetleyici referansı ve Xiaomi servis/uygulama ikilileri.
Bu yayında modül ZIP’i ve kullanım belgeleri sunulur. Yerel geliştirme ağacı ve
QCA/WLAN kaynak arşivi bu yayına eklenmemiştir.

SHA256: `b2ba59f785fc0b203a3c888c70a7dc4de9bf764def82535a828c260ffb0a7c98`
