# Dosya Yolu: /views/ARCHITECTURE.md
# Amac: OFBiz konfigurasyon araclarinin katmanli mimarisini ve sorumluluk sinirlarini dokumante eder
# View - Markdown
# Version: 1.2.0
# Aciklama: Release, snapshot, runtime ve Docker akislarinin katman bagimliliklarini aciklar
#
# Bagimli Oldugu Katman: View | Controller | Service | Repo | Tool | Language | Config

# OFBiz Configuration Architecture

## Katmanlar

~~~text
controllers/ofbiz.sh
    |
    +--> services/release-service.sh
    +--> services/snapshot-service.sh
    +--> services/runtime-service.sh
    +--> services/docker-service.sh
              |
              +--> repositories/install-repository.sh
              +--> repositories/docker-repository.sh
              |
              +--> tools/java-tool.sh
              +--> tools/release-tool.sh
              +--> tools/git-tool.sh
              +--> tools/docker-tool.sh
              +--> tools/ofbiz-run.sh

views/
language/
config/
~~~

Controller yalnizca CLI routing yapar.

Service is kurallarini ve akislari koordine eder.

Repository kurulum storage'i, metadata, image referansi ve container adlandirma bilgisini yonetir.

Tool Git, Curl, Java, Gradle ve Docker CLI gibi dis sistem adaptorlerini kapsar.

Config release/snapshot kataloglari, dis kaynaklar, Docker tag'leri ve runtime sabitlerini tutar.

View ve Language kullaniciya gosterilen yardim/dokumantasyon katmanidir.

## Docker karari

Modern release veya snapshot icin resmi Apache GHCR image'i varsa pull/run akisi tercih edilir.

22.01 gibi resmi guncel image'i olmayan fakat Apache branch'i bulunan hedeflerde kaynak branch clone edilir ve branch'in kendi Dockerfile'i ile local image build edilir.

Eski release paketinde Dockerfile yoksa Dockerfile.compat kullanilir.

Docker Compose varsayilan olarak HTTPS portunu 127.0.0.1 adresine bind eder ve runtime/config/lib-extra/hook dizinlerini kalici volume olarak tutar.
