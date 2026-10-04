:: Dosya Yolu: /tools/portable/windows/Credentials.cmd
:: Amac: Windows portable OFBiz ilk admin giris bilgisini gosterir
:: Tool - Batch
:: Version: 1.0.0
:: Aciklama: Demo veya Runtime icin ilk admin parolasini portable data dizininden okur
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions
call "%~dp0_env.cmd"
if errorlevel 1 goto fail

if not exist "%TURKUAZ_DATA%\initial-admin-password.txt" (
    echo [TurkuazOFBiz] Ilk admin bilgisi henuz olusturulmamis.
    echo Once Start.cmd calistirin.
    goto done
)

set "ADMIN_PASSWORD="
set /p ADMIN_PASSWORD=<"%TURKUAZ_DATA%\initial-admin-password.txt"

echo.
echo Kullanici       : admin
echo Ilk parola      : %ADMIN_PASSWORD%
echo Adres           : %TURKUAZ_URL%
echo.
echo Not: Parolayi OFBiz icinde degistirdiyseniz bu dosya yalnizca ilk parolayi gosterir.

:done
pause
exit /b 0

:fail
pause
exit /b 1
