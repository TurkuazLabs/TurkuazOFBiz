# Dosya Yolu: /CHANGELOG.md
# Amac: TurkuazOFBiz surumlerindeki kullaniciya donuk degisiklikleri kaydeder
# View - Markdown
# Version: 1.0.0
# Aciklama: Semantic versioning tabanli proje degisiklik gecmisi
#
# Bagimli Oldugu Katman: View

# Changelog

Tum dikkat cekici TurkuazOFBiz degisiklikleri bu dosyada kaydedilir.

Surumleme Semantic Versioning mantigini izler.

## [1.0.0] - 2026-10-04

### Added

- Apache OFBiz 24.09, 18.12 ve 17.12 release katalogu.
- Release aliaslari: latest, 24.09, 18.12 ve 17.12.
- Apache Git branch tabanli trunk, release24.09 ve release22.01 snapshot yonetimi.
- Release ve snapshot hedefleri icin yan yana kurulum modeli.
- Izole Eclipse Temurin JDK yonetimi.
- Aktif hedef icin /opt/ofbiz/current symlink yonetimi.
- Kurulum metadata dosyasi ile release/snapshot ve Java major takibi.
- Controller, Service, Repository, Tool, View, Language ve Config katmanlari.
- Resmi Apache GHCR OFBiz image pull/run destegi.
- 22.01 branch'i icin kaynak Docker build destegi.
- Eski release'ler icin Dockerfile.compat fallback yapisi.
- Docker Compose ornek ortam dosyasi ve kalici volume yapisi.
- Gercek HTTPS Docker smoke testi.
- GitHub Actions ile Bash syntax, ShellCheck, resolver ve Docker testleri.
- Legacy OFBiz ve Java kurulum scriptleri icin arsiv alani.

### Changed

- Proje b1glord/Configs icindeki OFBIZ klasorunden TurkuazLabs/TurkuazOFBiz bagimsiz reposuna tasindi.
- OFBIZ ara klasoru kaldirilarak proje yapisi repo kokune tasindi.
- Eski Configs raw referanslari TurkuazOFBiz public kaynaklarina yonlendirildi.

### Verified

- ghcr.io/apache/ofbiz:24.09.07-preloaddemo gercek container olarak baslatildi.
- HTTPS /partymgr endpoint'i smoke testte dogrulandi.
- Apache release22.01 Dockerfile docker build --check ile dogrulandi.
