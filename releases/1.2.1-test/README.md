# XAirDrop 1.2.1 test — code155

Önceki GitHub sürümü: **v1.2-test / code130**. Bu sürüm, daha sonra geliştirilen code154 çalışma dosyalarını ve doğrulanan HyperOS 4.0.3 profilini tek test paketinde toplar.

## Code130'a göre değişiklikler

- **Xiaomi 15 Ultra / OS4.0.3.0.XOACNXM profili:** `6.6.118-android15-8-gf72a02f47f4b-abogki551678766-4k` kerneli ve bu ROM'un stok QCA/MAC/bağımlılık dosyaları tam kimlikleriyle denetlenir. Kernel adı tek başına yeterli değildir.
- **Mi Share 5.5.0 desteği:** doğrulanan orijinal APK ve gerekli iki ağ izni kontrol edilir. 5.5.0 APK'sı değiştirilmez ve pakete eklenmez. Önceki 5.4.2/5.4.4 profilleri korunur; 5.4.4 için sürüme özel Ask düzeltmesi bulunur.
- **Başlangıç ve kapanış:** firmware seçimi `post-fs-data` aşamasına taşındı; preinit bağımlılığı kaldırıldı. Otomatik başlangıç, temiz kapanış, yarım kalan oturum korumaları ve sınırlı yeniden deneme akışı geliştirildi.
- **Alım oturumu:** Action, çalışan sistemde yeni sürücü denemesi başlatmak yerine stok Apple alım ekranını açar. Eş kaydı başarısızlığında geri alma ve kapanıştan sonra yeni iş kabul etmeme düzeltmeleri içerir.
- **Galeri:** eski ROM'larda sürüme göre doğrulanan düzeltme korunur. OS4.0.3.0'ın tam kimliği doğrulanan orijinal paylaşım bileşeni AirDrop hedefini zaten ele aldığı için eski Galeri yaması uygulanmaz.
- **Daha küçük paket:** XZ ile kayıpsız açılan yaklaşık **8,0 MiB** ZIP; eski yayımdaki yaklaşık 22 MiB pakete göre küçüldü. Kurulumdan sonra dosyalar normal biçimde kullanılır.

## Doğrulananlar ve sınırlar

14 Kasım 2026 tarihinde Xiaomi 15 Ultra / OS4.0.3.0 üzerinde, bu pakette korunan onarılmış **code154 çalışma dosyalarıyla**:

- Beş modülün toplam **1.006 sembol bağımlılığı** için eşleşme kontrolü; 16 yapıda **541 ortak alanın** yerleşim kontrolü geçti.
- Sürücü/Wonder **API10**, üç alım oturumunun açılması ve temiz kapanması, Wi-Fi'nin IP alarak geri dönmesi geçti.
- Temiz yeniden başlatmadan sonra otomatik başlangıç geçti. Son oturum 35 saniyelik örnekleme boyunca RUNNING kaldı; firmware çökme kaydı görülmedi.

**Code155 ZIP'i ayrıca telefona kurulmadı.** Yerelde ZIP/XZ/tar açılma, tüm dış/iç SHA256 değerleri, dosya listesi, sürüm bilgisi ve shell sözdizimi doğrulandı. Kernel modülleri, firmware ve XOS dosyaları test edilen code154 ile birebir aynıdır. Code155 ayrıca sürüm/paket notlarını ve doğrulanan stok Galeri bileşeni için gereksiz yamayı atlama kontrolünü içerir.

**Bu ROM'da iPhone keşfi, iki yönde gerçek dosya aktarımı ve hız henüz doğrulanmadı.** Eski ROM profilleri korunur; bu yayımda yeniden cihaz testinden geçirilmedi. Diğer cihazlar veya aynı adlı farklı sürücü paketleri desteklenmiş sayılmaz. Sürücü hâlâ **IPA KAPALI / TEŞHİS** yapılandırmasındadır.

## Kurulum ve kullanım

1. Uygun orijinal Mi Share sürümü kurulu olmalı. İlk kurulumda veya sağlıksız eski kurulumda stok sürücüyle açılış gerekir.
2. ZIP'i KernelSU/SukiSU modül yöneticisinden yükleyip normal şekilde yeniden başlatın. Sağlıklı etkin kurulumda güncelleme bir sonraki açılış için hazırlanabilir. Diğer root çözümleri için yardımcı yollar bulunur; bu yayımda cihaz testi yapılmadı.
3. Wi-Fi ve Bluetooth'u açın. Mi Share'in Apple aygıtlarından alma ekranını açık tutun. İstek gelirse dosyayı telefonda kabul edin.
4. Ekranı normal kapattığınızda Wi-Fi bağlantısının geri geldiğini kontrol edin.

Çözülmemiş sürücü/kapanış korumaları otomatik silinmez. Bugün cihazdaki eski, incelenmiş kapanış kaydı ayrıca doğrulanarak arşivlendi; bu ZIP aynı işlemi tüm kullanıcılara otomatik uygulamaz. Sorun halinde modülü devre dışı bırakıp yeniden başlatın; aday sürücüyü canlı sökmeyin. Günlük toplama: `su -c "sh /data/adb/modules/xairdrop/collect-log.sh"`.

## Dosyalar

- `XAirDrop-1.2.1-test.zip` — kurulabilir modül.
- `XAirDrop-1.2.1-test.zip.sha256` — sağlama toplamı.
- `KULLANIM-TR.txt` — kısa kullanım ve test sınırları.

SHA256: `6534ab6c104c3e4afad254f5dc29ad972b476059a396c5634afdeeabb3cb2be3`

Geliştirenler: [Leekin2](https://github.com/Leekin2) ve [mertcqnkld](https://github.com/mertcqnkld). Qualcomm CLO WLAN, Google Wonder 3.6.5, [Weverses/OPAirDrop](https://github.com/Weverses/OPAirDrop), MiAirDrop referansı ve Xiaomi bileşenlerine teşekkürler. Özel geliştirme deposu veya cihaz günlükleri bu yayımda paylaşılmadı.
