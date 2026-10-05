# Dosya Yolu: /install.ps1
# Amac: Windows kullanicisi icin Native portable veya Docker TurkuazOFBiz kurulumunu tek arabirimden yonetir
# Controller - PowerShell
# Version: 2.2.0
# Aciklama: Ortak mode/target/version/variant modeliyle Windows native portable ve WSL/Docker kurulumlarini yonlendirir
#
# Bagimli Oldugu Katman: Controller | Service | Repo | Tool | View | Config

[CmdletBinding()]
param(
    [ValidateSet("install", "start", "stop", "status", "doctor", "open", "password")]
    [string]$Action = "install",
    [ValidateSet("", "native", "docker")]
    [string]$InstallMode = "",
    [string]$Distro = "",
    [ValidateSet("", "release", "snapshot")]
    [string]$TargetType = "",
    [string]$OFBizVersion = "",
    [ValidateSet("", "runtime", "demo")]
    [string]$Variant = "",
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
$NativeRoot = Join-Path $InstallRoot "native"
$SecretFile = Join-Path $InstallRoot "admin-password.txt"
$CredentialsDir = Join-Path $InstallRoot "credentials"
$StateFile = Join-Path $InstallRoot "installer-state.json"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "TurkuazOFBiz.lnk"
$DefaultAppPath = ""
$InstallerDefaultMode = ""
$InstallerDefaultHttpsPort = 0

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

function Read-MenuChoice {
    param(
        [string]$Prompt,
        [int]$Min,
        [int]$Max,
        [int]$Default = 1
    )

    while ($true) {
        $value = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($value)) {
            return $Default
        }

        $number = 0
        if ([int]::TryParse($value, [ref]$number) -and $number -ge $Min -and $number -le $Max) {
            return $number
        }

        Write-Host "Gecersiz secim. $Min-$Max arasinda bir deger girin." -ForegroundColor Yellow
    }
}

function Get-ConfigValue {
    param(
        [string]$ConfigPath,
        [string]$VariableName
    )

    $content = Get-Content -Path $ConfigPath -Raw
    $pattern = '(?m)^' + [regex]::Escape($VariableName) + '="([^"]*)"'
    $match = [regex]::Match($content, $pattern)

    if (-not $match.Success) {
        Fail "Config degeri bulunamadi: $VariableName"
    }

    return [string]$match.Groups[1].Value
}

function Initialize-InstallerConfig {
    $installerConfig = Join-Path $ManagedRepo "config\installer.conf"

    if (-not (Test-Path $installerConfig)) {
        Fail "Installer config bulunamadi: $installerConfig"
    }

    $script:InstallerDefaultMode = Get-ConfigValue -ConfigPath $installerConfig -VariableName "OFBIZ_INSTALL_MODE_DEFAULT"
    $script:InstallerDefaultHttpsPort = [int](Get-ConfigValue -ConfigPath $installerConfig -VariableName "OFBIZ_INSTALL_HTTPS_PORT_DEFAULT")
    $script:DefaultAppPath = Get-ConfigValue -ConfigPath $installerConfig -VariableName "OFBIZ_INSTALL_APP_PATH_DEFAULT"
}

