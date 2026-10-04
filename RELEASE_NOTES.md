# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.5.0 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.5.0
# Aciklama: Interaktif coklu OFBiz surum secimli Windows installer'i ozetler
#
# Bagimli Oldugu Katman: View | Tool | Config

# TurkuazOFBiz v1.5.0

v1.5.0 Windows installer'i tek sabit OFBiz surumunden interaktif coklu surum yoneticisine donusturur.

## Surum secim menusu

Installer parametresiz install action ile acildiginda once hedef ailesini sorar:

1. Release 24.09
2. Release 18.12
3. Release 17.12
4. Snapshot / branch

Release secildiginde config/versions.conf katalogundaki tum desteklenen tam surumler listelenir.

Snapshot secildiginde:

- trunk
- release24.09
- release22.01

sunulur.

17.12 compat hedeflerinde demo varyanti otomatik secilir. Diger hedeflerde Demo veya Runtime secilebilir.

## Docker image hazirlama

Installer once resmi Apache OFBiz Docker image'ini kullanmayi dener.

Resmi image eslestirmesi veya manifesti yoksa ayni hedef icin kaynak koddan local Docker image build eder. Bu nedenle eski 18.12/17.12 veya release22.01 hedeflerinin ilk kurulumu 24.09 resmi image kurulumundan daha uzun surebilir.

## Hedef durumu

Basarili secim su dosyada saklanir:

    %LOCALAPPDATA%\TurkuazOFBiz\installer-state.json

Masaustu TurkuazOFBiz kisayolu sonraki acilista bu hedefi tekrar baslatir.

## Izolasyon

Her hedef ve varyant kendi TurkuazOFBiz container kimligini ve credential dosyasini kullanir. Demo parolasi admin / ofbiz olarak kalir; Runtime varyanti guclu rastgele parola uretir.

Tum hedefler varsayilan olarak 127.0.0.1:8443 kullandigi icin installer secilen hedefi baslatmadan once diger TurkuazOFBiz container'larini durdurur.
