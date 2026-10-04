# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.2.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.2.0
# Aciklama: Desteklenen sabit OFBiz release serileri icin gercek runtime CI matrisini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.2.0

v1.2.0 destekledigimiz sabit OFBiz serilerini gercek release paketleri ve gercek Java surumleriyle CI seviyesinde dogrular.

## Release runtime matrix

CI artik asagidaki matrisi gercekten calistirir:

~~~text
OFBiz 17.12.09 -> Temurin JDK 8
OFBiz 18.12.19 -> Temurin JDK 8
OFBiz 24.09.07 -> Temurin JDK 17
~~~

Her hedef icin:

1. Resmi Apache ZIP indirilir.
2. Resmi SHA-512 dogrulanir.
3. TurkuazOFBiz Java Tool ile izole Temurin JDK indirilir ve SHA-256 dogrulanir.
4. JAVA_HOME sadece ilgili test icin ayarlanir.
5. OFBiz Gradle wrapper hazirlanir.
6. Gradle surumu calistirilir.
7. Gradle build script help gorevi ile yuklenir.

Bu test sadece katalogda bir surum bulunmasini degil, release paketinin secilen Java ile Gradle seviyesinde gercekten acilabildigini kontrol eder.

## Catalog verification

Apache'in resmi release/archive listeleri ile TurkuazOFBiz katalogu karsilastirildi:

- 17.12.01 - 17.12.09
- 18.12.01 - 18.12.19
- 24.09.01 - 24.09.07

## Compatibility

Mevcut CLI, Docker ve doctor komutlari degismemistir.
