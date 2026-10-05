# Dosya Yolu: /tools/portable/test-windows-portable.ps1
# Amac: Uretilen Windows portable Demo ve Runtime paketlerini gercek HTTPS ile smoke test eder
# Tool - PowerShell
# Version: 1.2.0
# Aciklama: Surum ve Java metadata dahil portable paketleri acar, Start/Stop ve /partymgr readiness akisini dogrular
#
# Bagimli Oldugu Katman: Tool | View

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackageDirectory,
    [string]$OFBizVersion = "24.09.07",
    [Parameter(Mandatory = $true)]
    [string]$ExpectedJavaMajor
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Fail {
    param([string]$Message)
    throw "[Portable Smoke] $Message"
}

function Wait-HttpsReady {
    param([int]$Attempts = 30)

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $params = @{
                Uri = "https://localhost:8443/partymgr"
                SkipCertificateCheck = $true
                MaximumRedirection = 0
                TimeoutSec = 5
                ErrorAction = "Stop"
            }
            $response = Invoke-WebRequest @params

            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                return
            }
        }
        catch {
            if ($_.Exception.Response -and
                [int]$_.Exception.Response.StatusCode -ge 300 -and
                [int]$_.Exception.Response.StatusCode -lt 400) {
                return
            }
        }

        Start-Sleep -Seconds 2
    }

    Fail "HTTPS /partymgr hazir olmadi."
}

function Wait-HttpsStopped {
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            $params = @{
                Uri = "https://localhost:8443/partymgr"
                SkipCertificateCheck = $true
                TimeoutSec = 3
                ErrorAction = "Stop"
            }
            Invoke-WebRequest @params | Out-Null
        }
        catch {
            return
        }

        Start-Sleep -Seconds 2
    }

    Fail "OFBiz shutdown sonrasi 8443 portu kapanmadi."
}

