# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.4.4 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.4.4
# Aciklama: Demo image admin parola uyumsuzlugunu duzeltir
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.4.4

Bu patch resmi Apache OFBiz preloaded demo image ile installer arasindaki admin parola uyumsuzlugunu duzeltir.

## Demo girisi

Apache OFBiz preloaddemo image demo verisini image icinde hazir getirir. Bu demo veri icindeki varsayilan yonetici hesabi:

- Kullanici: admin
- Parola: ofbiz

Demo veri yuklendiginde Apache entrypoint admin kullanicisini zaten yuklenmis olarak isaretledigi icin sonradan verilen OFBIZ_ADMIN_PASSWORD degeri bu hesabin parolasini degistirmez.

TurkuazOFBiz installer artik demo varyantinda rastgele ve gecersiz bir parola gostermek yerine resmi demo parolasini kullanir ve admin-password.txt dosyasini ofbiz ile senkronize eder.

Runtime varyantinda rastgele guclu parola davranisi korunur.

## Password action

Windows:

    .\TurkuazOFBiz-Installer.ps1 -Action password

Linux / WSL:

    ./install.sh password
