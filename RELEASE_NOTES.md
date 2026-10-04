# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.2.2 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.2.2
# Aciklama: Legacy Docker runtime ayrimi ve surum-drift guvencesini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.2.2

Bu patch surumu v1.2.1 sonrasinda tamamlanan legacy Docker runtime ayrimini resmi surume dahil eder ve release/version tutarliligini CI seviyesinde korur.

## Fixed

Legacy Dockerfile.compat image'lari modern Apache OFBiz image'lariyla ayni entrypoint modeline sahip degildir. v1.2.2 ile:

- Legacy compat container'a modern OFBIZ_ADMIN_PASSWORD ve OFBIZ_DATA_LOAD davranisi zorla uygulanmaz.
- Modern Apache volume mountlari legacy compat image'a zorla eklenmez.
- Legacy compat run yolu preloaded demo varyantini zorunlu tutar.
- 17.12.09 image icindeki Java 8 dogrulanir.
- Gercek container /webtools HTTPS endpoint'i ile smoke test edilir.

## Release integrity

CI artik VERSION degerinin mevcut Git tag'i ile commit seviyesinde tutarli olup olmadigini kontrol eder.

Ornegin v1.2.2 zaten bir committe yayinlanmissa, VERSION hala 1.2.2 iken yeni bir main commit CI'dan gecemez. Yeni degisiklik icin 1.2.3 veya uygun sonraki surume bump gerekir.

Bu sayede GitHub Release, tag ve main kodu arasinda sessiz surum drift'i engellenir.

## Validation

- Statik mimari, Bash syntax ve ShellCheck.
- 17.12.09 + Temurin 8 + Gradle runtime matrisi.
- 18.12.19 + Temurin 8 + Gradle runtime matrisi.
- 24.09.07 + Temurin 17 + Gradle runtime matrisi.
- Gercek Apache ZIP + SHA-512 dogrulamasi.
- Doctor smoke.
- 17.12.09 legacy compat Docker demo build + HTTPS smoke.
- 24.09.07 resmi Docker HTTPS smoke.
