# Dosya Yolu: /install.ps1
# Amac: Windows kullanicisi icin TurkuazOFBiz ve OFBiz Docker kurulumunu tek komutta yonetir
# Tool - PowerShell
# Version: 1.1.0
# Aciklama: Stabil TurkuazOFBiz release'ini indirir, WSL/Docker'i hazirlar, OFBiz 24.09.07 demo container'ini baslatir ve tarayiciyi acar
#
# Bagimli Oldugu Katman: Tool | Controller | Service | Config

[CmdletBinding()]
param(
    [ValidateSet("install", "start", "stop", "status", "doctor", "open")]
    [string]$Action = "install",
    [string]$Distro = "",
    [string]$OFBizVersion = "24.09.07",
    [ValidateSet("runtime", "demo")]
    [string]$Variant = "demo",
    [ValidateRange(1, 65535)]
    [int]$HttpsPort = 8443
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRepository = "TurkuazLabs/TurkuazOFBiz"
$ProjectApi = "https://api.github.com/repos/$ProjectRepository"
$ProjectUrl = "https://github.com/$ProjectRepository"
$InstallRoot = Join-Path $env:LOCALAPPDATA "TurkuazOFBiz"
$ManagedRepo = Join-Path $InstallRoot "repo"
$SecretFile = Join-Path $InstallRoot "admin-password.txt"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "TurkuazOFBiz.lnk"
$DefaultAppPath = "/partymgr"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "[TurkuazOFBiz] $Message" -ForegroundColor Cyan
}

function Fail {
    param([string]$Message)
    throw "[TurkuazOFBiz] $Message"
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-LatestReleaseTag {
    Write-Step "En son stabil TurkuazOFBiz surumu kontrol ediliyor"
    $headers = @{
        "User-Agent" = "TurkuazOFBiz-Installer"
        "Accept" = "application/vnd.github+json"
    }
    $release = Invoke-RestMethod -Uri "$ProjectApi/releases/latest" -Headers $headers
    if (-not $release.tag_name) {
        Fail "GitHub latest release bilgisi alinamadi."
    }
    return [string]$release.tag_name
}

function Sync-ManagedRepo {
    $tag = Get-LatestReleaseTag
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("TurkuazOFBiz-" + [Guid]::NewGuid().ToString("N"))
    $zipFile = Join-Path $tempRoot "TurkuazOFBiz.zip"
    $extractDir = Join-Path $tempRoot "extract"
    $archiveUrl = "$ProjectUrl/archive/refs/tags/$tag.zip"

    Write-Step "$tag indiriliyor"
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    New-Item -ItemType Directory -Force -Path $ManagedRepo | Out-Null

    try {
        Invoke-WebRequest -Uri $archiveUrl -OutFile $zipFile -UseBasicParsing
        Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

        $sourceRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
        if (-not $sourceRoot) {
            Fail "Indirilen release arsivi acilamadi."
        }

        Get-ChildItem -Path $ManagedRepo -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "install.bat" } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        Copy-Item -Path (Join-Path $sourceRoot.FullName "*") -Destination $ManagedRepo -Recurse -Force
        Write-Host "Stabil proje surumu hazir: $tag"
    }
    finally {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-WslDistros {
    if (-not (Test-Command "wsl.exe")) {
        Fail "WSL bulunamadi. Windows WSL2 kurulu olmali."
    }

    $items = @(
        & wsl.exe -l -q 2>$null |
            ForEach-Object { ($_ -replace [char]0, "").Trim() } |
            Where-Object {
                $_ -and
                $_ -notmatch "^docker-desktop" -and
                $_ -notmatch "^docker-desktop-data"
            }
    )

    return $items
}

function Resolve-WslDistro {
    $distros = @(Get-WslDistros)
    if ($distros.Count -eq 0) {
        Fail "Kullanilabilir WSL Linux dagitimi bulunamadi. Ubuntu-24.04 kurulu olmali."
    }

    if ($Distro) {
        if ($distros -notcontains $Distro) {
            Fail "WSL dagitimi bulunamadi: $Distro"
        }
        return $Distro
    }

    foreach ($preferred in @("Ubuntu-24.04", "Ubuntu")) {
        if ($distros -contains $preferred) {
            return $preferred
        }
    }

    return [string]$distros[0]
}

function Convert-ToWslPath {
    param(
        [string]$WindowsPath,
        [string]$LinuxDistro
    )

    if ($WindowsPath.Length -lt 3 -or $WindowsPath.Substring(1, 1) -ne ":") {
        Fail "Desteklenmeyen Windows yolu: $WindowsPath"
    }

    $drive = $WindowsPath.Substring(0, 1).ToLowerInvariant()
    $relative = $WindowsPath.Substring(3).Replace([char]92, [char]47)
    $result = "/mnt/$drive/$relative"

    & wsl.exe -d $LinuxDistro -- test -d $result 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "Windows yolu WSL icinde bulunamadi: $WindowsPath -> $result"
    }

    return $result
}

function Invoke-WslBash {
    param(
        [string]$LinuxDistro,
        [string]$Command,
        [switch]$AllowFailure
    )

    & wsl.exe -d $LinuxDistro -- bash -lc $Command
    $exitCode = $LASTEXITCODE

    if (-not $AllowFailure -and $exitCode -ne 0) {
        Fail "WSL komutu basarisiz oldu. Exit code: $exitCode"
    }
}

function Start-DockerDesktop {
    $dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dockerDesktop)) {
        Fail "Docker Desktop bulunamadi: $dockerDesktop"
    }

    $running = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $running) {
        Write-Step "Docker Desktop baslatiliyor"
        Start-Process -FilePath $dockerDesktop | Out-Null
    }
}

