# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.5.1 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.5.1
# Aciklama: Windows installer'i yerel paketlenmis launcher modeline tasir
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.5.1

Bu patch Windows'ta PS1 dosyasinin cift tiklandiginda kapanmasi, internetten indirilen script bloklari ve eski BAT bootstrap davranisini duzeltir.

## Onerilen Windows kurulumu

Release altindaki TurkuazOFBiz-Setup.zip dosyasini indirin, normal bir klasore cikarin ve TurkuazOFBiz-Launcher.cmd dosyasina cift tiklayin.

ZIP su dosyalari birlikte tasir:

- TurkuazOFBiz-Launcher.cmd
- TurkuazOFBiz-Installer.ps1
- README-FIRST.txt

Launcher internetten PowerShell kodu indirmez. ExecutionPolicy Bypass kullanmaz.

Yerel PS1 icin Windows internet zone blokunu Unblock-File ile kaldirir ve scripti normal PowerShell policy ile calistirir.

Hata durumunda pencere acik kalir ve hata mesaji okunabilir.

## Integrity

Release ayrica TurkuazOFBiz-Setup.zip.sha256 asset'ini yayinlar.

## Policy

Kurumsal MachinePolicy veya UserPolicy AllSigned zorluyorsa launcher bunu atlatmaz. Bu durumda Authenticode ile imzali installer gerekir.

v1.5.0 ile gelen interaktif 24.09 / 18.12 / 17.12 / snapshot secim menusu aynen korunur.
