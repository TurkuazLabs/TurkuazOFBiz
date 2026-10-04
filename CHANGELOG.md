# Dosya Yolu: /CHANGELOG.md
# Amac: TurkuazOFBiz surumlerindeki kullaniciya donuk degisiklikleri kaydeder
# View - Markdown
# Version: 1.2.1
# Aciklama: Semantic versioning tabanli proje degisiklik gecmisi
#
# Bagimli Oldugu Katman: View

# Changelog

Tum dikkat cekici TurkuazOFBiz degisiklikleri bu dosyada kaydedilir.

Surumleme Semantic Versioning mantigini izler.

## [1.2.1] - 2026-10-04

### Fixed

- Dockerfile.compat kullanan eski release build'lerinde Java major artik release/snapshot resolver'dan Docker build arg olarak aktarilir.
- 17.12.x local Docker build'inin yanlislikla varsayilan Java 17 kullanmasi engellendi.
- Compat Docker build yolu 17.12=Java 8, 18.12=Java 8 ve 24.09/snapshot=Java 17 olarak statik CI testleriyle sabitlendi.
- CI artik 17.12.09 icin gercek Dockerfile.compat runtime image build eder ve image icindeki Java 8 surumunu dogrular.
- Legacy Gradle wrapper icindeki shasum cagrisi, Apache 18.12 Dockerfile'indaki yaklasimla uyumlu olarak sha1sum'a normalize edilir.
- Docker build hata cleanup'i local work_dir scope disina cikan EXIT trap yerine function-scoped subshell cleanup ile guvenli hale getirildi.
- Compat image'lar metadata label ile modern Apache image'larindan ayrilir.
- Legacy compat run yolu modern OFBIZ_* entrypoint degiskenlerini ve modern volume mountlarini zorla uygulamaz.
- Legacy compat runtime image otomatik data initialization saglamadigi icin CLI run yolu demo varyantini zorunlu tutar.

### Verified

- CI 17.12.09 demo compat image'ini gercek loadAll ile build eder, image icinde Java 8'i dogrular ve /webtools HTTPS endpoint'ini gercek container ile smoke test eder.
- Apache release17.12 kaynaginda Dockerfile bulunmadigi ve compat fallback gerektigi dogrulandi.
- Apache release18.12 Dockerfile'inin kendi icinde Eclipse Temurin 8 kullandigi dogrulandi.
- Modern Apache Docker volume yollarinin /ofbiz/config, /ofbiz/runtime, /ofbiz/lib-extra ve /docker-entrypoint-hooks oldugu kaynak Dockerfile ile dogrulandi.

## [1.2.0] - 2026-10-04

### Added

- Desteklenen sabit release serileri icin gercek CI runtime matrisi.
- Apache OFBiz 17.12.09 + Temurin 8 dogrulamasi.
- Apache OFBiz 18.12.19 + Temurin 8 dogrulamasi.
- Apache OFBiz 24.09.07 + Temurin 17 dogrulamasi.
- Her matrix hedefinde resmi ZIP + SHA-512, izole Temurin JDK, Gradle wrapper ve Gradle build script yukleme testi.

### Verified

- Apache arsivinde 17.12.01-17.12.09 serisinin tamam oldugu dogrulandi.
- Apache arsivinde 18.12.01-18.12.19 serisinin tamam oldugu dogrulandi.
- Apache release history ile 24.09.01-24.09.07 serisinin tamam oldugu dogrulandi.
- release17.12 ve release18.12 kaynaklarinda Java source/target compatibility 1.8 oldugu dogrulandi.
- release24.09 ve trunk icin Java 17 gereksinimi dogrulandi.
- Background ve shutdown Gradle komut bicimleri Apache kaynak ornekleriyle eslestirildi.

## [1.1.0] - 2026-10-04

### Added

- Yan etkisiz sistem teshisi icin doctor komutu.
- doctor local ile gerekli komutlar, install root ve aktif target kontrolu.
- doctor release ile release ZIP, SHA-512 ve Adoptium JDK endpoint kontrolu.
- doctor snapshot ile Apache Git branch ve Java mapping kontrolu.
- doctor docker ile Docker CLI, daemon ve resmi image manifest kontrolu.
- doctor all ile tum kontrollerin tek komutta calistirilmasi.
- CI icinde gercek Apache 24.09.07 ZIP + SHA-512 indirme/dogrulama smoke testi.

### Changed

- Release checksum CI testi fixture seviyesinden gercek Apache dosyasi ile uctan uca dogrulamaya genisletildi.

### Verified

- Apache 24.09.07 release ZIP ve resmi SHA-512 dosyasi CI'da gercekten indirildi ve dogrulandi.
- Doctor komutu GitHub Actions Linux/Docker ortaminda ag kaynaklariyla test edilir.

## [1.0.1] - 2026-10-04

### Fixed

- Apache OFBiz release .sha512 dosyalarinin Apache checksum formatinda olmasi nedeniyle sabit release ZIP kurulumunun SHA-512 dogrulamasinda hata vermesi duzeltildi.
- Checksum parser artik hem Apache filename-colon-hash formatini hem GNU hash-filename formatini destekler.
- Basarisiz download veya checksum dogrulamasinda gecici dosyalar temizlenir.

### Verified

- Apache OFBiz 24.09.07 resmi SHA-512 dosya formati ile parser testi eklendi.
- Mevcut release/snapshot resolver, Docker smoke ve 22.01 Dockerfile kontrolleri korunur.

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
