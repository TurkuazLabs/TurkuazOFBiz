# Dosya Yolu: /tools/system-tool.sh
# Amac: OFBiz kurulumunun sistem paket bagimliliklarini hazirlar
# Tool - Shell
# Version: 1.0.0
# Aciklama: Desteklenen Linux paket yoneticileri uzerinden ortak araclari kurar
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_tool_require_root() {
    [[ "${EUID}" -eq 0 ]]
}

ofbiz_tool_install_base_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip tar git ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl unzip tar git ca-certificates
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl unzip tar git ca-certificates
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install curl unzip tar git ca-certificates
    else
        return 1
    fi

    command -v sha256sum >/dev/null 2>&1
    command -v sha512sum >/dev/null 2>&1
}
