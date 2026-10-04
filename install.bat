:: Dosya Yolu: /install.bat
:: Amac: Windows kullanicisinin TurkuazOFBiz installer'ini cift tikla baslatmasini saglar
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: Son stabil release PowerShell installer asset'ini gecici dizine indirir ve secilen action ile calistirir
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal

set "INSTALLER_URL=https://github.com/TurkuazLabs/TurkuazOFBiz/releases/latest/download/TurkuazOFBiz-Installer.ps1"
set "INSTALLER_FILE=%TEMP%\TurkuazOFBiz-install.ps1"
set "ACTION=%~1"

if "%ACTION%"=="" set "ACTION=install"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%INSTALLER_URL%' -OutFile '%INSTALLER_FILE%'; & '%INSTALLER_FILE%' -Action '%ACTION%'"

set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo TurkuazOFBiz installer hata ile sonlandi.
  pause
)

exit /b %EXIT_CODE%
