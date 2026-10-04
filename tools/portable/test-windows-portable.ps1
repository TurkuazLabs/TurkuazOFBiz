# Dosya Yolu: /tools/portable/test-windows-portable.ps1
# Amac: Uretilen Windows portable Demo ve Runtime paketlerini gercek HTTPS ile smoke test eder
# Tool - PowerShell
# Version: 1.0.0
# Aciklama: Paketleri acar, yerel JDK ile Start/Stop akisini kosar ve /partymgr readiness ile credential durumunu dogrular
#
# Bagimli Oldugu Katman: Tool | View

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackageDirectory,
    [string]$OFBizVersion = "24.09.07"
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

    $extract = Join-Path $env:RUNNER_TEMP ("portable-smoke-" + $Mode)
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
    $ofbiz = Join-Path $root "ofbiz\bin\ofbiz.bat"

    if (-not (Test-Path $java)) {
        Fail "$displayMode bundled Java bulunamadi."
    }
    if (-not (Test-Path $ofbiz)) {
        Fail "$displayMode bin\ofbiz.bat bulunamadi."
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

        if (-not (Test-Path $securityFlag) -or -not (Test-Path $adminKey) -or -not (Test-Path $passwordFile)) {
            Fail "$displayMode portable first-run security dosyalari eksik."
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
