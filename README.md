# Dosya Yolu: /README.md
# Amac: TurkuazOFBiz projesinin ana giris, kurulum ve kullanim rehberini sunar
# View - Markdown
# Version: 3.13.0
# Aciklama: Apache OFBiz release, snapshot, runtime ve Docker yonetim araclarini tanitir
#
# Bagimli Oldugu Katman: View | Controller | Service | Repo | Tool | Language | Config

# TurkuazOFBiz

[![CI](https://github.com/TurkuazLabs/TurkuazOFBiz/actions/workflows/ofbiz-config-ci.yml/badge.svg)](https://github.com/TurkuazLabs/TurkuazOFBiz/actions/workflows/ofbiz-config-ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

**Current version:** v1.7.0

TurkuazOFBiz, Apache OFBiz release ve branch tabanli snapshot hedeflerini ayni arabirimden yonetmek icin gelistirilen acik kaynak yonetim aracidir.

Bu proje Apache OFBiz'in resmi dagitimi degildir. Apache OFBiz kaynaklarini, resmi release paketlerini ve resmi container image'larini kullanir.

## Windows Portable - onerilen kullanim

TurkuazOFBiz'in ana Windows dagitim modeli portable pakettir. Docker, WSL, sistem Java kurulumu veya PowerShell script calistirma izni gerekmez.

v1.7.0 release matrisi desteklenen her ana release ailesinin guncel portable hedefi icin Demo ve Runtime paketi uretir:

~~~text
24.09.07 -> Java 17 -> Demo / Runtime
18.12.19 -> Java 8  -> Demo / Runtime
17.12.09 -> Java 8  -> Demo / Runtime
~~~

Yayinlanan hedefler `config/versions.conf` icindeki `OFBIZ_PORTABLE_RELEASES` katalogundan gelir. Portable builder ayni katalogdan gerekli Java major degerini cozer.

24.09 ve 18.12 portable paketleri Apache `distZip` dagitimindan uretilir. Apache 17.12 build yapisinda `application/distZip` bulunmadigi icin bu seri ayri legacy adapter kullanir: kaynak runtime agaci staging alani olarak korunur, root OFBiz JAR ve Gradle `runtime` bagimliliklari relocatable `lib` klasorune toplanir ve ayni TurkuazOFBiz launcher katmani kullanilir.

Demo paketi Apache OFBiz demo verisini onceden tasir. Ilk giris:

~~~text
Kullanici: admin
Parola: ofbiz
~~~

Runtime paketi seed verisini onceden tasir. Ilk `Start.cmd` calismasinda paket icindeki Java helper SecureRandom ile benzersiz admin parolasi ve shutdown anahtari uretir. Ilk parola `data\initial-admin-password.txt` dosyasinda tutulur ve OFBiz ilk giriste parola degisikligi isteyebilir.

Kullanim:

1. ZIP'i bosluk icermeyen bir klasore tamamen cikarin. Ornek: `C:\TurkuazOFBiz` veya `E:\Apps\TurkuazOFBiz`.
2. `TurkuazOFBiz.cmd` dosyasina cift tiklayin.
3. Menuden Baslat, Durdur, Durum, Tarayicida Ac veya Ilk Admin Bilgisi secin.

Portable klasor:

~~~text
TurkuazOFBiz-Portable-<ofbiz-version>-...\
  TurkuazOFBiz.cmd
  Start.cmd
  Stop.cmd
  Status.cmd
  Open.cmd
  Credentials.cmd
  java\
  ofbiz\
  data\
  tools\
~~~

Her paket hedef OFBiz surumunun gerektirdigi Temurin JDK runtime'ini kendi icinde tasir. Apache OFBiz `distZip` dagitimi kullanilir; Demo/Runtime verisi release CI sirasinda Windows runner'da preload edilir. Portable calistirma Apache'nin uzun generated Windows classpath'i yerine `config;lib-extra\*;lib\*` wildcard classpath kullanan TurkuazOFBiz launcher'i ile yapilir; boylece Windows CMD satir uzunlugu sinirina takilmaz. Release yayinlanmadan once her iki paket de bundled Java ile gercek `https://localhost:8443/partymgr` smoke testinden gecirilir.

### Docker / WSL - opsiyonel

Docker tabanli installer korunur ancak artik alternatif calisma modudur. Son release altindaki `TurkuazOFBiz-Setup.zip` paketi WSL2 + Docker Desktop kullananlar icindir.

Docker launcher internetten PowerShell kodu indirmez ve `ExecutionPolicy Bypass` kullanmaz; ancak sistem policy'si imzasiz PowerShell'i tamamen kapatiyorsa portable Windows paketi tercih edilmelidir.

## Linux / WSL tek komut

~~~bash
curl -fsSL https://raw.githubusercontent.com/TurkuazLabs/TurkuazOFBiz/main/install.sh | bash
~~~

## Gelistirici hizli baslangic

~~~bash
git clone https://github.com/TurkuazLabs/TurkuazOFBiz.git
cd TurkuazOFBiz

bash tools/ci/validate-structure.sh
bash controllers/ofbiz.sh help
~~~

## Doctor

Kurulum yapmadan yerel ortam ve uzak kaynaklari kontrol edin:

~~~bash
bash controllers/ofbiz.sh doctor all
bash controllers/ofbiz.sh doctor release 24.09.07
bash controllers/ofbiz.sh doctor snapshot 22.01
bash controllers/ofbiz.sh doctor docker
~~~

Doctor PASS, WARN ve FAIL sonuclari verir. Kritik hata varsa non-zero exit code dondurur.

## Guvenli kurulum modeli

Release ve snapshot kurulumlari staging dizininde hazirlanir. Metadata ve runtime dogrulamasi basarili olmadan mevcut hedef degistirilmez. Yarim kalmis bir klasor kurulu kabul edilmez.

~~~text
download/clone -> staging -> JDK/Gradle hazirlik -> metadata validation -> atomic replacement -> current symlink
~~~

## Release

~~~bash
bash controllers/ofbiz.sh release list
sudo bash controllers/ofbiz.sh release install 24.09.07
sudo bash controllers/ofbiz.sh release install 18.12.10
~~~

## Snapshot / branch

~~~bash
bash controllers/ofbiz.sh snapshot list
sudo bash controllers/ofbiz.sh snapshot install trunk
sudo bash controllers/ofbiz.sh snapshot install 24.09
sudo bash controllers/ofbiz.sh snapshot install 22.01
sudo bash controllers/ofbiz.sh snapshot update trunk
~~~

## Docker resmi image

~~~bash
bash controllers/ofbiz.sh docker pull release 24.09.07 runtime
bash controllers/ofbiz.sh docker pull release 24.09.07 demo
bash controllers/ofbiz.sh docker pull snapshot trunk runtime
bash controllers/ofbiz.sh docker pull snapshot 24.09 runtime
~~~

## Docker local build

22.01 icin Apache release22.01 branch Dockerfile'i kullanilir:

~~~bash
bash controllers/ofbiz.sh docker build snapshot 22.01 runtime
~~~

Herhangi bir release'i kaynaktan build etmek de mumkundur:

~~~bash
bash controllers/ofbiz.sh docker build release 18.12.10 runtime
bash controllers/ofbiz.sh docker build release 17.12.09 demo
~~~

Resmi Dockerfile'i olmayan eski release'lerde Dockerfile.compat kullanilir ve gerekli Java major surumu release katalogundan otomatik aktarilir. Legacy compat image modern Apache Docker entrypoint davranisini taklit etmez; calistirma icin preloaded demo varyanti kullanilir:

~~~bash
bash controllers/ofbiz.sh docker run release 17.12.09 demo
~~~

17.12 demo verisindeki varsayilan test girisi admin / ofbiz'dir; production kullanimi icin bu legacy demo kimlik bilgileri uygun degildir.

## Docker calistirma

Admin parolasi repoya yazilmaz:

~~~bash
OFBIZ_ADMIN_PASSWORD='<secret>' \
bash controllers/ofbiz.sh docker run release 24.09.07 runtime
~~~

Varsayilan HTTPS bind adresi:

~~~text
https://localhost:8443/
~~~

## Docker smoke test

~~~bash
bash controllers/ofbiz.sh docker smoke release 24.09.07 demo
~~~

## Docker Compose

~~~bash
cd tools/docker
cp .env.example .env
chmod 600 .env
# .env icindeki CHANGE_ME parolasini degistir
docker compose -f compose.yml up -d
~~~

Gercek .env dosyasi Git tarafindan ignore edilir.

## CI

GitHub Actions su kontrolleri calistirir:

~~~text
Bash syntax
ShellCheck
katman/header testleri
release/snapshot resolver testleri
Docker tag resolver testleri
release metadata tutarliligi
gercek 24.09.07 ZIP + SHA-512 dogrulamasi
doctor ag/sistem smoke kontrolleri
17.12.09 + Temurin 8 + release-service install/Gradle testi
18.12.19 + Temurin 8 + release-service install/Gradle testi
24.09.07 + Temurin 17 + release-service install/Gradle testi
release24.09 + Temurin 17 + snapshot-service install/Gradle testi
17.12.09 Dockerfile.compat + Java 8 + HTTPS demo container testi
resmi GHCR manifest kontrolleri
24.09.07 preloaddemo gercek HTTPS smoke testi
release22.01 Dockerfile build check
Windows PowerShell installer parser testi
Linux installer Bash + ShellCheck testi
Release installer asset kontrolu
portable katalog ve Java 8-17 uyumluluk kontrolu
~~~

## Proje dosyalari

- CHANGELOG.md: Surum gecmisi.
- RELEASE_NOTES.md: Guncel stabil surum release notlari.
- VERSION: Proje surumu.
- LICENSE: Apache License 2.0.

Detayli kullanim: views/README.md

Mimari: views/ARCHITECTURE.md

Kaynak proje: https://ofbiz.apache.org/
