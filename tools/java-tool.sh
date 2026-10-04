# Dosya Yolu: /tools/java-tool.sh
# Amac: Gerekli Eclipse Temurin JDK surumunu indirir ve izole dizine kurar
# Tool - Shell
# Version: 1.0.1
# Aciklama: Adoptium API, mimari algilama ve SHA-256 dogrulamasi ile JDK kurulum adaptorudur
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_tool_detect_adoptium_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            printf 'x64\n'
            ;;
        aarch64|arm64)
            printf 'aarch64\n'
            ;;
        armv7l|armv7)
            printf 'arm\n'
            ;;
        ppc64le)
            printf 'ppc64le\n'
            ;;
        s390x)
            printf 's390x\n'
            ;;
        *)
            return 1
            ;;
    esac
}

ofbiz_tool_install_temurin_jdk() {
    local java_major="${1:?java major required}"
    local jdks_dir="${2:?jdks dir required}"
    local api_base_url="${3:?api base url required}"
    local java_home="${jdks_dir}/temurin-${java_major}"
    local arch
    local api_url
    local fetch_url
    local work_dir
    local archive_file
    local checksum_file
    local expected_checksum

    if [[ -x "${java_home}/bin/javac" ]]; then
        printf '%s\n' "${java_home}"
        return
    fi

    arch="$(ofbiz_tool_detect_adoptium_arch)"
    api_url="${api_base_url}/${java_major}/ga/linux/${arch}/jdk/hotspot/normal/eclipse"
    work_dir="$(mktemp -d)"

    fetch_url="$(curl --fail --silent --show-error --output /dev/null --write-out '%{redirect_url}' "${api_url}")"
    [[ -n "${fetch_url}" ]] || return 1

    archive_file="${work_dir}/temurin-${java_major}.tar.gz"
    checksum_file="${work_dir}/temurin-${java_major}.sha256"

    curl --fail --location --retry 3 --output "${archive_file}" "${fetch_url}"
    curl --fail --location --retry 3 --output "${checksum_file}" "${fetch_url}.sha256.txt"

    expected_checksum="$(awk 'NR == 1 {print $1}' "${checksum_file}")"
    [[ -n "${expected_checksum}" ]] || return 1

    printf '%s  %s\n' "${expected_checksum}" "${archive_file}" | sha256sum --check --status

    rm -rf "${java_home}"
    mkdir -p "${java_home}"
    tar -xzf "${archive_file}" -C "${java_home}" --strip-components=1

    [[ -x "${java_home}/bin/javac" ]] || return 1

    rm -rf "${work_dir}"
    printf '%s\n' "${java_home}"
}
