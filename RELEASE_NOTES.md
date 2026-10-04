# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.0.1 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.0.1
# Aciklama: Apache release checksum uyumluluk duzeltmesini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.0.1

Bu patch surumu sabit Apache OFBiz release ZIP kurulumundaki SHA-512 dogrulama hatasini duzeltir.

## Fixed

Apache OFBiz resmi .sha512 dosyalari GNU sha512sum kontrol formatindan farkli olarak Apache filename-colon-hash formatini kullanir. v1.0.0 release downloader bu dosyayi dogrudan sha512sum --check ile okumaya calistigi icin release ZIP kurulumu hata verebiliyordu.

v1.0.1 ile:

- Apache filename-colon-hash checksum formati desteklenir.
- GNU hash-filename checksum formati da desteklenmeye devam eder.
- Gercek archive hash'i hesaplanip normalize edilmis beklenen SHA-512 ile karsilastirilir.
- Hata durumunda gecici download dizini temizlenir.

## Compatibility

Komutlarda veya klasor yapisinda kirici degisiklik yoktur.

~~~bash
sudo bash controllers/ofbiz.sh release install 24.09.07
sudo bash controllers/ofbiz.sh release install 18.12.19
~~~

## Validation

- Apache 24.09.07 resmi SHA-512 formati parser fixture'i ile dogrulandi.
- Bash syntax ve ShellCheck kontrolleri korunur.
- Gercek 24.09.07 Docker HTTPS smoke testi korunur.
- release22.01 Dockerfile build check korunur.
