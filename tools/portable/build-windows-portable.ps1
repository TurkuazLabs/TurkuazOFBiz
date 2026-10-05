# Dosya Yolu: /tools/portable/build-windows-portable.ps1
# Amac: Apache OFBiz ve Temurin JDK iceren Windows x64 portable release paketlerini uretir
# Tool - PowerShell
# Version: 1.3.1
# Aciklama: Modern distZip ve legacy runtime staging stratejilerini secerek Java 8-17 uyumlu portable ZIP ve SHA-256 uretir
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
$VersionsConfig = Join-Path $RepoRoot "config\versions.conf"
$LegacyStageInit = Join-Path $PortableSource "legacy-stage.init.gradle"

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "[Portable] $Message" -ForegroundColor Cyan
}

function Fail {
    param([string]$Message)

    throw "[Portable] $Message"
}

function Get-ConfigValue {
    param([string]$Name)

    $pattern = '(?m)^' + [regex]::Escape($Name) + '="([^"]*)"'
    $text = Get-Content -Path $VersionsConfig -Raw
    $match = [regex]::Match($text, $pattern)

    if (-not $match.Success) {
        Fail "Config degeri bulunamadi: $Name"
    }

    return $match.Groups[1].Value
}

function Test-VersionInCatalog {
    param([string]$Version)

    foreach ($series in @("24_09", "18_12", "17_12")) {
        $releases = Get-ConfigValue -Name "OFBIZ_RELEASES_$series"
        if (($releases -split '\s+') -contains $Version) {
            return $true
        }
    }

    return $false
}

function Get-PortableJavaMajor {
    param([string]$Version)

    if (-not (Test-VersionInCatalog -Version $Version)) {
        Fail "Portable icin desteklenmeyen OFBiz release: $Version"
    }

    if ($Version.StartsWith("24.09.")) {
        return Get-ConfigValue -Name "OFBIZ_JAVA_24_09"
    }
    if ($Version.StartsWith("18.12.")) {
        return Get-ConfigValue -Name "OFBIZ_JAVA_18_12"
    }
    if ($Version.StartsWith("17.12.")) {
        return Get-ConfigValue -Name "OFBIZ_JAVA_17_12"
    }

    Fail "OFBiz Java major eslemesi bulunamadi: $Version"
}

