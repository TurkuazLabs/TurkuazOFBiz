:: Dosya Yolu: /tools/portable/windows/Stop.cmd
:: Amac: Windows portable Apache OFBiz runtime'ini duzgun sekilde durdurur
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: Yerel admin shutdown anahtarini kisa Java launcher ile OFBiz shutdown komutuna aktarir
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions
call "%~dp0_env.cmd"
if errorlevel 1 goto fail

if not exist "%TURKUAZ_DATA%\admin-key.txt" (
    echo [TurkuazOFBiz] OFBiz henuz ilk kez baslatilmamis.
    goto done
)

set "ADMIN_KEY="
set /p ADMIN_KEY=<"%TURKUAZ_DATA%\admin-key.txt"
set "TURKUAZ_ADMIN_KEY=%ADMIN_KEY%"

call "%~dp0_ofbiz.cmd" --shutdown
set "STOP_EXIT=%ERRORLEVEL%"

if not "%STOP_EXIT%"=="0" goto fail

echo [TurkuazOFBiz] Durdurma istegi gonderildi.

:done
if /I not "%~1"=="nopause" pause
exit /b 0

:fail
echo [TurkuazOFBiz] Durdurma basarisiz.
if /I not "%~1"=="nopause" pause
exit /b 1
