:: Dosya Yolu: /tools/portable/windows/Status.cmd
:: Amac: Windows portable Apache OFBiz runtime durumunu gosterir
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: OFBiz admin status komutunu portable shutdown anahtari ve kisa Java launcher ile calistirir
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions
call "%~dp0_env.cmd"
if errorlevel 1 goto fail

if not exist "%TURKUAZ_DATA%\admin-key.txt" (
    if /I not "%~1"=="quiet" echo [TurkuazOFBiz] OFBiz henuz ilk kez baslatilmamis.
    exit /b 1
)

set "ADMIN_KEY="
set /p ADMIN_KEY=<"%TURKUAZ_DATA%\admin-key.txt"
set "TURKUAZ_ADMIN_KEY=%ADMIN_KEY%"

call "%~dp0_ofbiz.cmd" --status
set "STATUS_EXIT=%ERRORLEVEL%"

if /I not "%~1"=="quiet" pause
exit /b %STATUS_EXIT%

:fail
if /I not "%~1"=="quiet" pause
exit /b 1
