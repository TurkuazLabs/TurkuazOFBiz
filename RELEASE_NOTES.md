# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.3.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.3.0
# Aciklama: Atomik release/snapshot kurulum ve metadata dogrulama modelini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.3.0

v1.3.0 release ve snapshot kurulumlarini yarim kalmis filesystem durumlarina karsi sertlestirir.

## Atomic install model

Yeni kurulum veya reinstall once hedef klasore yazmak yerine ayni parent filesystem altinda gecici staging dizininde hazirlanir.

Staging tamamlanmadan hedef degistirilmez. Basarili staging icin su kosullar dogrulanir:

- gradlew mevcut ve executable.
- .ofbiz-meta mevcut.
- type dogru.
- identifier dogru.
- Java major dogru.
- Snapshot icin .git repository mevcut.

Dogrulama basarili olduktan sonra staging runtime hedef dizine tasinir.

Mevcut hedef varsa replacement sirasinda gecici backup tutulur. Yeni dizinin tasinmasi basarisiz olursa eski hedef restore edilmeye calisilir.

## Release behavior

Yarim kalmis bir release klasoru artik kurulu sayilmaz. Normal install bu hedefi yeniden hazirlar.

Force reinstall yeni staging hazir olmadan mevcut saglam release'i silmez.

## Snapshot behavior

Snapshot install ayni atomik staging modelini kullanir.

Snapshot update mevcut checkout'u yerinde degistirmek yerine branch'i yeniden staging'e clone eder, hazirlar ve dogrulama sonrasi hedefi degistirir.

## CI

- 17.12.09, 18.12.19 ve 24.09.07 release matrisi artik release-service ile gercek install akisini test eder.
- Idempotent ikinci install aktivasyonu test edilir.
- release24.09 snapshot install gercek snapshot-service, Git clone, Temurin 17 ve Gradle help ile test edilir.
- Repository staging/replacement ve metadata validation yardimcilari ag gerektirmeyen testlerle kontrol edilir.
- Doctor ve Docker smoke testleri korunur.
