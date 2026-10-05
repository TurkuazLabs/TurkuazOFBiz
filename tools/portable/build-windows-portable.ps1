# Dosya Yolu: /tools/portable/build-windows-portable.ps1
# Amac: Apache OFBiz ve Temurin JDK iceren Windows x64 portable release paketlerini uretir
# Tool - PowerShell
# Version: 1.1.0
# Aciklama: Apache release checksum dogrular, distZip olusturur, Java wildcard launcher ile Demo/Runtime preload eder ve portable ZIP/SHA-256 uretir
#
# Bagimli Oldugu Katman: Tool | Config | View

[CmdletBinding()]
param(
    [string]$OFBizVersion = "24.09.07",
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [string]$BundledJavaHome = $env:JAVA_HOME
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$PortableSource = Join-Path $RepoRoot "tools\portable"
$WindowsTemplate = Join-Path $PortableSource "windows"

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "[Portable] $Message" -ForegroundColor Cyan
}

function Fail {
    param([string]$Message)

    throw "[Portable] $Message"
}

function Download-WithFallback {
    param(
        [string[]]$Urls,
        [string]$Destination
    )

    foreach ($url in $Urls) {
        try {
            Write-Host "Download: $url"
            Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing
            return $url
        }
        catch {
            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
            Write-Warning "Download basarisiz: $url"
        }
    }

    Fail "Dosya indirilemedi: $Destination"
}

