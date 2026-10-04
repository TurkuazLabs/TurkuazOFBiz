:: Dosya Yolu: /tools/portable/windows/Open.cmd
:: Amac: Windows portable OFBiz uygulama adresini varsayilan tarayicida acar
:: Tool - Batch
:: Version: 1.0.0
:: Aciklama: Yerel HTTPS partymgr endpoint'ini acar
::
:: Bagimli Oldugu Katman: Tool

@echo off
start "" "https://localhost:8443/partymgr"
exit /b 0
