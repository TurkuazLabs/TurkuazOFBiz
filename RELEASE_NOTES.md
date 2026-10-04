# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.4.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.4.0
# Aciklama: Tek tik Windows, PowerShell ve Linux installer deneyimini ozetler
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.4.0

v1.4.0 son kullanici kurulumunu komut satirindan tek tik installer modeline tasir.

## Windows

Release asset olarak TurkuazOFBiz-Installer.bat dosyasini indirin ve cift tiklayin.

Installer otomatik olarak:

- En son stabil TurkuazOFBiz release'ini bulur.
- Projeyi LOCALAPPDATA altinda yonetir.
- Ubuntu-24.04 veya uygun WSL dagitimini secer.
- Docker Desktop kapaliysa baslatmayi dener.
- Docker'in WSL icinden hazir olmasini kontrol eder.
- OFBiz 24.09.07 demo image'ini ceker.
- Guclu admin parolasi uretir ve kullanici profilinde saklar.
- Container'i 127.0.0.1:8443 adresinde baslatir.
- Masaustune TurkuazOFBiz kisayolu olusturur.
- Tarayicida https://localhost:8443/ adresini acar.

Varsayilan kullanici admin'dir. Uretilen parola installer sonucunda ekranda ve kullanici profilindeki parola dosyasinda gosterilir.

## Linux / WSL

install.sh ayni Docker akisini Linux ve WSL icin sunar.

Desteklenen action'lar:

- install
- start
- stop
- status
- doctor
- open

## Release assets

Her stabil release su dosyalari yayinlar:

- TurkuazOFBiz-Installer.bat
- TurkuazOFBiz-Installer.ps1
- TurkuazOFBiz-Installer.sh

## Requirements

Windows installer WSL2 Linux dagitimi ve Docker Desktop bekler. Mevcut TurkuazOFBiz komutlari ileri seviye ve manuel kullanim icin korunur.
