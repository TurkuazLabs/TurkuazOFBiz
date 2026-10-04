# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.1.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.1.0
# Aciklama: Doctor teshis komutu ve gelistirilmis release checksum testlerini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.1.0

v1.1.0 sistem ve uzak kaynak sorunlarini kurulumdan once tespit etmek icin yeni doctor komutunu ekler.

## Doctor

Tum temel kontroller:

~~~bash
bash controllers/ofbiz.sh doctor all
~~~

Yalnizca yerel ortam:

~~~bash
bash controllers/ofbiz.sh doctor local
~~~

Belirli release:

~~~bash
bash controllers/ofbiz.sh doctor release 24.09.07
bash controllers/ofbiz.sh doctor release 18.12
~~~

Snapshot branch:

~~~bash
bash controllers/ofbiz.sh doctor snapshot trunk
bash controllers/ofbiz.sh doctor snapshot 22.01
~~~

Docker:

~~~bash
bash controllers/ofbiz.sh doctor docker
~~~

Doctor kurulum yapmaz ve dosya sistemi durumunu degistirmez. PASS, WARN ve FAIL sonuclari verir; kritik failure varsa non-zero exit code dondurur.

## Release integrity

CI artik sadece parser fixture'ini degil gercek Apache 24.09.07 release ZIP ve .sha512 dosyasini indirerek uctan uca dogrulama yapar.

## Compatibility

Mevcut release, snapshot, runtime ve Docker komutlari degismemistir.
