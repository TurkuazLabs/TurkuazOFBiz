# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.7.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.7.0
# Aciklama: Config tabanli cok-surumlu Windows portable dagitim modelini tanitir
#
# Bagimli Oldugu Katman: View | Tool | Config

# TurkuazOFBiz v1.7.0

v1.7.0 ile Windows portable dagitim tek bir OFBiz surumune bagli olmaktan cikarildi.

## Portable hedefler

Release matrisi merkezi `config/versions.conf` katalogundan uretilir:

~~~text
OFBiz 24.09.07 -> Temurin Java 17
OFBiz 18.12.19 -> Temurin Java 8
OFBiz 17.12.09 -> Temurin Java 8
~~~

Her hedef icin iki paket yayinlanir:

~~~text
TurkuazOFBiz-Portable-<version>-Demo-win-x64.zip
TurkuazOFBiz-Portable-<version>-Runtime-win-x64.zip
~~~

Her ZIP kendi SHA-256 dosyasi ile yayinlanir.

## Java uyumlulugu

Portable helper Java 8-17 ortak API tabanina indirildi.

Windows launcher paket icindeki `portable-java-major.txt` metadata'sini okur. Java 17 tarafinda gerekli module open parametresi kullanilirken Java 8 tarafinda desteklenmeyen `--add-opens` parametresi verilmez.

Portable builder secilen OFBiz release icin gerekli Java major degerini merkezi katalogdan cozer. Yanlis JDK ile build denenirse paketleme baslamadan hata verir.

## Portable metadata

Her cikartilan portable paket su metadata'yi tasir:

~~~text
portable-version.txt
portable-java-major.txt
portable-mode.txt
portable-metadata.properties
~~~

Bu metadata hem kullanici paketi hem CI smoke testi tarafindan ayni hedefin dogrulanmasi icin kullanilir.

## Guvenlik

Demo paketi resmi demo admin davranisini korur.

Runtime paketi ilk calistirmada yerel olarak:

- guclu admin parolasi,
- OFBiz shutdown anahtari,
- login secret,
- JWT/token anahtari

uretir.

Sabit production parolasi release asset'ine gomulmez.

## Release dogrulamasi

GitHub Release yayinlanmadan once her portable hedef:

- resmi Apache OFBiz ZIP ve SHA-512 dogrulamasindan,
- uygun Temurin JDK ile distZip build'inden,
- Demo ve Runtime preload isleminden,
- bundled Java metadata kontrolunden,
- gercek `https://localhost:8443/partymgr` readiness testinden,
- Start/Stop smoke testinden,
- ZIP SHA-256 dogrulamasindan

gecer.

Docker/WSL installer alternatif calisma modu olarak korunur.
