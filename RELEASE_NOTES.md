# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.7.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.7.0
# Aciklama: Cok-surumlu portable dagitim ve tek Windows/Linux Native-Docker installer modelini tanitir
#
# Bagimli Oldugu Katman: View | Tool | Config

# TurkuazOFBiz v1.7.0

v1.7.0 ile Windows portable dagitim tek bir OFBiz surumune bagli olmaktan cikarildi ve Windows/Linux kurulumlari ortak Native/Docker secim modeline toplandi.

## Tek installer modeli

Kurulum akisi iki platformda ayni kavramlari kullanir:

~~~text
Mode         -> Native / Docker
Target type  -> Release / desteklenen Snapshot
Target       -> OFBiz surumu veya branch
Variant      -> Demo / Runtime
~~~

Windows'ta Native varsayilan moddur. Installer uygun portable release asset'ini indirir, SHA-256 dogrular ve WSL/Docker kullanmadan calistirir.

Linux'ta Native varsayilan moddur. Installer mevcut Controller -> Service -> Repo -> Tool katmanini kullanarak OFBiz runtime'ini ve gerekli Temurin JDK'yi kurar. Docker modu opsiyonel alternatif olarak korunur.

Windows Docker modu WSL2 + Docker Desktop kullanir. Linux Docker modu yerel Docker daemon kullanir.

## Portable hedefler

Release matrisi merkezi `config/versions.conf` katalogundan uretilir:

~~~text
OFBiz 24.09.07 -> Temurin Java 17
OFBiz 18.12.19 -> Temurin Java 8
OFBiz 17.12.09 -> Temurin Java 8
~~~

Apache 17.12 build yapisinda `application/distZip` bulunmadigi icin 17.12.09 ayri legacy portable adapter ile paketlenir. Adapter kaynak runtime agacini korur, root OFBiz JAR ve Gradle runtime bagimliliklarini relocatable `lib` staging alanina toplar.

Her portable hedef icin iki paket yayinlanir:

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

Release workflow once basarili CI commit'inin hala current `main` oldugunu dogrular. Eski CI kosulari portable build baslatmadan atlanir ve ayni commit icin yinelenen release kosulari tekillestirilir.

GitHub Release yayinlanmadan once her portable hedef:

- resmi Apache OFBiz ZIP ve SHA-512 dogrulamasindan,
- uygun Temurin JDK ile distZip build'inden,
- Demo ve Runtime preload isleminden,
- bundled Java metadata kontrolunden,
- gercek `https://localhost:8443/partymgr` readiness testinden,
- Start/Stop smoke testinden,
- ZIP SHA-256 dogrulamasindan

gecer.

Docker kurulum modu alternatif calisma modu olarak korunur. Windows Native icin WSL/Docker zorunlu degildir; Linux Native icin Docker daemon zorunlu degildir.
