# Dosya Yolu: /CHANGELOG.md
# Amac: TurkuazOFBiz surumlerindeki kullaniciya donuk degisiklikleri kaydeder
# View - Markdown
# Version: 1.7.0
# Aciklama: Semantic versioning tabanli proje degisiklik gecmisi
#
# Bagimli Oldugu Katman: View

# Changelog

Tum dikkat cekici TurkuazOFBiz degisiklikleri bu dosyada kaydedilir.

Surumleme Semantic Versioning mantigini izler.

## [1.7.0] - 2026-10-05

### Added

- Windows portable release hedefleri icin merkezi `OFBIZ_PORTABLE_RELEASES` katalogu.
- Portable paket icine `portable-java-major.txt` ve `portable-metadata.properties` metadata dosyalari.
- Release workflow icin config tabanli dinamik Windows portable build matrisi.
- 24.09.07 / Java 17, 18.12.19 / Java 8 ve legacy-adapter tabanli 17.12.09 / Java 8 native portable hedefleri.
- CI icinde portable katalog tutarliligi ve Java 8 source/API uyumluluk derleme kontrolu.

### Changed

- Portable Java helper Java 17 API bagimliligindan Java 8-17 ortak API tabanina indirildi.
- Windows wildcard launcher Java major metadata'sini okuyarak `--add-opens` parametresini yalnizca Java 9+ runtime'larda kullanir.
- Portable builder OFBiz surumunun Java major degerini `config/versions.conf` katalogundan cozer ve yanlis JDK ile build'i reddeder.
- Release workflow sabit 24.09.07 hedefi yerine merkezi portable matrisi kullanir.
- GitHub Release tum portable hedeflerin Demo/Runtime ZIP ve SHA-256 dosyalarini otomatik toplar.

### Fixed

- Windows CRLF satir sonlarinin portable metadata smoke testini yanlis negatif sonuclandirmasi giderildi.
- Eski basarili CI kosularinin current main degilken pahali Windows portable build baslatmasi engellendi.
- Ayni validated commit icin yinelenen release workflow kosulari concurrency grubu ile tekillestirildi.
- Ayni branch'teki eski CI kosulari yeni commit geldiginde concurrency ile iptal edilerek gereksiz runtime/Docker tekrarlarinin kuyruga yigilmamasi saglandi.

### Verified

- Portable helper `javac --release 8` ile CI'da derlenir.
- 17.12 serisinin `application/distZip` sunmadigi dogrulandi; bunun yerine root OFBiz JAR + Gradle runtime bagimliliklarini relocatable `lib` staging alanina alan legacy portable adapter kullanilir.
- Her portable paket smoke testte OFBiz surumu, Java major, mode ve bundled Java runtime metadata'si ile dogrulanir.

## [1.6.0] - 2026-10-05

### Added

- Native Windows x64 portable dagitim modeli.
- Temurin JDK 17'nin portable paket icine gomulmesi; sistem Java kurulumu gerekmez.
- Apache OFBiz 24.09.07 distZip tabanli portable runtime.
- Ayri Demo ve Runtime portable ZIP paketleri.
- TurkuazOFBiz.cmd ana menu: Baslat, Durdur, Durum, Tarayicida Ac ve Ilk Admin Bilgisi.
- Start.cmd, Stop.cmd, Status.cmd, Open.cmd ve Credentials.cmd.
- SecureRandom tabanli PortableBootstrap Java helper.
- Runtime paketinde ilk calistirmada benzersiz admin parolasi ve shutdown anahtari.
- Demo/Runtime verisinin Windows release runner'da preload edilmesi.
- Her portable ZIP icin SHA-256 release asset'i.
- Release oncesi Demo ve Runtime portable gercek HTTPS smoke testi.

### Changed

- Windows icin onerilen ana dagitim Docker/WSL installer'dan native portable ZIP modeline tasindi.
- Docker/WSL installer opsiyonel alternatif olarak korunur.
- Portable runtime PowerShell Execution Policy, Docker Desktop ve WSL'den bagimsizdir.

### Fixed

- Apache distZip generated bin\ofbiz.bat dosyasinin Windows'ta "The input line is too long" hatasina yol acan uzun classpath'i portable akisindan kaldirildi.
- Portable preload, start, stop ve status islemleri kisa Java wildcard classpath launcher'ina tasindi.
- Portable login/JWT secret override'i gercek runtime classpath'indeki ofbiz\config\security.properties dosyasina tasindi.

### Security

- Runtime portable public release icine sabit production admin parolasi gomulmez.
- Her cikartilan Runtime klasoru ilk baslatmada yerel guclu parola ve shutdown anahtari uretir.
- JWT/login secret degerleri portable klasor icinde ilk calistirmada benzersiz olusturulur.

