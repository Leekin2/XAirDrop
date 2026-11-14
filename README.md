# XAirDrop

Seçili Xiaomi 15 / 15 Ultra sistemlerinde Xiaomi Share üzerinden Apple aygıtlarıyla paylaşım için root modülü. Geliştirenler: [Leekin2](https://github.com/Leekin2) ve [mertcqnkld](https://github.com/mertcqnkld). LSPosed/Xposed gerekmez.

**[İndir: XAirDrop 1.2.1 test — code155](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2.1-test)**

Yeni doğrulanan profil: **Xiaomi 15 Ultra, OS4.0.3.0.XOACNXM**, kernel `6.6.118-android15-8-gf72a02f47f4b-abogki551678766-4k`. Stok WLAN/MAC/bağımlılık dosyalarının tam kimlikleri de kontrol edilir. Eski kernel/profiller korunur; bu yayımda yeniden cihaz testinden geçirilmedi.

Mi Share 5.5.0 orijinal APK desteği, preinit gerektirmeyen başlangıç, alım oturumu ve temiz kapanış iyileştirmeleri, yaklaşık 8 MiB kayıpsız paket. 5.4.4 için sürüme özel Ask düzeltmesi bulunur. OS4.0.3.0'ın doğrulanan stok Galeri bileşeni değiştirilmez.

**Test sürümü; IPA kapalı teşhis yapılandırması.** API10, alım oturumu, Wi-Fi'ye dönüş ve yeniden başlatma testleri korunmuş code154 çalışma dosyalarıyla geçti. Code155 ZIP'i yerelde doğrulandı; telefona ayrıca kurulmadı. **Bu ROM'da iPhone keşfi, gerçek dosya aktarımı ve hız henüz doğrulanmadı.**

## Kullanım

1. Uygun orijinal Mi Share kurulu olmalı; APK pakete dahil değildir.
2. ZIP'i KernelSU/SukiSU üzerinden yükleyip yeniden başlatın. Çözülmemiş hata korumaları inceleme gerektirir; otomatik silinmez.
3. Wi-Fi ve Bluetooth'u açıp Mi Share'in Apple alım ekranını açık tutun. Gelen isteği telefonda kabul edin.
4. Ekranı normal kapatınca Wi-Fi bağlantısının geri döndüğünü kontrol edin.

[Değişiklikler, tam uyumluluk ve test sınırları](releases/1.2.1-test/README.md) · [Kısa kullanım](releases/1.2.1-test/KULLANIM-TR.txt) · [Önceki v1.2-test](https://github.com/Leekin2/XAirDrop/releases/tag/v1.2-test)

Sorun halinde modülü devre dışı bırakıp yeniden başlatın. Aday sürücüyü canlı sökmeyin. Günlük: `su -c "sh /data/adb/modules/xairdrop/collect-log.sh"`.

## Destek ve katkılar

[@emcleek](https://t.me/emcleek) · [XApps for HyperOS](https://t.me/Xgooogle) · [HyperVoltron](https://t.me/HyperVoltron).

Qualcomm CLO WLAN, Google Wonder 3.6.5, [Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), MiAirDrop referansı ve Xiaomi bileşenleri. LICENSE ve dosyalardaki upstream bildirimleri geçerlidir. Özel geliştirme ağacı ve cihaz günlükleri yayıma dahil değildir.
