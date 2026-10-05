:: Dosya Yolu: /tools/portable/windows/Start.cmd
:: Amac: Windows portable Apache OFBiz runtime'ini baslatir
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: Ilk calistirma guvenligini hazirlar, runtime admin hesabini yukler, kisa Java launcher ile readiness bekler ve tarayiciyi acar
::
:: Bagimli Oldugu Katman: Tool

@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_env.cmd"
if errorlevel 1 goto fail

set "MODE="
set /p MODE=<"%~dp0portable-mode.txt"
if not defined MODE (
    echo [TurkuazOFBiz] HATA: portable-mode.txt okunamadi.
    goto fail
)

"%JAVA_HOME%\bin\java.exe" -jar "%TURKUAZ_TOOLS%\TurkuazOFBiz-PortableHelper.jar" init "%TURKUAZ_PORTABLE_ROOT%" "%MODE%"
if errorlevel 1 goto fail

set "ADMIN_KEY="
set /p ADMIN_KEY=<"%TURKUAZ_DATA%\admin-key.txt"
if not defined ADMIN_KEY (
    echo [TurkuazOFBiz] HATA: Portable admin shutdown anahtari okunamadi.
    goto fail
)

set "TURKUAZ_ADMIN_KEY=!ADMIN_KEY!"

if /I "%MODE%"=="runtime" if not exist "%TURKUAZ_DATA%\runtime-admin-loaded.flag" (
    echo.
    echo [TurkuazOFBiz] Runtime admin hesabi ilk kez hazirlaniyor...
    call "%~dp0_ofbiz.cmd" --load-data "file=%TURKUAZ_DATA%\AdminUserLoginData.xml"
    set "LOAD_EXIT=!ERRORLEVEL!"

    if not "!LOAD_EXIT!"=="0" (
        echo [TurkuazOFBiz] HATA: Runtime admin hesabi yuklenemedi.
        goto fail
    )

    >"%TURKUAZ_DATA%\runtime-admin-loaded.flag" echo runtime admin loaded
)

where curl.exe >nul 2>&1
if not errorlevel 1 (
    set "HTTP_CODE="
    for /f "usebackq delims=" %%H in (`curl.exe --insecure --silent --output NUL --write-out "%%{http_code}" "%TURKUAZ_URL%"`) do set "HTTP_CODE=%%H"

    if "!HTTP_CODE:~0,1!"=="2" goto already_ready
    if "!HTTP_CODE:~0,1!"=="3" goto already_ready
)

echo.
echo [TurkuazOFBiz] Apache OFBiz baslatiliyor...
start "TurkuazOFBiz" /min cmd.exe /d /c call "%~dp0_ofbiz.cmd" --start

where curl.exe >nul 2>&1
if errorlevel 1 (
    timeout /t 20 /nobreak >nul
    goto ready
)

for /l %%A in (1,1,72) do (
    set "HTTP_CODE="
    for /f "usebackq delims=" %%H in (`curl.exe --insecure --silent --output NUL --write-out "%%{http_code}" "%TURKUAZ_URL%"`) do set "HTTP_CODE=%%H"

    if "!HTTP_CODE:~0,1!"=="2" goto ready
    if "!HTTP_CODE:~0,1!"=="3" goto ready

    timeout /t 5 /nobreak >nul
)

echo [TurkuazOFBiz] HATA: OFBiz 6 dakika icinde hazir olmadi.
echo Log: %OFBIZ_HOME%\runtime\logs
goto fail

:already_ready
echo [TurkuazOFBiz] OFBiz zaten calisiyor.

:ready
echo [TurkuazOFBiz] OFBiz hazir: %TURKUAZ_URL%
if not defined TURKUAZ_NO_BROWSER start "" "%TURKUAZ_URL%"
exit /b 0

:fail
echo.
echo [TurkuazOFBiz] Baslatma basarisiz.
if /I not "%~1"=="nopause" pause
exit /b 1