## [1.5.1] - 2026-10-04

### Added

- Windows icin TurkuazOFBiz-Setup.zip release paketi.
- ZIP icinde yerel TurkuazOFBiz-Launcher.cmd, TurkuazOFBiz-Installer.ps1 ve README-FIRST.txt.
- Windows setup ZIP icin SHA-256 checksum release asset'i.
- CI icinde Windows setup ZIP olusturma, icerik ve checksum dogrulamasi.

### Changed

- Windows son kullanici akisi tek basina BAT/PS1 indirmek yerine birlikte paketlenmis ZIP launcher modeline tasindi.
- Masaustu kisayolu launcher'i start nopause ile cagirir.
- Release workflow artik standalone BAT yerine Setup ZIP + SHA-256 yayinlar.

### Fixed

- Yeni launcher internetten PS1 indirmez.
- ExecutionPolicy Bypass tamamen kaldirildi.
- Launcher yerel PS1 icin Unblock-File uygular; RemoteSigned sistemlerde manuel Unblock-File ihtiyacini kaldirir.
- Installer hata ile sonlanirsa launcher penceresi hemen kapanmaz.
- Launcher hem release paketindeki TurkuazOFBiz-Installer.ps1 adini hem yonetilen repodaki install.ps1 adini destekler.

## [1.5.0] - 2026-10-04

### Added

- Windows installer icin interaktif OFBiz release/snapshot secim menusu.
- 24.09, 18.12 ve 17.12 serilerindeki desteklenen tam release surumlerini config katalogundan otomatik listeleme.
- trunk, release24.09 ve release22.01 snapshot branch secimi.
- Demo/Runtime varyant secimi; 17.12 compat hedeflerinde demo zorunlulugu.
- Secilen hedefi installer-state.json ile kalici kaydetme.
- Her hedef/varyant icin ayri credential dosyasi.
- Resmi Docker image bulunmadiginda otomatik local Docker build fallback'i.
- Secilen hedef/varyanta ozel TurkuazOFBiz container adi.

### Changed

- install action parametre verilmezse 24.09.07'yi sessizce secmek yerine menu acar.
- Masaustu start kisayolu son basarili kurulum secimini kullanir.
- Ayni 8443 portunu kullanan TurkuazOFBiz hedefleri arasinda gecis yaparken diger TurkuazOFBiz container'lari durdurulur.
- Demo ve runtime credential/storage container kimlikleri birbirinden ayrildi.

### Verified

- PowerShell installer parser testi korunur.
- CI menu katalog referanslari, state dosyasi, container adlandirma ve local build fallback kodunu dogrular.
- Mevcut release/snapshot runtime, Doctor ve Docker smoke matrisi korunur.

## [1.4.4] - 2026-10-04

### Fixed

- Apache OFBiz preloaddemo image icindeki resmi demo admin hesabi ile installer parola dosyasi senkronize edildi.
- Demo varyantinda yanlis rastgele parola uretmek yerine resmi admin / ofbiz girisi kullanilir.
- Runtime varyantinda rastgele guclu admin parola davranisi korunur.
- Windows ve Linux installer'a password action eklendi.
- Mevcut yanlis demo parola dosyasi yeni installer tarafindan ofbiz degeriyle duzeltilir.

### Verified

- Apache OFBiz release24.09 docker-entrypoint demo veri yuklemesinin admin hesabini zaten yuklenmis olarak isaretledigi dogrulandi.
- Apache OFBiz Docker dokumantasyonundaki demo admin girisi admin / ofbiz ile eslestirildi.

## [1.4.3] - 2026-10-04

### Fixed

- Windows ve Linux installer artik bos OFBiz root adresi yerine CI'da dogrulanan /partymgr endpoint'ini acar.
- Installer container baslatildiktan sonra /partymgr HTTPS endpoint'i hazir olana kadar bekler.
- Windows installer status/start/stop komutlarinda gereksiz 0 exit-code ciktisi kaldirildi.
- Installer doctor action'i Docker-only kurulumda gereksiz unzip ve /opt/ofbiz kontrollerini calistirmak yerine doctor docker kullanir.
- Docker-only kullanimda /opt/ofbiz bulunmamasi artik installer doctor sonucunu basarisiz yapmaz.

## [1.4.2] - 2026-10-04

### Fixed

