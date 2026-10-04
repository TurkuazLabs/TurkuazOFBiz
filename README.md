# Dosya Yolu: /README.md
# Amac: OFBiz konfigurasyon paketinin ana giris ve klasor haritasini sunar
# View - Markdown
# Version: 2.2.0
# Aciklama: Release, snapshot, runtime ve Docker araclari icin hizli baslangic rehberi
#
# Bagimli Oldugu Katman: View | Controller | Service | Repo | Tool | Language | Config

# Apache OFBiz Configs

Bu paket Apache OFBiz'in sabit release surumlerini, branch tabanli snapshot hedeflerini ve Docker image/container akislarini ayni arabirimden yonetir.

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

22.01 resmi guncel GHCR tag'i yerine Apache release22.01 branch Dockerfile'i ile local build edilir:

~~~bash
bash controllers/ofbiz.sh docker build snapshot 22.01 runtime
~~~

Herhangi bir release'i kaynaktan build etmek de mumkundur:

~~~bash
bash controllers/ofbiz.sh docker build release 18.12.10 runtime
~~~

## Docker calistirma

Production veya kalici kullanim icin admin parolasi ortamdan verilmelidir:

~~~bash
OFBIZ_ADMIN_PASSWORD='<secret>' bash controllers/ofbiz.sh docker run release 24.09.07 runtime
~~~

Varsayilan HTTPS bind adresi yalnizca localhost'tur:

~~~text
https://localhost:8443/
~~~

## Docker smoke test

~~~bash
bash controllers/ofbiz.sh docker smoke release 24.09.07 demo
~~~

## Compose

~~~bash
cd tools/docker
cp .env.example .env
chmod 600 .env
# .env icindeki CHANGE_ME parolasini degistir
docker compose -f compose.yml up -d
~~~

Gercek .env dosyasi Git tarafindan ignore edilir.

Detayli kullanim: views/README.md

Mimari: views/ARCHITECTURE.md
