# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.4.3 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.4.3
# Aciklama: Installer uygulama URL, readiness ve Docker doctor davranisini duzeltir
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.4.3

Bu patch installer'in Docker container baslatildiktan sonraki kullanici deneyimini duzeltir.

## Fixed

- Tarayici artik https://localhost:8443/ yerine https://localhost:8443/partymgr adresini acar.
- Container baslatildiktan sonra /partymgr 2xx veya 3xx cevap verene kadar installer bekler.
- Windows PowerShell wrapper artik basarili WSL komutlarindan sonra gereksiz 0 yazdirmaz.
- Installer doctor action'i Docker kurulumu icin doctor docker calistirir.
- unzip ve /opt/ofbiz kontrolleri Docker-only installer saglik sonucunu etkilemez.

Mevcut container'i silmek gerekmez. Yeni installer ile start veya open kullanmak yeterlidir.
