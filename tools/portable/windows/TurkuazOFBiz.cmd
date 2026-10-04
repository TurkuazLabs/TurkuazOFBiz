:: Dosya Yolu: /tools/portable/windows/TurkuazOFBiz.cmd
:: Amac: Windows portable TurkuazOFBiz ana yonetim menusunu sunar
:: Tool - Batch
:: Version: 1.0.0
:: Aciklama: Start, stop, status, open ve credential islemlerini PowerShell kullanmadan yonetir
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions
cd /d "%~dp0"

:menu
cls
echo ============================================================
echo  TurkuazOFBiz Portable
echo ============================================================
echo.
echo  1 - Baslat
echo  2 - Durdur
echo  3 - Durum
echo  4 - Tarayicida Ac
echo  5 - Ilk Admin Bilgisi
echo  0 - Cikis
echo.
set /p "CHOICE=Secim: "

if "%CHOICE%"=="1" call "%~dp0Start.cmd" & goto menu
if "%CHOICE%"=="2" call "%~dp0Stop.cmd" & goto menu
if "%CHOICE%"=="3" call "%~dp0Status.cmd" & goto menu
if "%CHOICE%"=="4" call "%~dp0Open.cmd" & goto menu
if "%CHOICE%"=="5" call "%~dp0Credentials.cmd" & goto menu
if "%CHOICE%"=="0" exit /b 0

goto menu
