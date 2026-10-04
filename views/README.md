# Dosya Yolu: /views/README.md
# Amac: Apache OFBiz release, snapshot, runtime ve Docker kullanimini aciklar
# View - Markdown
# Version: 4.1.0
# Aciklama: Release/snapshot kurulumlari ile resmi ve local Docker image akislarini dokumante eder
#
# Bagimli Oldugu Katman: View | Controller | Service | Repo | Tool | Config

# Apache OFBiz Version Manager

## Release

~~~bash
bash controllers/ofbiz.sh release list
sudo bash controllers/ofbiz.sh release install latest
sudo bash controllers/ofbiz.sh release install 24.09.07
sudo bash controllers/ofbiz.sh release install 18.12.10
~~~

## Snapshot

~~~bash
bash controllers/ofbiz.sh snapshot list
sudo bash controllers/ofbiz.sh snapshot install trunk
sudo bash controllers/ofbiz.sh snapshot install 24.09
sudo bash controllers/ofbiz.sh snapshot install 22.01
sudo bash controllers/ofbiz.sh snapshot update trunk
~~~

## Docker stratejisi

Docker iki kaynagi destekler.

Resmi GHCR image tercih edilen hedefler:

~~~text
release 24.09.07 runtime -> ghcr.io/apache/ofbiz:24.09.07
release 24.09.07 demo    -> ghcr.io/apache/ofbiz:24.09.07-preloaddemo
snapshot trunk runtime   -> ghcr.io/apache/ofbiz:trunk-snapshot
snapshot trunk demo      -> ghcr.io/apache/ofbiz:trunk-preloaddemo-snapshot
snapshot 24.09 runtime   -> ghcr.io/apache/ofbiz:release24.09-snapshot
snapshot 24.09 demo      -> ghcr.io/apache/ofbiz:release24.09-preloaddemo-snapshot
~~~

22.01 icin branch halen Apache Git reposunda vardir fakat guncel resmi snapshot tag'i yoktur. Bu nedenle local build kullanilir:

~~~bash
bash controllers/ofbiz.sh docker build snapshot 22.01 runtime
~~~

Local image adi:

~~~text
local/ofbiz:snapshot-release22.01-runtime
~~~

## Docker pull

~~~bash
bash controllers/ofbiz.sh docker pull release 24.09.07 runtime
bash controllers/ofbiz.sh docker pull release 24.09.07 demo
bash controllers/ofbiz.sh docker pull snapshot trunk runtime
bash controllers/ofbiz.sh docker pull snapshot 24.09 demo
~~~

Bir resmi tag yoksa pull komutu hata verir ve local build kullanmanizi ister.

## Docker source build

~~~bash
bash controllers/ofbiz.sh docker build release 24.09.07 runtime
bash controllers/ofbiz.sh docker build release 18.12.10 runtime
bash controllers/ofbiz.sh docker build snapshot 22.01 runtime
~~~

Kaynakta resmi Apache Dockerfile varsa o kullanilir. Yoksa tools/docker/Dockerfile.compat kullanilir.

## Docker run

Admin parolasi repoya yazilmaz:

~~~bash
OFBIZ_ADMIN_PASSWORD='<secret>' bash controllers/ofbiz.sh docker run release 24.09.07 runtime
~~~

Snapshot:

~~~bash
OFBIZ_ADMIN_PASSWORD='<secret>' bash controllers/ofbiz.sh docker run snapshot trunk runtime
~~~

Varsayilan bind:

~~~text
127.0.0.1:8443 -> container:8443
~~~

Container isimleri hedefe gore uretilir:

~~~text
ofbiz-release-24-09-07
ofbiz-snapshot-trunk
ofbiz-snapshot-release24-09
~~~

## Docker smoke

Preloaded demo image ile gercek HTTPS testi:

~~~bash
bash controllers/ofbiz.sh docker smoke release 24.09.07 demo
~~~

Smoke testi container'i gecici olarak 127.0.0.1:18443 portunda baslatir, /partymgr endpoint'ini kontrol eder ve container'i siler.

## Docker Compose

~~~bash
cd tools/docker
cp .env.example .env
chmod 600 .env
~~~

.env icinde en az:

~~~text
OFBIZ_ADMIN_PASSWORD=<guclu-parola>
~~~

degistirilmelidir.

Ardindan:

~~~bash
docker compose -f compose.yml up -d
docker compose -f compose.yml logs -f ofbiz
docker compose -f compose.yml down
~~~

Gercek .env dosyasi .gitignore ile disarida tutulur.

## Resmi entrypoint ayarlari

Modern Apache Docker image'lari OFBIZ_DATA_LOAD, OFBIZ_ADMIN_USER, OFBIZ_ADMIN_PASSWORD ve OFBIZ_HOST ortam degiskenlerini destekler.

Runtime image ilk calismada seed veya demo veri yukleyebilir. preloaddemo image ise demo verisini image build sirasinda yuklemis olarak gelir.

## CI

OFBiz Config CI su kontrolleri calistirir:

~~~text
Bash syntax
ShellCheck
katman/header testleri
release/snapshot resolver testleri
Docker tag resolver testleri
resmi GHCR manifest kontrolleri
24.09.07 preloaddemo gercek container HTTPS smoke testi
release22.01 Dockerfile build check
~~~
