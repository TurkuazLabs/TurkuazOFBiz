:: Dosya Yolu: /tools/portable/windows/_ofbiz.cmd
:: Amac: Windows portable OFBiz'i uzun generated classpath kullanmadan bundled Java ile calistirir
:: Tool - Batch
:: Version: 1.1.0
:: Aciklama: Java 8-17 uyumlu wildcard classpath launcher ile OFBiz Start ana sinifini dogrudan cagirir
::
:: Bagimli Oldugu Katman: Tool | Config

@echo off
setlocal EnableExtensions
call "%~dp0_env.cmd"
if errorlevel 1 exit /b %ERRORLEVEL%

if not exist "%OFBIZ_HOME%\lib" (
    echo [TurkuazOFBiz] HATA: OFBiz lib klasoru bulunamadi.
    exit /b 5
)

if not exist "%OFBIZ_HOME%\config" mkdir "%OFBIZ_HOME%\config" >nul 2>&1
if not exist "%OFBIZ_HOME%\lib-extra" mkdir "%OFBIZ_HOME%\lib-extra" >nul 2>&1

set "JAVA_MAJOR="
if exist "%TURKUAZ_PORTABLE_ROOT%\portable-java-major.txt" set /p JAVA_MAJOR=<"%TURKUAZ_PORTABLE_ROOT%\portable-java-major.txt"
if not defined JAVA_MAJOR (
    echo [TurkuazOFBiz] HATA: portable-java-major.txt okunamadi.
    exit /b 6
)

set "ADMIN_OPT="
if defined TURKUAZ_ADMIN_KEY set "ADMIN_OPT=-Dofbiz.admin.key=%TURKUAZ_ADMIN_KEY%"

set "MODULE_OPT="
if not "%JAVA_MAJOR%"=="8" set "MODULE_OPT=--add-opens=java.base/java.util=ALL-UNNAMED"

pushd "%OFBIZ_HOME%"
"%JAVA_HOME%\bin\java.exe" ^
  -Xms128M ^
  -Xmx1024M ^
  "-Djdk.serialFilter=maxarray=100000;maxdepth=20;maxrefs=1000;maxbytes=500000" ^
  %MODULE_OPT% ^
  %ADMIN_OPT% ^
  -cp "%OFBIZ_HOME%\config;%OFBIZ_HOME%\lib-extra\*;%OFBIZ_HOME%\lib\*" ^
  org.apache.ofbiz.base.start.Start %*
set "OFBIZ_EXIT=%ERRORLEVEL%"
popd

exit /b %OFBIZ_EXIT%
