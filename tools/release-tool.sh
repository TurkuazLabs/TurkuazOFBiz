# Dosya Yolu: /tools/release-tool.sh
# Amac: Apache OFBiz release ZIP paketini indirir, dogrular ve acar
# Tool - Shell
# Version: 1.0.1
# Aciklama: Current ve archive kaynaklarini deneyen SHA-512 dogrulamali release indirme adaptorudur
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

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

    [[ "${found}" == "1" ]] || return 1

    (
        cd "${work_dir}"
        sha512sum --check "${archive_name}.sha512"
    )

    mkdir -p "${destination_dir}"
    unzip -q "${archive_file}" -d "${destination_dir}"
    rm -rf "${work_dir}"
}
