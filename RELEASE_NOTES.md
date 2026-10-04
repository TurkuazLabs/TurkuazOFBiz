# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.4.1 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.4.1
# Aciklama: Windows masaustu kisayolunun start davranisini duzeltir
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.4.1

Bu patch surumu Windows tek tik kullanimini duzeltir.

## Fixed

Kurulum sonrasi olusturulan masaustu TurkuazOFBiz kisayolu artik install action yerine start action ile calisir.

Bunun sonucu:

- Mevcut OFBiz container zaten varsa yeniden kurulum yapilmaz.
- Durdurulmus container baslatilir.
- Tarayici otomatik acilir.
- Container henuz yoksa start action otomatik olarak tam kuruluma geri doner.

Ilk kurulum icin yine TurkuazOFBiz-Installer.bat dosyasina cift tiklamak yeterlidir.