- Windows installer'daki LOCALAPPDATA yolunun WSL yoluna cevrilmesinde dogrudan wslpath cagrisi kaldirildi.
- Standart WSL mount yapisinda C:\ yolu dogrudan /mnt/c/ yoluna cevrilir ve WSL icinde varligi dogrulanir.
- Ubuntu-24.04 ortaminda Windows yolu arguman aktarimindan kaynaklanan "Windows yolu WSL yoluna cevrilemedi" hatasi giderildi.
- CI installer'in tekrar dogrudan wslpath kullanmasini engelleyen regression kontrolleri ekledi.
- Yol donusumu PowerShell Path API + standart WSL2 /mnt/<drive> mount modeliyle sadeleştirildi.

## [1.4.1] - 2026-10-04

### Fixed

- Windows masaustu kisayolu artik install yerine start action ile acilir.
- Mevcut container varsa yalnizca baslatilir ve tarayici acilir.
- Container yoksa start action mevcut installer davranisiyla otomatik kuruluma geri doner.

## [1.4.0] - 2026-10-04

### Added

- Windows icin cift tiklanabilir install.bat bootstrap installer.
- Windows PowerShell install.ps1 yoneticisi.
- Linux ve WSL icin install.sh installer.
- Windows installer icinde WSL dagitimi otomatik secimi.
- Docker Desktop kapaliysa otomatik baslatma ve WSL Docker readiness kontrolu.
- Stabil TurkuazOFBiz GitHub Release arsivini otomatik indirme ve yonetilen repo dizini.
- OFBiz 24.09.07 demo image pull/run otomasyonu.
- Guclu admin parolasini otomatik uretme ve kullanici profilinde saklama.
- Windows masaustu TurkuazOFBiz kisayolu.
- Installer start, stop, status, doctor ve open action'lari.
- Her GitHub Release icin indirilebilir BAT, PS1 ve SH installer asset'leri.

### Changed

- Windows son kullanici akisi CLI komutlari yerine tek BAT dosyasina indirildi.
- Release workflow installer asset'lerini GitHub Release'e ekler.
- CI PowerShell parser, Bash syntax, ShellCheck ve BAT latest-asset referanslarini dogrular.

### Verified

- install.sh Bash syntax kontrolu basarili.
- Installer dosyalari release CI kapsaminda test edilir.
- Mevcut atomik release/snapshot, Doctor ve Docker testleri korunur.

## [1.3.0] - 2026-10-04

### Added

- Release ve snapshot kurulumlari icin ayni filesystem uzerinde staging dizinleri.
- Kurulum tamamlanmadan once gradlew, metadata, type, identifier ve Java major dogrulamasi.
- Snapshot kurulumlarinda .git repository dogrulamasi.
- Hedef dizin replacement sirasinda eski kurulumun backup/restore guvencesi.
- CI runtime matrisi artik release-service katmanini gercek kurulum yolu ile test eder.
- CI release24.09 snapshot kurulumunu snapshot-service katmani uzerinden gercek clone + JDK + Gradle ile test eder.

### Changed

- Release reinstall artik mevcut saglam kurulumu yeni staging kurulumu basariyla hazir olana kadar silmez.
- Snapshot update artik mevcut checkout'u yerinde hard-reset etmek yerine yeni branch clone'unu staging'de hazirlayip atomik olarak degistirir.
- release use ve snapshot use eksik metadata veya bozuk gradlew bulunan hedefleri aktive etmez.
- current yolu gercek bir klasorse symlink ile sessizce ezilmeye calisilmaz.

### Fixed

- Yarim kalmis release/snapshot klasorlerinin yalnizca dizin varligi nedeniyle kurulu kabul edilmesi engellendi.
- Basarisiz force reinstall veya snapshot update sonrasinda onceki saglam hedefin kaybedilme riski azaltildi.

## [1.2.2] - 2026-10-04

### Fixed

- Legacy Docker compat runtime ile modern Apache Docker entrypoint davranisi kesin olarak ayrildi.
- Eski 17.12/18.12 compat image'larinda modern OFBIZ_ADMIN_PASSWORD, OFBIZ_DATA_LOAD ve modern volume davranisinin zorla uygulanmasi engellendi.
- Legacy compat container calistirmada preloaded demo varyanti zorunlu hale getirildi.
- 17.12.09 demo compat image gercek HTTPS /webtools smoke testiyle dogrulandi.

### Changed

- Release sonrasinda ayni VERSION ile yeni commit yapilmasini engelleyen CI surum-drift kontrolu eklendi.
- Yayinlanmis bir vX.Y.Z tag'i farkli commit'e aitse main/PR CI artik yeni version bump isteyecek.

### Verified

- 17.12.09 + Java 8 compat Docker demo image build ve HTTPS smoke testi basarili.
- 17.12.09, 18.12.19 ve 24.09.07 runtime matrisi korunur.
- Doctor, release ZIP checksum ve modern Docker smoke testleri korunur.

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
