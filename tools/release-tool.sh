# Dosya Yolu: /tools/release-tool.sh
# Amac: Apache OFBiz release ZIP paketini indirir, dogrular ve acar
# Tool - Shell
# Version: 1.1.0
# Aciklama: Apache ve GNU SHA-512 formatlarini destekleyen release indirme ve dogrulama adaptorudur
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_tool_read_sha512() {
    local checksum_file="${1:?checksum file required}"
    local first_token
    local normalized

    [[ -f "${checksum_file}" ]] || return 1

    first_token="$(awk 'NR == 1 {print $1}' "${checksum_file}")"

    if [[ "${first_token}" =~ ^[0-9A-Fa-f]{128}$ ]]; then
        printf '%s\n' "${first_token}" | tr '[:upper:]' '[:lower:]'
        return
    fi

    normalized="$(
        sed '1s/^[^:]*:[[:space:]]*//' "${checksum_file}"             | tr -d '[:space:]'
    )"

    [[ "${normalized}" =~ ^[0-9A-Fa-f]{128}$ ]] || return 1

    printf '%s\n' "${normalized}" | tr '[:upper:]' '[:lower:]'
}

ofbiz_tool_verify_sha512() {
    local archive_file="${1:?archive file required}"
    local checksum_file="${2:?checksum file required}"
    local expected_checksum
    local actual_checksum

    [[ -f "${archive_file}" ]] || return 1

    expected_checksum="$(ofbiz_tool_read_sha512 "${checksum_file}")"
    actual_checksum="$(sha512sum "${archive_file}" | awk '{print $1}')"

    [[ "${actual_checksum}" == "${expected_checksum}" ]]
}

ofbiz_tool_download_release() {
    local version="${1:?version required}"
    local current_base_url="${2:?current base url required}"
    local archive_base_url="${3:?archive base url required}"
    local destination_dir="${4:?destination dir required}"
    local archive_name="apache-ofbiz-${version}.zip"
    local work_dir
    local archive_file
    local checksum_file
    local base_url
    local found="0"

    work_dir="$(mktemp -d)"
    archive_file="${work_dir}/${archive_name}"
    checksum_file="${archive_file}.sha512"

    for base_url in "${current_base_url}" "${archive_base_url}"; do
        if curl --fail --location --retry 2 --output "${archive_file}" "${base_url}/${archive_name}"; then
            if curl --fail --location --retry 2 --output "${checksum_file}" "${base_url}/${archive_name}.sha512"; then
                found="1"
                break
            fi
        fi
    done

    if [[ "${found}" != "1" ]]; then
        rm -rf "${work_dir}"
        return 1
    fi

    if ! ofbiz_tool_verify_sha512 "${archive_file}" "${checksum_file}"; then
        rm -rf "${work_dir}"
        return 1
    fi

    mkdir -p "${destination_dir}"
    unzip -q "${archive_file}" -d "${destination_dir}"
    rm -rf "${work_dir}"
}
