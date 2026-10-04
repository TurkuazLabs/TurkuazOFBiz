# Dosya Yolu: /README.md
# Amac: TurkuazOFBiz projesinin ana giris, kurulum ve kullanim rehberini sunar
# View - Markdown
# Version: 3.9.0
# Aciklama: Apache OFBiz release, snapshot, runtime ve Docker yonetim araclarini tanitir
#
# Bagimli Oldugu Katman: View | Controller | Service | Repo | Tool | Language | Config

# TurkuazOFBiz

[![CI](https://github.com/TurkuazLabs/TurkuazOFBiz/actions/workflows/ofbiz-config-ci.yml/badge.svg)](https://github.com/TurkuazLabs/TurkuazOFBiz/actions/workflows/ofbiz-config-ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

**Current version:** v1.5.0

TurkuazOFBiz, Apache OFBiz release ve branch tabanli snapshot hedeflerini ayni arabirimden yonetmek icin gelistirilen acik kaynak yonetim aracidir.

Bu proje Apache OFBiz'in resmi dagitimi degildir. Apache OFBiz kaynaklarini, resmi release paketlerini ve resmi container image'larini kullanir.

## Tek tik Windows kurulumu

Windows + WSL2 + Docker Desktop kullananlar icin komut yazmak gerekmez.

1. Son release altindaki `TurkuazOFBiz-Installer.bat` dosyasini indirin.
2. Dosyaya cift tiklayin.
3. Installer stabil TurkuazOFBiz surumunu hazirlar, Docker Desktop'i gerekirse baslatir ve interaktif OFBiz surum secim menusunu acar.
4. Release serisi, tam surum ve Demo/Runtime varyanti secilir.
5. Resmi Docker image varsa cekilir; yoksa desteklenen hedef kaynak koddan local Docker image olarak build edilir.
6. Secim kaydedilir ve masaustu kisayolu sonraki acilista ayni hedefi baslatir.

Sabit latest asset:

https://github.com/TurkuazLabs/TurkuazOFBiz/releases/latest/download/TurkuazOFBiz-Installer.bat

Installer yonetilen proje dosyalarini `%LOCALAPPDATA%\TurkuazOFBiz\repo` altinda tutar ve masaustune TurkuazOFBiz kisayolu olusturur. Bu kisayol normal kullanimda mevcut container'i baslatir; container yoksa kurulumu otomatik yapar.

Varsayilan uygulama adresi:

~~~text
https://localhost:8443/partymgr
~~~

Installer container'i baslattiktan sonra bu endpoint 2xx/3xx cevap verene kadar bekler ve sonra tarayiciyi acar.

Windows installer su hedefleri menuden sunar:

~~~text
Release 24.09 : 24.09.01 - 24.09.07
Release 18.12 : 18.12.01 - 18.12.19
Release 17.12 : 17.12.01 - 17.12.09
Snapshot      : trunk, release24.09, release22.01
~~~

17.12 compat Docker yolu demo varyantiyla calisir. Diger hedeflerde Demo veya Runtime secilebilir. Farkli hedef/varyant container ve parola bilgileri birbirinden ayrilir; ayni 8443 portu kullanildigi icin installer secilen hedefi baslatirken diger TurkuazOFBiz container'larini durdurur.

Son secim burada tutulur:

~~~text
%LOCALAPPDATA%\TurkuazOFBiz\installer-state.json
~~~

Varsayilan demo image resmi Apache demo verisini kullanir. Demo girisi:

~~~text
Kullanici: admin
Parola: ofbiz
~~~

Demo varyantinda parola dosyasi bu degerle senkronize edilir. Runtime varyantinda ise guclu rastgele admin parolasi otomatik uretilir ve kullanici profilinde saklanir.

Windows installer ile parolayi tekrar gormek icin:

~~~powershell
.\TurkuazOFBiz-Installer.ps1 -Action password
~~~

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
~~~

## Proje dosyalari

- CHANGELOG.md: Surum gecmisi.
- RELEASE_NOTES.md: Guncel stabil surum release notlari.
- VERSION: Proje surumu.
- LICENSE: Apache License 2.0.

Detayli kullanim: views/README.md

Mimari: views/ARCHITECTURE.md

Kaynak proje: https://ofbiz.apache.org/
