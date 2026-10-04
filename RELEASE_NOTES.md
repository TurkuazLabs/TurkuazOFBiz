# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.0.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.0.0
# Aciklama: Ilk stabil surumun ozelliklerini, test durumunu ve kullanim notlarini ozetler
#
# Bagimli Oldugu Katman: View

# TurkuazOFBiz v1.0.0

TurkuazOFBiz'in ilk stabil surumu Apache OFBiz release, snapshot ve Docker hedeflerini tek bir katmanli CLI yapisinda yonetir.

## Highlights

- OFBiz 24.09, 18.12 ve 17.12 release yonetimi.
- trunk, release24.09 ve release22.01 snapshot yonetimi.
- Release ve snapshot hedefleri arasinda aktif surum gecisi.
- Otomatik Java major secimi ve izole Temurin JDK dizinleri.
- Resmi Apache GHCR container image destegi.
- 22.01 icin kaynak branch Docker build destegi.
- Runtime ve demo Docker varyantlari.
- Loopback varsayilanli guvenli Docker port bind.
- CI icinde gercek OFBiz HTTPS smoke testi.

## Quick start

~~~bash
git clone https://github.com/TurkuazLabs/TurkuazOFBiz.git
cd TurkuazOFBiz

bash tools/ci/validate-structure.sh
bash controllers/ofbiz.sh release list
bash controllers/ofbiz.sh snapshot list
~~~

Resmi 24.09.07 demo image testi:

~~~bash
bash controllers/ofbiz.sh docker pull release 24.09.07 demo
bash controllers/ofbiz.sh docker smoke release 24.09.07 demo
~~~

22.01 local Docker build:

~~~bash
bash controllers/ofbiz.sh docker build snapshot 22.01 runtime
~~~

## Validation

v1.0.0 release hazirligi sirasinda:

- Bash syntax kontrolu basarili.
- ShellCheck basarili.
- Release ve snapshot resolver testleri basarili.
- Resmi Apache GHCR tag kontrolleri basarili.
- OFBiz 24.09.07 preloaded demo HTTPS smoke testi basarili.
- release22.01 Dockerfile build check basarili.

## Compatibility

Linux ve Docker odakli calisir. Docker Desktop + WSL2 gibi Linux uyumlu Docker ortamlari da desteklenen kullanim modelidir.

## License

TurkuazOFBiz Apache License 2.0 ile lisanslanir.

Apache OFBiz, Apache Software Foundation tarafindan gelistirilen ayri bir projedir. TurkuazOFBiz Apache OFBiz'in resmi dagitimi degildir.
