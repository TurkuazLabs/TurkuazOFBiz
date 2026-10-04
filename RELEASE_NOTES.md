# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.2.1 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.2.1
# Aciklama: Legacy Docker compat Java major aktarim duzeltmesini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.2.1

Bu patch surumu eski OFBiz release'lerinin local Docker build yolundaki Java major aktarimini duzeltir.

## Fixed

17.12 serisinde resmi Dockerfile bulunmadigi icin TurkuazOFBiz Dockerfile.compat kullanir. Compat Dockerfile varsayilan olarak Java 17 ile basladigindan, Java 8 gerektiren 17.12 local build'i yanlis JDK ile olusturulabiliyordu.

v1.2.1 ile:

- Legacy Gradle wrapper'in bekledigi shasum komutu sha1sum'a normalize edilir.
- Docker build gecici dizin cleanup'i hata durumunda da guvenli calisir.
- Compat Docker build Java major degerini version resolver'dan alir.
- 17.12.x -> Java 8
- 18.12.x -> Java 8
- 24.09.x -> Java 17
- Snapshot hedefleri -> ilgili snapshot Java mapping'i

Compat image'lar label ile algilanir. Modern Apache Docker entrypoint'ine ait OFBIZ_ADMIN_PASSWORD, OFBIZ_DATA_LOAD ve modern volume davranisi eski 17.12 image'ina zorla uygulanmaz. Legacy container icin preloaded demo varyanti kullanilir.

Resmi Dockerfile mevcutsa Apache'in kendi Dockerfile'i degistirilmeden kullanilmaya devam eder.

## Validation

CI Docker Java mapping'lerini statik olarak kontrol eder. Ayrica 17.12.09 icin gercek Dockerfile.compat demo image loadAll ile build edilir, image icindeki Java'nin 1.8 oldugu dogrulanir, container baslatilir ve /webtools HTTPS endpoint'i smoke test edilir. Mevcut release runtime matrisi, Doctor ve modern Docker smoke testleri de korunur.
