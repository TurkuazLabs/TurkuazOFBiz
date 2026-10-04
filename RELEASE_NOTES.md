# Dosya Yolu: /RELEASE_NOTES.md
# Amac: TurkuazOFBiz v1.4.2 GitHub release notlarini hazirlar
# View - Markdown
# Version: 1.4.2
# Aciklama: Windows LOCALAPPDATA yolunun WSL icine guvenilir aktarimini duzeltir
#
# Bagimli Oldugu Katman: View | Tool

# TurkuazOFBiz v1.4.2

Bu patch Windows PowerShell installer'in WSL yol donusum hatasini duzeltir.

## Fixed

v1.4.1 installer Windows tarafindaki su tip yolu:

C:\Users\<user>\AppData\Local\TurkuazOFBiz\repo

dogrudan wslpath komutuna arguman olarak aktariyordu. Bazi Windows/WSL kurulumlarinda bu arguman beklenen bicimde WSL tarafina ulasmadigi icin installer OFBiz kurulumuna baslamadan durabiliyordu.

v1.4.2 ile:

- Standart Windows drive path'i /mnt/<drive>/... bicimine cevrilir.
- Olusan dizinin secilen WSL dagitimi icinde gercekten var oldugu kontrol edilir.
- Dogrudan wslpath bagimliligi kaldirilmistir.
- Windows surucu harfi PowerShell Path API ile okunur ve standart WSL2 /mnt/<drive>/... yoluna donusturulur.

Installer yeniden calistirildiginda mevcut yonetilen repo dizinini guncel stabil release ile senkronize eder.