function Test-Package {
    param([string]$Mode)

    $displayMode = if ($Mode -eq "demo") { "Demo" } else { "Runtime" }
    $zipName = "TurkuazOFBiz-Portable-$OFBizVersion-$displayMode-win-x64.zip"
    $zip = Join-Path $PackageDirectory $zipName

    if (-not (Test-Path $zip)) {
        Fail "Portable paket bulunamadi: $zip"
    }

    $extract = Join-Path $env:RUNNER_TEMP ("portable-smoke-" + $OFBizVersion + "-" + $Mode)
    Remove-Item -Path $extract -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Expand-Archive -Path $zip -DestinationPath $extract -Force

    $start = Get-ChildItem -Path $extract -Recurse -Filter "Start.cmd" | Select-Object -First 1
    if (-not $start) {
        Fail "$displayMode Start.cmd bulunamadi."
    }

    $root = $start.Directory.FullName
    $stop = Join-Path $root "Stop.cmd"
    $java = Join-Path $root "java\bin\java.exe"
    $launcher = Join-Path $root "_ofbiz.cmd"
    $ofbizLib = Join-Path $root "ofbiz\lib"
    $versionFile = Join-Path $root "portable-version.txt"
    $javaMajorFile = Join-Path $root "portable-java-major.txt"
    $metadataFile = Join-Path $root "portable-metadata.properties"

    if (-not (Test-Path $java)) {
        Fail "$displayMode bundled Java bulunamadi."
    }
    if (-not (Test-Path $launcher)) {
        Fail "$displayMode _ofbiz.cmd bulunamadi."
    }
    if (-not (Test-Path $ofbizLib)) {
        Fail "$displayMode OFBiz lib klasoru bulunamadi."
    }
    if (-not (Test-Path $versionFile) -or -not (Test-Path $javaMajorFile) -or -not (Test-Path $metadataFile)) {
        Fail "$displayMode portable metadata dosyalari eksik."
    }

    $packageVersion = (Get-Content -Path $versionFile -Raw).Trim()
    $packageJavaMajor = (Get-Content -Path $javaMajorFile -Raw).Trim()
    $metadata = Get-Content -Path $metadataFile -Raw

    if ($packageVersion -ne $OFBizVersion) {
        Fail "$displayMode OFBiz metadata surumu beklenen $OFBizVersion degil: $packageVersion"
    }
    if ($packageJavaMajor -ne $ExpectedJavaMajor) {
        Fail "$displayMode Java metadata major beklenen $ExpectedJavaMajor degil: $packageJavaMajor"
    }
    if ($metadata -notmatch "(?m)^ofbiz\.version=$([regex]::Escape($OFBizVersion))$" -or
        $metadata -notmatch "(?m)^java\.major=$([regex]::Escape($ExpectedJavaMajor))$" -or
        $metadata -notmatch "(?m)^mode=$Mode$") {
        Fail "$displayMode portable metadata icerigi tutarsiz."
    }

    $javaVersionText = (& $java -version 2>&1 | Out-String)
    if ($ExpectedJavaMajor -eq "8") {
        if ($javaVersionText -notmatch 'version "1\.8\.') {
            Fail "$displayMode bundled Java 8 dogrulanamadi."
        }
    }
    elseif ($javaVersionText -notmatch ('version "' + [regex]::Escape($ExpectedJavaMajor) + '\.')) {
        Fail "$displayMode bundled Java $ExpectedJavaMajor dogrulanamadi."
    }

    $oldNoBrowser = $env:TURKUAZ_NO_BROWSER
    $env:TURKUAZ_NO_BROWSER = "1"

    try {
        Write-Host "Starting $displayMode portable package..."
        $startCommand = 'call "' + $start.FullName + '" nopause'
        & cmd.exe /d /c $startCommand
        if ($LASTEXITCODE -ne 0) {
            Fail "$displayMode Start.cmd basarisiz."
        }

        Wait-HttpsReady

        $securityFlag = Join-Path $root "data\security-initialized.flag"
        $adminKey = Join-Path $root "data\admin-key.txt"
        $passwordFile = Join-Path $root "data\initial-admin-password.txt"
        $securityOverride = Join-Path $root "ofbiz\config\security.properties"

        if (-not (Test-Path $securityFlag) -or -not (Test-Path $adminKey) -or -not (Test-Path $passwordFile)) {
            Fail "$displayMode portable first-run security dosyalari eksik."
        }

        if (-not (Test-Path $securityOverride)) {
            Fail "$displayMode security.properties classpath override olusmadi."
        }

        $securityText = Get-Content -Path $securityOverride -Raw
        if ($securityText -notmatch '(?m)^login\.secret_key_string=.{64,}$' -or
            $securityText -notmatch '(?m)^security\.token\.key=.{64,}$') {
            Fail "$displayMode login/JWT secret override dogrulanamadi."
        }

        $password = (Get-Content -Path $passwordFile -Raw).Trim()
        if ($Mode -eq "demo" -and $password -ne "ofbiz") {
            Fail "Demo admin parolasi beklenen ofbiz degeri degil."
        }

        if ($Mode -eq "runtime") {
            if ($password.Length -lt 24 -or $password -eq "ofbiz") {
                Fail "Runtime admin parolasi guclu yerel parola olarak uretilmedi."
            }

            if (-not (Test-Path (Join-Path $root "data\runtime-admin-loaded.flag"))) {
                Fail "Runtime admin import marker olusmadi."
            }
        }

        Write-Host "Stopping $displayMode portable package..."
        $stopCommand = 'call "' + $stop + '" nopause'
        & cmd.exe /d /c $stopCommand
        if ($LASTEXITCODE -ne 0) {
            Fail "$displayMode Stop.cmd basarisiz."
        }

        Wait-HttpsStopped
    }
    finally {
        $env:TURKUAZ_NO_BROWSER = $oldNoBrowser
    }

    Write-Host "$displayMode portable smoke SUCCESS" -ForegroundColor Green
}

Test-Package -Mode "demo"
Test-Package -Mode "runtime"
