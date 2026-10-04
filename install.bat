:: Dosya Yolu: /install.bat
:: Amac: Windows kullanicisinin yerel TurkuazOFBiz PowerShell installer'ini guvenli cift tik akisi ile baslatir
:: Tool - Batch
:: Version: 2.0.1
:: Aciklama: Internetten kod indirmez, ExecutionPolicy Bypass kullanmaz, yerel PS1 blokunu kaldirir ve hata durumunda pencereyi acik tutar
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions

title TurkuazOFBiz Installer

set "INSTALLER_FILE=%~dp0TurkuazOFBiz-Installer.ps1"
set "ACTION=%~1"
set "PAUSE_MODE=%~2"

if not exist "%INSTALLER_FILE%" set "INSTALLER_FILE=%~dp0install.ps1"
if "%ACTION%"=="" set "ACTION=install"

if not exist "%INSTALLER_FILE%" (
    echo.
    echo [TurkuazOFBiz] HATA: Yerel PowerShell installer dosyasi bulunamadi.
    echo.
    echo TurkuazOFBiz-Setup.zip dosyasini tamamen bir klasore cikarin
    echo ve TurkuazOFBiz-Launcher.cmd dosyasini o klasorden calistirin.
    echo.
    pause
    exit /b 2
)

echo.
echo [TurkuazOFBiz] Yerel PowerShell installer hazirlaniyor...

powershell.exe -NoProfile -Command ^
  "Unblock-File -LiteralPath $env:INSTALLER_FILE -ErrorAction SilentlyContinue"

if errorlevel 1 (
    echo.
    echo [TurkuazOFBiz] UYARI: Dosya blok bilgisi kaldirilamadi.
    echo PowerShell sistem politikaniz imzasiz scriptleri engelliyor olabilir.
    echo.
)

powershell.exe -NoProfile -File "%INSTALLER_FILE%" -Action "%ACTION%"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo [TurkuazOFBiz] Islem tamamlandi.
) else (
    echo [TurkuazOFBiz] Installer hata ile sonlandi. Exit code: %EXIT_CODE%
    echo.
    echo Pencere hata mesajini okuyabilmeniz icin acik tutuluyor.
)

if /I not "%PAUSE_MODE%"=="nopause" pause

exit /b %EXIT_CODE%