function Verify-ApacheChecksum {
    param(
        [string]$Archive,
        [string]$ChecksumFile
    )

    $checksumText = Get-Content -Path $ChecksumFile -Raw
    $match = [regex]::Match($checksumText, "(?i)[a-f0-9]{128}")
    $expected = ""

    if ($match.Success) {
        $expected = $match.Value.ToLowerInvariant()
    }
    elseif ($checksumText.Contains(":")) {
        $payload = $checksumText.Substring($checksumText.IndexOf(":") + 1)
        $groupedHex = $payload -replace "[^A-Fa-f0-9]", ""

        if ($groupedHex.Length -ge 128) {
            $expected = $groupedHex.Substring(0, 128).ToLowerInvariant()
        }
    }

    if (-not $expected) {
        Fail "Apache SHA-512 degeri okunamadi: $ChecksumFile"
    }

    $actual = (Get-FileHash -Path $Archive -Algorithm SHA512).Hash.ToLowerInvariant()

    if ($expected -ne $actual) {
        Fail "Apache OFBiz SHA-512 dogrulamasi basarisiz."
    }
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -Path $Source -Force | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Build-PortableHelper {
    param(
        [string]$WorkDirectory
    )

    $classes = Join-Path $WorkDirectory "helper-classes"
    $jarFile = Join-Path $WorkDirectory "TurkuazOFBiz-PortableHelper.jar"
    $javac = Join-Path $BundledJavaHome "bin\javac.exe"
    $jar = Join-Path $BundledJavaHome "bin\jar.exe"
    $source = Join-Path $PortableSource "PortableBootstrap.java"

    New-Item -ItemType Directory -Force -Path $classes | Out-Null

    & $javac -encoding UTF-8 -d $classes $source
    if ($LASTEXITCODE -ne 0) {
        Fail "Portable helper javac derlemesi basarisiz."
    }

    & $jar --create --file $jarFile --main-class org.turkuazlabs.ofbiz.portable.PortableBootstrap -C $classes .
    if ($LASTEXITCODE -ne 0) {
        Fail "Portable helper JAR olusturulamadi."
    }

    return $jarFile
}

function Write-PortableReadme {
    param(
        [string]$Root,
        [string]$Mode
    )

    $modeText = if ($Mode -eq "demo") {
        "Demo: Apache OFBiz demo verisi onceden yukludur. Ilk giris admin / ofbiz."
    }
    else {
        "Runtime: Seed veri onceden yukludur. Ilk Start.cmd calismasinda guclu admin parolasi yerel olarak uretilir."
    }

    @"
TurkuazOFBiz Portable Windows x64
================================

OFBiz: $OFBizVersion
Mod  : $Mode

$modeText

Kullanim:
1. ZIP'i tamamen bosluksuz bir Windows yoluna cikarin.
   Ornek: C:\TurkuazOFBiz veya E:\Apps\TurkuazOFBiz
2. TurkuazOFBiz.cmd dosyasina cift tiklayin.
3. Menu: Baslat / Durdur / Durum / Tarayicida Ac / Ilk Admin Bilgisi.

Gereksinim:
- Windows x64
- Docker YOK
- WSL YOK
- Sistem Java kurulumu YOK
- PowerShell script calistirma YOK

Paket kendi Temurin JDK 17 runtime'ini tasir.

Adres:
https://localhost:8443/partymgr

Not:
Apache OFBiz Windows tarafinda bosluk bulunan kurulum yollarini desteklemez.
Runtime modunda ilk parola OFBiz icinde degistirildikten sonra data\initial-admin-password.txt
yalnizca ilk parolayi temsil eder.
"@ | Set-Content -Path (Join-Path $Root "README-FIRST.txt") -Encoding UTF8
}

function Invoke-PortableOFBiz {
    param(
        [string]$PortableRoot,
        [string[]]$OFBizArguments
    )

    $ofbizHome = Join-Path $PortableRoot "ofbiz"
    $javaHome = Join-Path $PortableRoot "java"
    $java = Join-Path $javaHome "bin\java.exe"
    $libDir = Join-Path $ofbizHome "lib"
    $configDir = Join-Path $ofbizHome "config"
    $libExtraDir = Join-Path $ofbizHome "lib-extra"

    if (-not (Test-Path $java)) {
        Fail "Portable Java bulunamadi: $java"
    }

    if (-not (Test-Path $libDir)) {
        Fail "Portable OFBiz lib klasoru bulunamadi: $libDir"
    }

    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    New-Item -ItemType Directory -Force -Path $libExtraDir | Out-Null

    $classpath = "$configDir;$libExtraDir\*;$libDir\*"
    $javaArguments = @(
        "-Xms128M",
        "-Xmx1024M",
        "-Djdk.serialFilter=maxarray=100000;maxdepth=20;maxrefs=1000;maxbytes=500000",
        "--add-opens=java.base/java.util=ALL-UNNAMED",
        "-cp",
        $classpath,
        "org.apache.ofbiz.base.start.Start"
    ) + $OFBizArguments

    Push-Location $ofbizHome
    try {
        & $java @javaArguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        Fail "Portable OFBiz Java islemi basarisiz. Exit code: $exitCode"
    }
}

function Preload-OFBizData {
    param(
        [string]$PortableRoot,
        [string]$Mode
    )

    if ($Mode -eq "demo") {
        Write-Step "Demo verisi preload ediliyor"
        Invoke-PortableOFBiz -PortableRoot $PortableRoot -OFBizArguments @("--load-data")
    }
    else {
        Write-Step "Runtime seed verisi preload ediliyor"
        Invoke-PortableOFBiz -PortableRoot $PortableRoot -OFBizArguments @(
            "--load-data",
            "readers=seed,seed-initial"
        )
    }

    $ofbizHome = Join-Path $PortableRoot "ofbiz"

    foreach ($cleanup in @(
        (Join-Path $ofbizHome "runtime\logs"),
        (Join-Path $ofbizHome "runtime\tmp"),
        (Join-Path $ofbizHome "runtime\tempfiles")
    )) {
        if (Test-Path $cleanup) {
            Get-ChildItem -Path $cleanup -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-PortablePackage {
    param(
        [string]$Mode,
        [string]$DistributionRoot,
        [string]$HelperJar,
        [string]$WorkDirectory
    )

    $displayMode = if ($Mode -eq "demo") { "Demo" } else { "Runtime" }
    $folderName = "TurkuazOFBiz-Portable-$OFBizVersion-$displayMode-win-x64"
    $root = Join-Path $WorkDirectory $folderName

    Write-Step "$displayMode portable klasoru hazirlaniyor"
    New-Item -ItemType Directory -Force -Path $root | Out-Null

    Copy-DirectoryContents -Source $DistributionRoot -Destination (Join-Path $root "ofbiz")
    Copy-DirectoryContents -Source $BundledJavaHome -Destination (Join-Path $root "java")

    New-Item -ItemType Directory -Force -Path (Join-Path $root "tools") | Out-Null
    Copy-Item -Path $HelperJar -Destination (Join-Path $root "tools\TurkuazOFBiz-PortableHelper.jar") -Force

    foreach ($file in @(
        "TurkuazOFBiz.cmd",
        "_env.cmd",
        "_ofbiz.cmd",
        "Start.cmd",
        "Stop.cmd",
        "Status.cmd",
        "Open.cmd",
        "Credentials.cmd"
    )) {
        Copy-Item -Path (Join-Path $WindowsTemplate $file) -Destination (Join-Path $root $file) -Force
    }

    $Mode | Set-Content -Path (Join-Path $root "portable-mode.txt") -Encoding ASCII
    $OFBizVersion | Set-Content -Path (Join-Path $root "portable-version.txt") -Encoding ASCII
    New-Item -ItemType Directory -Force -Path (Join-Path $root "data") | Out-Null

    Write-PortableReadme -Root $root -Mode $Mode
    Preload-OFBizData -PortableRoot $root -Mode $Mode

    $zip = Join-Path $OutputDirectory "$folderName.zip"
    Remove-Item -Path $zip -Force -ErrorAction SilentlyContinue

    Write-Step "$displayMode portable ZIP olusturuluyor"
    Compress-Archive -Path $root -DestinationPath $zip -CompressionLevel Optimal

    $hash = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([IO.Path]::GetFileName($zip))" |
        Set-Content -Path "$zip.sha256" -Encoding ASCII

    return $zip
}

if (-not $BundledJavaHome -or -not (Test-Path (Join-Path $BundledJavaHome "bin\javac.exe"))) {
    Fail "Windows JDK bulunamadi: $BundledJavaHome"
}

$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$work = Join-Path ([IO.Path]::GetTempPath()) ("TurkuazOFBiz-Portable-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null

try {
    $archive = Join-Path $work "apache-ofbiz-$OFBizVersion.zip"
    $checksum = "$archive.sha512"

    $baseNames = @(
        "https://dlcdn.apache.org/ofbiz",
        "https://archive.apache.org/dist/ofbiz"
    )

    $archiveUrls = @($baseNames | ForEach-Object { "$_/apache-ofbiz-$OFBizVersion.zip" })
    $checksumUrls = @($baseNames | ForEach-Object { "$_/apache-ofbiz-$OFBizVersion.zip.sha512" })

    Write-Step "Apache OFBiz $OFBizVersion indiriliyor"
    Download-WithFallback -Urls $archiveUrls -Destination $archive | Out-Null
    Download-WithFallback -Urls $checksumUrls -Destination $checksum | Out-Null
    Verify-ApacheChecksum -Archive $archive -ChecksumFile $checksum

    $sourceExtract = Join-Path $work "source"
    Expand-Archive -Path $archive -DestinationPath $sourceExtract -Force

    $sourceRoot = Get-ChildItem -Path $sourceExtract -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "gradlew.bat") } |
        Select-Object -First 1

    if (-not $sourceRoot) {
        Fail "Apache OFBiz source root bulunamadi."
    }

    Write-Step "Gradle wrapper hazirlaniyor"
    Push-Location $sourceRoot.FullName
    try {
        & (Join-Path $sourceRoot.FullName "gradle\init-gradle-wrapper.ps1")

        $wrapperJar = Join-Path $sourceRoot.FullName "gradle\wrapper\gradle-wrapper.jar"
        if (-not (Test-Path $wrapperJar)) {
            Fail "Gradle wrapper hazirlanamadi: gradle-wrapper.jar bulunamadi."
        }

        Write-Step "Apache OFBiz distZip derleniyor"
        & (Join-Path $sourceRoot.FullName "gradlew.bat") --no-daemon distZip
        if ($LASTEXITCODE -ne 0) {
            Fail "Apache OFBiz distZip build basarisiz."
        }
    }
    finally {
        Pop-Location
    }

    $distZip = Get-ChildItem -Path (Join-Path $sourceRoot.FullName "build\distributions") -Filter "*.zip" |
        Select-Object -First 1

    if (-not $distZip) {
        Fail "OFBiz distZip artefakti bulunamadi."
    }

    $distExtract = Join-Path $work "distribution"
    Expand-Archive -Path $distZip.FullName -DestinationPath $distExtract -Force

    $ofbizBat = Get-ChildItem -Path $distExtract -Recurse -Filter "ofbiz.bat" |
        Where-Object { $_.Directory.Name -eq "bin" } |
        Select-Object -First 1

    if (-not $ofbizBat) {
        Fail "distZip icinde bin\ofbiz.bat bulunamadi."
    }

    $distributionRoot = $ofbizBat.Directory.Parent.FullName

    if (-not (Test-Path (Join-Path $distributionRoot "framework\security\config\security.properties"))) {
        Fail "Portable distribution security.properties dosyasini tasimiyor."
    }

    Write-Step "Portable Java helper derleniyor"
    $helperJar = Build-PortableHelper -WorkDirectory $work

    $demoZip = New-PortablePackage -Mode "demo" -DistributionRoot $distributionRoot -HelperJar $helperJar -WorkDirectory $work
    $runtimeZip = New-PortablePackage -Mode "runtime" -DistributionRoot $distributionRoot -HelperJar $helperJar -WorkDirectory $work

    Write-Host ""
    Write-Host "Portable paketler hazir:" -ForegroundColor Green
    Write-Host "  $demoZip"
    Write-Host "  $runtimeZip"
}
finally {
    Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
}
