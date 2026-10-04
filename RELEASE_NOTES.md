# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.6.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.6.0
# Aciklama: Native Windows portable OFBiz dagitim modelini tanitir
#
# Bagimli Oldugu Katman: View | Tool | Config

# TurkuazOFBiz v1.6.0

v1.6.0 ile Windows icin ana kullanim modeli native portable OFBiz paketine tasindi.

## Portable paketler

- TurkuazOFBiz-Portable-24.09.07-Demo-win-x64.zip
- TurkuazOFBiz-Portable-24.09.07-Runtime-win-x64.zip

Her ZIP kendi SHA-256 dosyasi ile yayinlanir.

## Ne gerekmez?

Portable pakette:

- Docker Desktop gerekmez.
- WSL gerekmez.
- Windows'a Java kurmak gerekmez.
- PowerShell script execution policy degistirmek gerekmez.
- Registry kurulumu gerekmez.

Temurin JDK 17 paket icindedir.

## Kullanici arayuzu

ZIP'i bosluk icermeyen bir klasore cikarin ve TurkuazOFBiz.cmd dosyasina cift tiklayin.

Menu:

1. Baslat
2. Durdur
3. Durum
4. Tarayicida Ac
5. Ilk Admin Bilgisi

## Demo

Demo verisi release CI sirasinda onceden yuklenir.

Ilk giris:

    admin / ofbiz

## Runtime

Runtime seed verisi release CI sirasinda onceden yuklenir.

Ilk Start.cmd calismasinda paket icindeki Java helper SecureRandom ile:

- benzersiz admin parolasi,
- benzersiz OFBiz shutdown anahtari,
- benzersiz login/JWT secret degerleri

uretir.

Ilk admin parolasi data\initial-admin-password.txt dosyasina yazilir.

## Release dogrulamasi

GitHub Release yayinlanmadan once Windows runner:

- Apache 24.09.07 ZIP SHA-512 dogrulamasi yapar,
- distZip uretir,
- Temurin JDK 17'yi pakete koyar,
- Demo ve Runtime verisini preload eder,
- iki ZIP'i de acar,
- bundled Java ile Start.cmd calistirir,
- https://localhost:8443/partymgr endpoint'ini dogrular,
- Stop.cmd ile OFBiz'i kapatir.

Docker/WSL installer v1.6.0'da opsiyonel alternatif olarak korunur.