function Get-JavaHomeMajor {
    param([string]$JavaHome)

    $java = Join-Path $JavaHome "bin\java.exe"
    if (-not (Test-Path $java)) {
        Fail "Bundled Java bulunamadi: $java"
    }

    $versionText = (& $java -version 2>&1 | Out-String)

    if ($versionText -match 'version "1\.8\.') {
        return "8"
    }
    if ($versionText -match 'version "([0-9]+)\.') {
        return $matches[1]
    }

    Fail "Bundled Java major okunamadi: $versionText"
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

function Copy-LegacyDistributionTree {
    param(
        [string]$Source,
        [string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    Get-ChildItem -Path $Source -Force |
        Where-Object { $_.Name -notin @("build", ".gradle") } |
        ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $Destination -Recurse -Force
        }
}

function Initialize-GradleWrapper {
    param([string]$SourceRoot)

    Write-Step "Gradle wrapper hazirlaniyor"
    Push-Location $SourceRoot
    try {
        & (Join-Path $SourceRoot "gradle\init-gradle-wrapper.ps1")

        $wrapperJar = Join-Path $SourceRoot "gradle\wrapper\gradle-wrapper.jar"
        if (-not (Test-Path $wrapperJar)) {
            Fail "Gradle wrapper hazirlanamadi: gradle-wrapper.jar bulunamadi."
        }
    }
    finally {
        Pop-Location
    }
}

function Build-ModernDistribution {
    param(
        [string]$SourceRoot,
        [string]$WorkDirectory
    )

    Push-Location $SourceRoot
    try {
        Write-Step "Apache OFBiz distZip derleniyor"
        & (Join-Path $SourceRoot "gradlew.bat") --no-daemon distZip | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Fail "Apache OFBiz distZip build basarisiz."
        }
    }
    finally {
        Pop-Location
    }

    $distZip = Get-ChildItem -Path (Join-Path $SourceRoot "build\distributions") -Filter "*.zip" |
        Select-Object -First 1

    if (-not $distZip) {
        Fail "OFBiz distZip artefakti bulunamadi."
    }

    $distExtract = Join-Path $WorkDirectory "distribution"
    Expand-Archive -Path $distZip.FullName -DestinationPath $distExtract -Force

    $ofbizBat = Get-ChildItem -Path $distExtract -Recurse -Filter "ofbiz.bat" |
        Where-Object { $_.Directory.Name -eq "bin" } |
        Select-Object -First 1

    if (-not $ofbizBat) {
        Fail "distZip icinde bin\ofbiz.bat bulunamadi."
    }

    return $ofbizBat.Directory.Parent.FullName
}

function Build-LegacyDistribution {
    param(
        [string]$SourceRoot,
        [string]$WorkDirectory
    )

    $legacyRoot = Join-Path $WorkDirectory "legacy-distribution"
    $legacyLib = Join-Path $legacyRoot "lib"

    Write-Step "Legacy OFBiz kaynak agaci portable staging alanina kopyalaniyor"
    Copy-LegacyDistributionTree -Source $SourceRoot -Destination $legacyRoot
    New-Item -ItemType Directory -Force -Path $legacyLib | Out-Null

    Push-Location $SourceRoot
    try {
        Write-Step "Legacy OFBiz root JAR ve runtime bagimliliklari staging alani icin derleniyor"
        & (Join-Path $SourceRoot "gradlew.bat") --no-daemon -I $LegacyStageInit "-Dturkuaz.portable.lib=$legacyLib" turkuazPortableStage | Out-Host

        if ($LASTEXITCODE -ne 0) {
            Fail "Legacy OFBiz portable runtime staging basarisiz."
        }
    }
    finally {
        Pop-Location
    }

    $rootJar = Get-ChildItem -Path $legacyLib -Filter "ofbiz*.jar" |
        Select-Object -First 1

    if (-not $rootJar) {
        Fail "Legacy portable root OFBiz JAR bulunamadi."
    }

    return $legacyRoot
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

    & $javac -encoding UTF-8 -source 8 -target 8 -d $classes $source
    if ($LASTEXITCODE -ne 0) {
        Fail "Portable helper javac derlemesi basarisiz."
    }

    & $jar cfe $jarFile org.turkuazlabs.ofbiz.portable.PortableBootstrap -C $classes .
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

Paket kendi Temurin JDK $PortableJavaMajor runtime'ini tasir.

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
        "-Djdk.serialFilter=maxarray=100000;maxdepth=20;maxrefs=1000;maxbytes=500000"
    )

    if ($PortableJavaMajor -ne "8") {
        $javaArguments += "--add-opens=java.base/java.util=ALL-UNNAMED"
    }

    $javaArguments += @(
        "-cp",
        $classpath,
        "org.apache.ofbiz.base.start.Start"
    )
    $javaArguments += $OFBizArguments

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
    $PortableJavaMajor | Set-Content -Path (Join-Path $root "portable-java-major.txt") -Encoding ASCII
    @(
        "ofbiz.version=$OFBizVersion",
        "java.major=$PortableJavaMajor",
        "mode=$Mode",
        "platform=windows-x64"
    ) | Set-Content -Path (Join-Path $root "portable-metadata.properties") -Encoding ASCII
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

$PortableJavaMajor = Get-PortableJavaMajor -Version $OFBizVersion

if (-not $BundledJavaHome -or -not (Test-Path (Join-Path $BundledJavaHome "bin\javac.exe"))) {
    Fail "Windows JDK bulunamadi: $BundledJavaHome"
}

$ActualJavaMajor = Get-JavaHomeMajor -JavaHome $BundledJavaHome
if ($ActualJavaMajor -ne $PortableJavaMajor) {
    Fail "OFBiz $OFBizVersion Java $PortableJavaMajor gerektiriyor; verilen JDK Java $ActualJavaMajor."
}

Write-Step "Portable hedef: OFBiz $OFBizVersion / Java $PortableJavaMajor"

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

    Initialize-GradleWrapper -SourceRoot $sourceRoot.FullName

    if ($OFBizVersion.StartsWith("17.12.")) {
        $distributionRoot = Build-LegacyDistribution -SourceRoot $sourceRoot.FullName -WorkDirectory $work
    }
    else {
        $distributionRoot = Build-ModernDistribution -SourceRoot $sourceRoot.FullName -WorkDirectory $work
    }

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
