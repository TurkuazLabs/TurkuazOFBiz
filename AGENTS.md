<!--
Dosya Yolu: REPO_ROOT/AGENTS.md
Amac: TurkuazOFBiz icin aktif DevStandards v3.0.0 kurallari
Modul - Documentation Markdown
Version: 3.0.0
Aciklama: Surumlu merkezi kaynaga sabitlenmis proje kontrati
Bagimli Oldugu Katman: Documentation
-->

# TurkuazOFBiz - Project Agent Contract

**Source:** https://github.com/TurkuazSoft/DevStandards/tree/72f6f642128fa29ec9a68b18881e9aa225739c9d
**Standard:** BURAK DEV STANDARD v3.0.0, active, commit `72f6f642128fa29ec9a68b18881e9aa225739c9d`.
**Platform:** ERP / Java OFBiz, profile `platforms/java.md`.
**Project roadmap:** Mevcut README, CONTRIBUTING, docs ve issue/PR.

## Uygulama

- Once repo, aktif branch/PR, mevcut kaynak ve CI durumunu kontrol et. "Devam et" son dogrulanmis noktadan ilerlemek demektir.
- Calisan davranisi, guvenligi ve kullanici degisikliklerini koru; kapsam disi refactor ve onaysiz release yok.
- Mantiksal Controller -> Service -> Repository/Model is/veri sinirini koru; Tool/Adapter harici erisim, View arayuz, Language lokalizasyon katmanidir; framework native dizin yapisini koru.
- Teknik dosyalarda yorum destekleniyorsa Dosya Yolu, Amac, Modul - FileType, Version, Aciklama ve Bagimli Oldugu Katman ustverisini kullan; JSON/binary formatini bozma; gercek mutlak yol bilinmiyorsa REPO_ROOT/goreli-yol.
- Magic string, hard-coded config/secret, token veya kisi verisi loguna izin verme.
- Build, test, contract/integration ve smoke sonuclarini ayri dogrula. Test edilmemis PASS raporlama. Artifact production release degildir.
- Guvenilmeyen fork PR kodunu kisisel self-hosted CI'da calistirma.
- Merkezi repo private olabilir; erisim yoksa bu yerel temel kurallar baglayicidir. Yeni standartlar ayri kontrollu PR ile uygulanir.

## ERP / Java OFBiz

OFBiz modules and database migrations, purchase/supplier invoices and multi-tenant integrity preserved.
