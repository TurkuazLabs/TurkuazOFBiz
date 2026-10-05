:: Dosya Yolu: /tools/portable/windows/_env.cmd
:: Amac: Windows portable TurkuazOFBiz ortak ortam degiskenlerini hazirlar
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: Modern ve legacy portable dagitimlar icin relative root, bundled Java, OFBiz lib ve data yollarini dogrular
::
:: Bagimli Oldugu Katman: Tool

@echo off

set "TURKUAZ_PORTABLE_ROOT=%~dp0"
if "%TURKUAZ_PORTABLE_ROOT:~-1%"=="\" set "TURKUAZ_PORTABLE_ROOT=%TURKUAZ_PORTABLE_ROOT:~0,-1%"

if not "%TURKUAZ_PORTABLE_ROOT: =%"=="%TURKUAZ_PORTABLE_ROOT%" (
    echo [TurkuazOFBiz] HATA: Apache OFBiz Windows yolunda bosluk desteklenmiyor.
    echo Paketi C:\TurkuazOFBiz veya E:\Apps\TurkuazOFBiz gibi bosluksuz bir yola tasiyin.
    exit /b 2
)

set "JAVA_HOME=%TURKUAZ_PORTABLE_ROOT%\java"
set "OFBIZ_HOME=%TURKUAZ_PORTABLE_ROOT%\ofbiz"
set "TURKUAZ_DATA=%TURKUAZ_PORTABLE_ROOT%\data"
set "TURKUAZ_TOOLS=%TURKUAZ_PORTABLE_ROOT%\tools"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "TURKUAZ_URL=https://localhost:8443/partymgr"

if not exist "%JAVA_HOME%\bin\java.exe" (
    echo [TurkuazOFBiz] HATA: Paket ici Java bulunamadi: %JAVA_HOME%\bin\java.exe
    exit /b 3
)

if not exist "%OFBIZ_HOME%\lib" (
    echo [TurkuazOFBiz] HATA: Portable OFBiz lib runtime bulunamadi.
    exit /b 4
)

if not exist "%TURKUAZ_DATA%" mkdir "%TURKUAZ_DATA%" >nul 2>&1

exit /b 0