function Wait-DockerReady {
    param([string]$LinuxDistro)

    $ready = $false
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        & wsl.exe -d $LinuxDistro -- bash -lc "docker info >/dev/null 2>&1"
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            break
        }
        Start-Sleep -Seconds 2
    }

    if (-not $ready) {
        Fail "Docker WSL icinden erisilebilir hale gelmedi. Docker Desktop WSL integration ayarini kontrol edin."
    }
}

function Ensure-Docker {
    param([string]$LinuxDistro)

    & wsl.exe -d $LinuxDistro -- bash -lc "docker info >/dev/null 2>&1"
    if ($LASTEXITCODE -eq 0) {
        return
    }

    Start-DockerDesktop
    Wait-DockerReady -LinuxDistro $LinuxDistro
}

function New-AdminPassword {
    $alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }

    $chars = foreach ($byte in $bytes) {
        $alphabet[$byte % $alphabet.Length]
    }
    return -join $chars
}

function Get-AdminPassword {
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

    if (Test-Path $SecretFile) {
        $existing = (Get-Content -Path $SecretFile -Raw).Trim()
        if ($existing) {
            return $existing
        }
    }

    $password = New-AdminPassword
    Set-Content -Path $SecretFile -Value $password -Encoding ASCII
    return $password
}

function Get-ContainerName {
    return "ofbiz-release-" + ($OFBizVersion -replace "\.", "-")
}

function Ensure-DesktopShortcut {
    if (-not (Test-Path (Join-Path $ManagedRepo "install.bat"))) {
        return
    }

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($DesktopShortcut)
        $shortcut.TargetPath = Join-Path $ManagedRepo "install.bat"
        $shortcut.Arguments = "start"
        $shortcut.WorkingDirectory = $ManagedRepo
        $shortcut.Description = "TurkuazOFBiz baslat"
        $shortcut.Save()
    }
    catch {
        Write-Warning "Masaustu kisayolu olusturulamadi: $($_.Exception.Message)"
    }
}

function Get-OFBizUrl {
    return "https://localhost:$HttpsPort$DefaultAppPath"
}

function Wait-OFBizReady {
    param([string]$LinuxDistro)

    $url = Get-OFBizUrl

    for ($attempt = 1; $attempt -le 72; $attempt++) {
        $command = "curl --insecure --silent --output /dev/null --write-out '%{http_code}' '$url' 2>/dev/null || true"
        $httpCode = & wsl.exe -d $LinuxDistro -- bash -lc $command
        $httpCode = ([string]$httpCode).Trim()

        if ($httpCode -match '^[23][0-9][0-9]$') {
            Write-Host "[TurkuazOFBiz] OFBiz hazir: HTTP $httpCode"
            return
        }

        Start-Sleep -Seconds 5
    }

    Fail "OFBiz HTTPS hazirlik zaman asimina ugradi: $url"
}

function Open-OFBiz {
    Start-Process (Get-OFBizUrl) | Out-Null
}

function Invoke-Install {
    Sync-ManagedRepo
    $linuxDistro = Resolve-WslDistro
    Write-Step "WSL dagitimi: $linuxDistro"
    Ensure-Docker -LinuxDistro $linuxDistro

    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro
    $password = Get-AdminPassword

    Write-Step "Docker ortam kontrolu"
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"

    Write-Step "Apache OFBiz $OFBizVersion $Variant image hazirlaniyor"
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh docker pull release '$OFBizVersion' '$Variant'"

    Write-Step "Apache OFBiz baslatiliyor"
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && OFBIZ_ADMIN_PASSWORD='$password' OFBIZ_HTTPS_PORT='$HttpsPort' bash controllers/ofbiz.sh docker run release '$OFBizVersion' '$Variant'"

    Wait-OFBizReady -LinuxDistro $linuxDistro
    Ensure-DesktopShortcut

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " TurkuazOFBiz hazir" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " Adres       : $(Get-OFBizUrl)"
    Write-Host " Kullanici   : admin"
    Write-Host " Parola      : $password"
    Write-Host " Parola dosya: $SecretFile"
    Write-Host " WSL         : $linuxDistro"
    Write-Host ""

    Open-OFBiz
}

function Invoke-Start {
    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    & wsl.exe -d $linuxDistro -- bash -lc "docker inspect '$container' >/dev/null 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Invoke-Install
        return
    }

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker start '$container' >/dev/null"
    Wait-OFBizReady -LinuxDistro $linuxDistro
    Open-OFBiz
}

function Invoke-Stop {
    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker stop '$container' >/dev/null 2>&1 || true"
    Write-Host "TurkuazOFBiz container durduruldu: $container"
}

function Invoke-Status {
    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker ps -a --filter 'name=^/$container$' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'"
}

function Invoke-Doctor {
    if (-not (Test-Path (Join-Path $ManagedRepo "controllers\ofbiz.sh"))) {
        Sync-ManagedRepo
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"
}

try {
    switch ($Action) {
        "install" { Invoke-Install }
        "start"   { Invoke-Start }
        "stop"    { Invoke-Stop }
        "status"  { Invoke-Status }
        "doctor"  { Invoke-Doctor }
        "open"    { Open-OFBiz }
        default   { Fail "Bilinmeyen action: $Action" }
    }
    exit 0
}
catch {
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Repo: $ProjectUrl" -ForegroundColor Yellow
    exit 1
}