function Get-ConfigMultilineValues {
    param(
        [string]$ConfigPath,
        [string]$VariableName
    )

    $content = Get-Content -Path $ConfigPath -Raw
    $pattern = '(?ms)^' + [regex]::Escape($VariableName) + '="(.*?)"'
    $match = [regex]::Match($content, $pattern)

    if (-not $match.Success) {
        Fail "Config degeri bulunamadi: $VariableName"
    }

    return @(
        $match.Groups[1].Value -split "\r?\n" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
}

function Select-ValueMenu {
    param(
        [string]$Title,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        Fail "Secim listesi bos: $Title"
    }

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan

    for ($index = 0; $index -lt $Values.Count; $index++) {
        $suffix = if ($index -eq 0) { "  [onerilen/en yeni]" } else { "" }
        Write-Host (" {0,2} - {1}{2}" -f ($index + 1), $Values[$index], $suffix)
    }

    $choice = Read-MenuChoice -Prompt "Secim" -Min 1 -Max $Values.Count -Default 1
    return $Values[$choice - 1]
}

function Select-InstallMode {
    if ($InstallMode) {
        return
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " TurkuazOFBiz - Kurulum Modu" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " 1 - Native Portable  (Docker/WSL gerekmez, onerilen)"
    Write-Host " 2 - Docker           (WSL2 + Docker Desktop)"

    $defaultChoice = if ($InstallerDefaultMode -eq "docker") { 2 } else { 1 }
    $choice = Read-MenuChoice -Prompt "Kurulum modu" -Min 1 -Max 2 -Default $defaultChoice
    $script:InstallMode = if ($choice -eq 1) { "native" } else { "docker" }
}

function Select-Variant {
    if ($Variant) {
        return
    }

    Write-Host ""
    Write-Host "Calisma verisi:"
    Write-Host " 1 - Demo    (hazir ornek veri; test icin onerilen)"
    Write-Host " 2 - Runtime (seed veri; ilk calismada guclu admin parolasi)"

    $choice = Read-MenuChoice -Prompt "Varyant" -Min 1 -Max 2 -Default 1
    $script:Variant = if ($choice -eq 1) { "demo" } else { "runtime" }
}

function Select-NativeTarget {
    $versionsConfig = Join-Path $ManagedRepo "config\versions.conf"
    $values = @(
        Get-ConfigMultilineValues -ConfigPath $versionsConfig -VariableName "OFBIZ_PORTABLE_RELEASES" |
            Sort-Object -Descending
    )

    $script:TargetType = "release"

    if (-not $OFBizVersion) {
        $script:OFBizVersion = Select-ValueMenu -Title "Windows native portable OFBiz surumu" -Values $values
    }
    elseif ($values -notcontains $OFBizVersion) {
        Fail "Windows native portable katalogunda olmayan OFBiz surumu: $OFBizVersion"
    }

    Select-Variant

    if ($HttpsPort -ne $InstallerDefaultHttpsPort) {
        Fail "Windows native portable paket su anda HTTPS $InstallerDefaultHttpsPort portunu kullanir. Docker modu ozel port destekler."
    }

    Write-Host ""
    Write-Host "Secilen hedef: native / release / $OFBizVersion / $Variant" -ForegroundColor Green
}

function Select-DockerTarget {
    $versionsConfig = Join-Path $ManagedRepo "config\versions.conf"
    $snapshotsConfig = Join-Path $ManagedRepo "config\snapshots.conf"

    if (-not $TargetType -or -not $OFBizVersion) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " TurkuazOFBiz - Docker OFBiz Hedef Secimi" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " 1 - Release 24.09"
        Write-Host " 2 - Release 18.12"
        Write-Host " 3 - Release 17.12"
        Write-Host " 4 - Snapshot / branch"

        $family = Read-MenuChoice -Prompt "Kurulacak seri" -Min 1 -Max 4 -Default 1

        switch ($family) {
            1 {
                $script:TargetType = "release"
                $values = @(Get-ConfigMultilineValues -ConfigPath $versionsConfig -VariableName "OFBIZ_RELEASES_24_09" | Sort-Object -Descending)
                $script:OFBizVersion = Select-ValueMenu -Title "24.09 surumu" -Values $values
            }
            2 {
                $script:TargetType = "release"
                $values = @(Get-ConfigMultilineValues -ConfigPath $versionsConfig -VariableName "OFBIZ_RELEASES_18_12" | Sort-Object -Descending)
                $script:OFBizVersion = Select-ValueMenu -Title "18.12 surumu" -Values $values
            }
            3 {
                $script:TargetType = "release"
                $values = @(Get-ConfigMultilineValues -ConfigPath $versionsConfig -VariableName "OFBIZ_RELEASES_17_12" | Sort-Object -Descending)
                $script:OFBizVersion = Select-ValueMenu -Title "17.12 surumu" -Values $values
            }
            4 {
                $script:TargetType = "snapshot"
                $values = @(Get-ConfigMultilineValues -ConfigPath $snapshotsConfig -VariableName "OFBIZ_SNAPSHOT_BRANCHES")
                $script:OFBizVersion = Select-ValueMenu -Title "Snapshot branch" -Values $values
            }
        }
    }

    if ($TargetType -eq "release" -and $OFBizVersion -like "17.12.*") {
        $script:Variant = "demo"
        Write-Host ""
        Write-Host "17.12 Docker compat yolu demo varyantini kullanir." -ForegroundColor Yellow
    }
    else {
        Select-Variant
    }

    Write-Host ""
    Write-Host "Secilen hedef: docker / $TargetType / $OFBizVersion / $Variant" -ForegroundColor Green
}

function Save-InstallerState {
    param([string]$NativePath = "")

    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

    $state = [ordered]@{
        install_mode = $InstallMode
        target_type = $TargetType
        target = $OFBizVersion
        variant = $Variant
        https_port = $HttpsPort
        app_path = $DefaultAppPath
        native_path = $NativePath
    }

    $state | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

function Restore-InstallerState {
    if (-not (Test-Path $StateFile)) {
        Fail "Kayitli OFBiz hedefi bulunamadi. Installer'i install action ile calistirin."
    }

    $state = Get-Content -Path $StateFile -Raw | ConvertFrom-Json

    if (-not $InstallMode) {
        if ($state.install_mode) {
            $script:InstallMode = [string]$state.install_mode
        }
        else {
            $script:InstallMode = "docker"
        }
    }

    if (-not $TargetType) {
        $script:TargetType = [string]$state.target_type
    }

    if (-not $OFBizVersion) {
        $script:OFBizVersion = [string]$state.target
    }

    if (-not $Variant) {
        $script:Variant = [string]$state.variant
    }

    if ($state.https_port) {
        $script:HttpsPort = [int]$state.https_port
    }

    if ($state.app_path) {
        $script:DefaultAppPath = [string]$state.app_path
    }
    elseif (-not $DefaultAppPath -and (Test-Path (Join-Path $ManagedRepo "config\installer.conf"))) {
        Initialize-InstallerConfig
    }

    return $state
}

function Get-TargetCredentialFile {
    New-Item -ItemType Directory -Force -Path $CredentialsDir | Out-Null
    $safeTarget = ($OFBizVersion -replace '[^A-Za-z0-9._-]', '-')
    return Join-Path $CredentialsDir "$TargetType-$safeTarget-$Variant.txt"
}

function Get-LatestRelease {
    Write-Step "En son stabil TurkuazOFBiz surumu kontrol ediliyor"

    $headers = @{
        "User-Agent" = "TurkuazOFBiz-Installer"
        "Accept" = "application/vnd.github+json"
    }

    $release = Invoke-RestMethod -Uri "$ProjectApi/releases/latest" -Headers $headers
    if (-not $release.tag_name) {
        Fail "GitHub latest release bilgisi alinamadi."
    }

    return $release
}

function Sync-ManagedRepo {
    $release = Get-LatestRelease
    $tag = [string]$release.tag_name
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("TurkuazOFBiz-" + [Guid]::NewGuid().ToString("N"))
    $zipFile = Join-Path $tempRoot "TurkuazOFBiz.zip"
    $extractDir = Join-Path $tempRoot "extract"
    $archiveUrl = "$ProjectUrl/archive/refs/tags/$tag.zip"

    Write-Step "$tag yonetim dosyalari indiriliyor"

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
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        Copy-Item -Path (Join-Path $sourceRoot.FullName "*") -Destination $ManagedRepo -Recurse -Force
        Write-Host "Stabil proje surumu hazir: $tag"
    }
    finally {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-NativePackageName {
    $displayMode = if ($Variant -eq "demo") { "Demo" } else { "Runtime" }
    return "TurkuazOFBiz-Portable-$OFBizVersion-$displayMode-win-x64.zip"
}

function Get-NativeTargetPath {
    $safeTarget = ($OFBizVersion -replace '[^A-Za-z0-9._-]', '-')
    return Join-Path $NativeRoot "$safeTarget-$Variant"
}

function Find-ReleaseAsset {
    param(
        [object]$Release,
        [string]$Name
    )

    $asset = @($Release.assets | Where-Object { $_.name -eq $Name }) | Select-Object -First 1

    if (-not $asset) {
        Fail "Release asset bulunamadi: $Name"
    }

    return $asset
}

function Install-NativePackage {
    $release = Get-LatestRelease
    $packageName = Get-NativePackageName
    $checksumName = "$packageName.sha256"
    $packageAsset = Find-ReleaseAsset -Release $release -Name $packageName
    $checksumAsset = Find-ReleaseAsset -Release $release -Name $checksumName
    $targetPath = Get-NativeTargetPath
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("TurkuazOFBiz-Native-" + [Guid]::NewGuid().ToString("N"))
    $zipPath = Join-Path $tempRoot $packageName
    $checksumPath = Join-Path $tempRoot $checksumName
    $extractPath = Join-Path $tempRoot "extract"

    Write-Step "Windows native portable paket indiriliyor: $packageName"

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    New-Item -ItemType Directory -Force -Path $NativeRoot | Out-Null

    try {
        Invoke-WebRequest -Uri $packageAsset.browser_download_url -OutFile $zipPath -UseBasicParsing
        Invoke-WebRequest -Uri $checksumAsset.browser_download_url -OutFile $checksumPath -UseBasicParsing

        $expectedHash = ((Get-Content -Path $checksumPath -Raw).Trim() -split '\s+')[0].ToUpperInvariant()
        $actualHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()

        if ($expectedHash -ne $actualHash) {
            Fail "Portable ZIP SHA-256 dogrulamasi basarisiz."
        }

        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        $launcher = Get-ChildItem -Path $extractPath -Recurse -Filter "TurkuazOFBiz.cmd" | Select-Object -First 1
        if (-not $launcher) {
            Fail "Portable TurkuazOFBiz.cmd bulunamadi."
        }

        $sourceRoot = $launcher.Directory.FullName

        if (Test-Path $targetPath) {
            Remove-Item -Path $targetPath -Recurse -Force
        }

        New-Item -ItemType Directory -Force -Path (Split-Path $targetPath -Parent) | Out-Null
        Move-Item -Path $sourceRoot -Destination $targetPath
    }
    finally {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    return $targetPath
}

function Invoke-NativeCommand {
    param(
        [string]$NativePath,
        [string]$CommandFile,
        [string]$Argument = ""
    )

    $commandPath = Join-Path $NativePath $CommandFile

    if (-not (Test-Path $commandPath)) {
        Fail "Native komut bulunamadi: $commandPath"
    }

    $command = 'call "' + $commandPath + '"'
    if ($Argument) {
        $command += " $Argument"
    }

    & cmd.exe /d /c $command

    if ($LASTEXITCODE -ne 0) {
        Fail "Native komut basarisiz: $CommandFile"
    }
}

function Invoke-NativeInstall {
    $nativePath = Install-NativePackage

    Write-Step "Native Apache OFBiz baslatiliyor"
    Invoke-NativeCommand -NativePath $nativePath -CommandFile "Start.cmd" -Argument "nopause"
    Save-InstallerState -NativePath $nativePath
    Ensure-DesktopShortcut

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " TurkuazOFBiz Native hazir" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " Hedef       : release / $OFBizVersion / $Variant"
    Write-Host " Adres       : $(Get-OFBizUrl)"
    Write-Host " Docker/WSL  : gerekmez"

    Invoke-NativePassword -NativePath $nativePath
}

function Get-WslDistros {
    if (-not (Test-Command "wsl.exe")) {
        Fail "WSL bulunamadi. Docker modu icin WSL2 kurulu olmali."
    }

    return @(
        & wsl.exe -l -q 2>$null |
            ForEach-Object { ($_ -replace [char]0, "").Trim() } |
            Where-Object {
                $_ -and
                $_ -notmatch "^docker-desktop" -and
                $_ -notmatch "^docker-desktop-data"
            }
    )
}

function Resolve-WslDistro {
    $distros = @(Get-WslDistros)

    if ($distros.Count -eq 0) {
        Fail "Kullanilabilir WSL Linux dagitimi bulunamadi."
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

    if (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue)) {
        Write-Step "Docker Desktop baslatiliyor"
        Start-Process -FilePath $dockerDesktop | Out-Null
    }
}

function Wait-DockerReady {
    param([string]$LinuxDistro)

    for ($attempt = 1; $attempt -le 60; $attempt++) {
        & wsl.exe -d $LinuxDistro -- bash -lc "docker info >/dev/null 2>&1"

        if ($LASTEXITCODE -eq 0) {
            return
        }

        Start-Sleep -Seconds 2
    }

    Fail "Docker WSL icinden erisilebilir hale gelmedi."
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
    $targetSecret = Get-TargetCredentialFile

    if ($Variant -eq "demo") {
        $password = "ofbiz"
        Set-Content -Path $targetSecret -Value $password -Encoding ASCII
        Set-Content -Path $SecretFile -Value $password -Encoding ASCII
        return $password
    }

    if (Test-Path $targetSecret) {
        $existing = (Get-Content -Path $targetSecret -Raw).Trim()

        if ($existing) {
            Set-Content -Path $SecretFile -Value $existing -Encoding ASCII
            return $existing
        }
    }

    $password = New-AdminPassword
    Set-Content -Path $targetSecret -Value $password -Encoding ASCII
    Set-Content -Path $SecretFile -Value $password -Encoding ASCII
    return $password
}

function Get-ContainerName {
    $safeTarget = ($OFBizVersion -replace '[^A-Za-z0-9_-]', '-')
    return "turkuazofbiz-$Variant-$TargetType-$safeTarget"
}

function Stop-OtherTurkuazContainers {
    param([string]$LinuxDistro)

    $command = "docker ps --format '{{.Names}}' | grep -E '^(ofbiz-(release|snapshot)-|turkuazofbiz-)' | xargs -r docker stop >/dev/null"
    Invoke-WslBash -LinuxDistro $LinuxDistro -Command $command
}

function Ensure-DesktopShortcut {
    if (-not (Test-Path (Join-Path $ManagedRepo "install.bat"))) {
        return
    }

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($DesktopShortcut)
        $shortcut.TargetPath = Join-Path $ManagedRepo "install.bat"
        $shortcut.Arguments = "start nopause"
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
    $url = Get-OFBizUrl

    if (-not (Test-Command "curl.exe")) {
        Fail "curl.exe bulunamadi; OFBiz readiness kontrolu yapilamiyor."
    }

    for ($attempt = 1; $attempt -le 72; $attempt++) {
        $httpCode = (& curl.exe --insecure --silent --output NUL --write-out "%{http_code}" $url 2>$null)
        $httpCode = ([string]$httpCode).Trim()

        if ($httpCode -match '^[23][0-9][0-9]
function Prepare-TargetImage {
    param(
        [string]$LinuxDistro,
        [string]$LinuxRepo
    )

    Write-Step "Apache OFBiz $TargetType $OFBizVersion $Variant image kontrol ediliyor"

    & wsl.exe -d $LinuxDistro -- bash -lc "cd '$LinuxRepo' && bash controllers/ofbiz.sh docker pull '$TargetType' '$OFBizVersion' '$Variant'"

    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Step "Resmi image bulunamadi; kaynak koddan local Docker image build ediliyor"
    Invoke-WslBash -LinuxDistro $LinuxDistro -Command "cd '$LinuxRepo' && bash controllers/ofbiz.sh docker build '$TargetType' '$OFBizVersion' '$Variant'"
}

function Invoke-DockerInstall {
    $linuxDistro = Resolve-WslDistro
    Write-Step "WSL dagitimi: $linuxDistro"
    Ensure-Docker -LinuxDistro $linuxDistro

    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro
    $password = Get-AdminPassword

    Write-Step "Docker ortam kontrolu"
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"

    Prepare-TargetImage -LinuxDistro $linuxDistro -LinuxRepo $linuxRepo

    Write-Step "Diger TurkuazOFBiz container'lari durduruluyor"
    Stop-OtherTurkuazContainers -LinuxDistro $linuxDistro

    Write-Step "Apache OFBiz Docker container baslatiliyor"
    $containerPrefix = "turkuazofbiz-$Variant"

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && OFBIZ_DOCKER_CONTAINER_NAME='$containerPrefix' OFBIZ_ADMIN_PASSWORD='$password' OFBIZ_HTTPS_PORT='$HttpsPort' bash controllers/ofbiz.sh docker run '$TargetType' '$OFBizVersion' '$Variant'"

    Wait-OFBizReady
    Save-InstallerState
    Ensure-DesktopShortcut

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " TurkuazOFBiz Docker hazir" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " Hedef       : $TargetType / $OFBizVersion / $Variant"
    Write-Host " Adres       : $(Get-OFBizUrl)"
    Write-Host " Kullanici   : admin"
    Write-Host " Parola      : $password"
    Write-Host " Parola dosya: $SecretFile"
    Write-Host " WSL         : $linuxDistro"

    Open-OFBiz
}

function Invoke-Install {
    Sync-ManagedRepo
    Initialize-InstallerConfig
    Select-InstallMode

    if ($InstallMode -eq "native") {
        Select-NativeTarget
        Invoke-NativeInstall
        return
    }

    Select-DockerTarget
    Invoke-DockerInstall
}

function Invoke-NativeStart {
    param([object]$State)

    $nativePath = [string]$State.native_path

    if (-not $nativePath -or -not (Test-Path $nativePath)) {
        Fail "Native kurulum dizini bulunamadi. Yeniden install calistirin."
    }

    Invoke-NativeCommand -NativePath $nativePath -CommandFile "Start.cmd" -Argument "nopause"
    Open-OFBiz
}

function Invoke-NativeStop {
    param([object]$State)

    Invoke-NativeCommand -NativePath ([string]$State.native_path) -CommandFile "Stop.cmd" -Argument "nopause"
}

function Invoke-NativeStatus {
    param([object]$State)

    Invoke-NativeCommand -NativePath ([string]$State.native_path) -CommandFile "Status.cmd" -Argument "quiet"
}

function Invoke-NativePassword {
    param([string]$NativePath)

    $passwordFile = Join-Path $NativePath "data\initial-admin-password.txt"

    if (-not (Test-Path $passwordFile)) {
        Write-Host "Ilk admin parolasi henuz uretilmemis."
        return
    }

    $password = (Get-Content -Path $passwordFile -Raw).Trim()

    Write-Host " Kullanici   : admin"
    Write-Host " Parola      : $password"
    Write-Host " Parola dosya: $passwordFile"
}

function Invoke-DockerStart {
    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    & wsl.exe -d $linuxDistro -- bash -lc "docker inspect '$container' >/dev/null 2>&1"

    if ($LASTEXITCODE -ne 0) {
        Invoke-DockerInstall
        return
    }

    Stop-OtherTurkuazContainers -LinuxDistro $linuxDistro
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker start '$container' >/dev/null"
    Wait-OFBizReady
    Open-OFBiz
}

function Invoke-Start {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativeStart -State $state
    }
    else {
        Invoke-DockerStart
    }
}

function Invoke-Stop {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativeStop -State $state
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker stop '$container' >/dev/null 2>&1 || true"
    Write-Host "TurkuazOFBiz container durduruldu: $container"
}

function Invoke-Status {
    $state = Restore-InstallerState

    Write-Host "Kurulum modu : $InstallMode"
    Write-Host "Secili hedef : $TargetType / $OFBizVersion / $Variant"

    if ($InstallMode -eq "native") {
        Invoke-NativeStatus -State $state
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker ps -a --filter 'name=^/$container$' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'"
}

function Invoke-Doctor {
    if (-not (Test-Path (Join-Path $ManagedRepo "controllers\ofbiz.sh"))) {
        Sync-ManagedRepo
    }

    Initialize-InstallerConfig

    if (Test-Path $StateFile) {
        Restore-InstallerState | Out-Null
    }
    elseif (-not $InstallMode) {
        $script:InstallMode = "native"
    }

    if ($InstallMode -eq "native") {
        Write-Host "Windows Native:"
        Write-Host " PowerShell : $($PSVersionTable.PSVersion)"
        Write-Host " curl.exe   : $(if (Test-Command 'curl.exe') { 'OK' } else { 'YOK' })"
        Write-Host " NativeRoot : $NativeRoot"
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"
}

function Invoke-Password {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativePassword -NativePath ([string]$state.native_path)
        return
    }

    $password = Get-AdminPassword
    $targetSecret = Get-TargetCredentialFile

    Write-Host "Kullanici    : admin"
    Write-Host "Parola       : $password"
    Write-Host "Hedef        : $TargetType / $OFBizVersion"
    Write-Host "Varyant      : $Variant"
    Write-Host "Parola dosya : $targetSecret"
}

try {
    switch ($Action) {
        "install"  { Invoke-Install }
        "start"    { Invoke-Start }
        "stop"     { Invoke-Stop }
        "status"   { Invoke-Status }
        "doctor"   { Invoke-Doctor }
        "open"     {
            if (Test-Path $StateFile) {
                Restore-InstallerState | Out-Null
            }
            else {
                if (-not (Test-Path (Join-Path $ManagedRepo "config\installer.conf"))) {
                    Sync-ManagedRepo
                }
                Initialize-InstallerConfig
            }
            Open-OFBiz
        }
        "password" { Invoke-Password }
        default    { Fail "Bilinmeyen action: $Action" }
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
) {
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

function Prepare-TargetImage {
    param(
        [string]$LinuxDistro,
        [string]$LinuxRepo
    )

    Write-Step "Apache OFBiz $TargetType $OFBizVersion $Variant image kontrol ediliyor"

    & wsl.exe -d $LinuxDistro -- bash -lc "cd '$LinuxRepo' && bash controllers/ofbiz.sh docker pull '$TargetType' '$OFBizVersion' '$Variant'"

    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Step "Resmi image bulunamadi; kaynak koddan local Docker image build ediliyor"
    Invoke-WslBash -LinuxDistro $LinuxDistro -Command "cd '$LinuxRepo' && bash controllers/ofbiz.sh docker build '$TargetType' '$OFBizVersion' '$Variant'"
}

function Invoke-DockerInstall {
    $linuxDistro = Resolve-WslDistro
    Write-Step "WSL dagitimi: $linuxDistro"
    Ensure-Docker -LinuxDistro $linuxDistro

    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro
    $password = Get-AdminPassword

    Write-Step "Docker ortam kontrolu"
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"

    Prepare-TargetImage -LinuxDistro $linuxDistro -LinuxRepo $linuxRepo

    Write-Step "Diger TurkuazOFBiz container'lari durduruluyor"
    Stop-OtherTurkuazContainers -LinuxDistro $linuxDistro

    Write-Step "Apache OFBiz Docker container baslatiliyor"
    $containerPrefix = "turkuazofbiz-$Variant"

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && OFBIZ_DOCKER_CONTAINER_NAME='$containerPrefix' OFBIZ_ADMIN_PASSWORD='$password' OFBIZ_HTTPS_PORT='$HttpsPort' bash controllers/ofbiz.sh docker run '$TargetType' '$OFBizVersion' '$Variant'"

    Save-InstallerState
    Ensure-DesktopShortcut

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " TurkuazOFBiz Docker hazir" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " Hedef       : $TargetType / $OFBizVersion / $Variant"
    Write-Host " Adres       : $(Get-OFBizUrl)"
    Write-Host " Kullanici   : admin"
    Write-Host " Parola      : $password"
    Write-Host " Parola dosya: $SecretFile"
    Write-Host " WSL         : $linuxDistro"

    Open-OFBiz
}

function Invoke-Install {
    Sync-ManagedRepo
    Initialize-InstallerConfig
    Select-InstallMode

    if ($InstallMode -eq "native") {
        Select-NativeTarget
        Invoke-NativeInstall
        return
    }

    Select-DockerTarget
    Invoke-DockerInstall
}

function Invoke-NativeStart {
    param([object]$State)

    $nativePath = [string]$State.native_path

    if (-not $nativePath -or -not (Test-Path $nativePath)) {
        Fail "Native kurulum dizini bulunamadi. Yeniden install calistirin."
    }

    Invoke-NativeCommand -NativePath $nativePath -CommandFile "Start.cmd" -Argument "nopause"
    Open-OFBiz
}

function Invoke-NativeStop {
    param([object]$State)

    Invoke-NativeCommand -NativePath ([string]$State.native_path) -CommandFile "Stop.cmd" -Argument "nopause"
}

function Invoke-NativeStatus {
    param([object]$State)

    Invoke-NativeCommand -NativePath ([string]$State.native_path) -CommandFile "Status.cmd" -Argument "quiet"
}

function Invoke-NativePassword {
    param([string]$NativePath)

    $passwordFile = Join-Path $NativePath "data\initial-admin-password.txt"

    if (-not (Test-Path $passwordFile)) {
        Write-Host "Ilk admin parolasi henuz uretilmemis."
        return
    }

    $password = (Get-Content -Path $passwordFile -Raw).Trim()

    Write-Host " Kullanici   : admin"
    Write-Host " Parola      : $password"
    Write-Host " Parola dosya: $passwordFile"
}

function Invoke-DockerStart {
    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    & wsl.exe -d $linuxDistro -- bash -lc "docker inspect '$container' >/dev/null 2>&1"

    if ($LASTEXITCODE -ne 0) {
        Invoke-DockerInstall
        return
    }

    Stop-OtherTurkuazContainers -LinuxDistro $linuxDistro
    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker start '$container' >/dev/null"
    Open-OFBiz
}

function Invoke-Start {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativeStart -State $state
    }
    else {
        Invoke-DockerStart
    }
}

function Invoke-Stop {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativeStop -State $state
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker stop '$container' >/dev/null 2>&1 || true"
    Write-Host "TurkuazOFBiz container durduruldu: $container"
}

function Invoke-Status {
    $state = Restore-InstallerState

    Write-Host "Kurulum modu : $InstallMode"
    Write-Host "Secili hedef : $TargetType / $OFBizVersion / $Variant"

    if ($InstallMode -eq "native") {
        Invoke-NativeStatus -State $state
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $container = Get-ContainerName

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "docker ps -a --filter 'name=^/$container$' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'"
}

function Invoke-Doctor {
    if (-not (Test-Path (Join-Path $ManagedRepo "controllers\ofbiz.sh"))) {
        Sync-ManagedRepo
    }

    Initialize-InstallerConfig

    if (Test-Path $StateFile) {
        Restore-InstallerState | Out-Null
    }
    elseif (-not $InstallMode) {
        $script:InstallMode = "native"
    }

    if ($InstallMode -eq "native") {
        Write-Host "Windows Native:"
        Write-Host " PowerShell : $($PSVersionTable.PSVersion)"
        Write-Host " curl.exe   : $(if (Test-Command 'curl.exe') { 'OK' } else { 'YOK' })"
        Write-Host " NativeRoot : $NativeRoot"
        return
    }

    $linuxDistro = Resolve-WslDistro
    Ensure-Docker -LinuxDistro $linuxDistro
    $linuxRepo = Convert-ToWslPath -WindowsPath $ManagedRepo -LinuxDistro $linuxDistro

    Invoke-WslBash -LinuxDistro $linuxDistro -Command "cd '$linuxRepo' && bash controllers/ofbiz.sh doctor docker"
}

function Invoke-Password {
    $state = Restore-InstallerState

    if ($InstallMode -eq "native") {
        Invoke-NativePassword -NativePath ([string]$state.native_path)
        return
    }

    $password = Get-AdminPassword
    $targetSecret = Get-TargetCredentialFile

    Write-Host "Kullanici    : admin"
    Write-Host "Parola       : $password"
    Write-Host "Hedef        : $TargetType / $OFBizVersion"
    Write-Host "Varyant      : $Variant"
    Write-Host "Parola dosya : $targetSecret"
}

try {
    switch ($Action) {
        "install"  { Invoke-Install }
        "start"    { Invoke-Start }
        "stop"     { Invoke-Stop }
        "status"   { Invoke-Status }
        "doctor"   { Invoke-Doctor }
        "open"     {
            if (Test-Path $StateFile) {
                Restore-InstallerState | Out-Null
            }
            else {
                if (-not (Test-Path (Join-Path $ManagedRepo "config\installer.conf"))) {
                    Sync-ManagedRepo
                }
                Initialize-InstallerConfig
            }
            Open-OFBiz
        }
        "password" { Invoke-Password }
        default    { Fail "Bilinmeyen action: $Action" }
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
