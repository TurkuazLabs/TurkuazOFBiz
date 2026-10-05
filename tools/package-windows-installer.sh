# Dosya Yolu: /tools/package-windows-installer.sh
# Amac: Windows launcher ve PowerShell installer'i tek indirilebilir ZIP paketi haline getirir
# Tool - Shell
# Version: 1.1.0
# Aciklama: Native portable ve opsiyonel Docker kurulumunu sunan launcher, PS1 ve kullanim notunu paketler
#
# Bagimli Oldugu Katman: Tool | View

set -euo pipefail

readonly PACKAGE_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_ROOT="$(cd "${PACKAGE_TOOL_DIR}/.." && pwd)"

output_dir="${1:-${PACKAGE_ROOT}/dist}"
mkdir -p "${output_dir}"
output_dir="$(cd "${output_dir}" && pwd)"

stage_dir="$(mktemp -d)"
trap 'rm -rf -- "${stage_dir}"' EXIT

cp "${PACKAGE_ROOT}/install.bat" "${stage_dir}/TurkuazOFBiz-Launcher.cmd"
cp "${PACKAGE_ROOT}/install.ps1" "${stage_dir}/TurkuazOFBiz-Installer.ps1"

cat > "${stage_dir}/README-FIRST.txt" <<'EOF'
TurkuazOFBiz Windows Kurulumu
=============================

1. Bu ZIP dosyasini normal bir klasore tamamen cikarin.
2. TurkuazOFBiz-Launcher.cmd dosyasina cift tiklayin.
3. Once Native Portable veya Docker kurulum modunu secin.
4. Ardindan OFBiz hedefi ve Demo/Runtime secimini yapin.

Launcher:
- Internetten PowerShell kodu indirmez.
- ExecutionPolicy Bypass kullanmaz.
- Paketteki yerel TurkuazOFBiz-Installer.ps1 dosyasinin Windows internet blokunu kaldirir.
- Hata olursa pencereyi acik tutar.

Native Portable gereksinimleri:
- Windows 10/11
- Docker gerekmez
- WSL gerekmez
- Sistem Java kurulumu gerekmez

Docker modu gereksinimleri:
- Windows 10/11
- WSL2 Linux dagitimi (Ubuntu-24.04 onerilir)
- Docker Desktop + WSL integration

Varsayilan uygulama:
https://localhost:8443/partymgr

Not:
Kurumsal bir MachinePolicy/UserPolicy "AllSigned" zorluyorsa imzasiz PS1 yine calismaz.
Bu durumda politika atlatilmaz; kod imzali installer gerekir.
EOF

archive="${output_dir}/TurkuazOFBiz-Setup.zip"
checksum="${archive}.sha256"

rm -f -- "${archive}" "${checksum}"

(
    cd "${stage_dir}"
    zip -q "${archive}"         TurkuazOFBiz-Launcher.cmd         TurkuazOFBiz-Installer.ps1         README-FIRST.txt
)

(
    cd "${output_dir}"
    sha256sum TurkuazOFBiz-Setup.zip > TurkuazOFBiz-Setup.zip.sha256
)

printf '%s\n' "${archive}"
printf '%s\n' "${checksum}"
