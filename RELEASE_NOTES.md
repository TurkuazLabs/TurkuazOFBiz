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

- Compat Docker build Java major degerini version resolver'dan alir.
- 17.12.x -> Java 8
- 18.12.x -> Java 8
- 24.09.x -> Java 17
- Snapshot hedefleri -> ilgili snapshot Java mapping'i

Resmi Dockerfile mevcutsa Apache'in kendi Dockerfile'i degistirilmeden kullanilmaya devam eder.

## Validation

CI Docker Java mapping'lerini statik olarak kontrol eder. Ayrica 17.12.09 icin gercek Dockerfile.compat runtime image build edilir ve image icindeki Java'nin 1.8 oldugu dogrulanir. Mevcut release runtime matrisi, Doctor ve modern Docker smoke testleri de korunur.
