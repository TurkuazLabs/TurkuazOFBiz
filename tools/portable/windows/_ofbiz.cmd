:: Dosya Yolu: /tools/portable/windows/_ofbiz.cmd
:: Amac: Windows portable OFBiz'i uzun generated classpath kullanmadan bundled Java ile calistirir
:: Tool - Batch
:: Version: 1.0.0
:: Aciklama: Java wildcard classpath ile OFBiz Start ana sinifini dogrudan cagirir ve Windows komut satiri uzunluk limitini asar
::
:: Bagimli Oldugu Katman: Tool

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

set "ADMIN_OPT="
if defined TURKUAZ_ADMIN_KEY set "ADMIN_OPT=-Dofbiz.admin.key=%TURKUAZ_ADMIN_KEY%"

pushd "%OFBIZ_HOME%"
"%JAVA_HOME%\bin\java.exe" ^
  -Xms128M ^
  -Xmx1024M ^
  "-Djdk.serialFilter=maxarray=100000;maxdepth=20;maxrefs=1000;maxbytes=500000" ^
  --add-opens=java.base/java.util=ALL-UNNAMED ^
  %ADMIN_OPT% ^
  -cp "%OFBIZ_HOME%\config;%OFBIZ_HOME%\lib-extra\*;%OFBIZ_HOME%\lib\*" ^
  org.apache.ofbiz.base.start.Start %*
set "OFBIZ_EXIT=%ERRORLEVEL%"
popd

exit /b %OFBIZ_EXIT%
