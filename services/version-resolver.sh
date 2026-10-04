# Dosya Yolu: /services/version-resolver.sh
# Amac: OFBiz surum aliaslarini cozer ve release metadata bilgisini saglar
# Service - Shell
# Version: 1.2.0
# Aciklama: Surum dogrulama, Java major secimi ve release listeleme servisi
#
# Bagimli Oldugu Katman: Service | Config

if [[ "${OFBIZ_VERSION_RESOLVER_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
OFBIZ_VERSION_RESOLVER_LOADED="1"

set -euo pipefail

readonly VERSION_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION_ROOT_DIR="$(cd "${VERSION_SERVICE_DIR}/.." && pwd)"
readonly OFBIZ_VERSION_CONFIG="${VERSION_ROOT_DIR}/config/versions.conf"
readonly OFBIZ_CONTROLLER="${VERSION_ROOT_DIR}/controllers/ofbiz.sh"

# shellcheck source=/dev/null
source "${OFBIZ_VERSION_CONFIG}"

ofbiz_list_versions() {
    printf 'Aliases:\n'
    printf '  latest -> %s\n' "${OFBIZ_DEFAULT_VERSION}"
    printf '  24.09  -> %s\n' "${OFBIZ_LATEST_24_09}"
    printf '  18.12  -> %s\n' "${OFBIZ_LATEST_18_12}"
    printf '  17.12  -> %s\n' "${OFBIZ_LATEST_17_12}"
    printf '\n24.09 releases - Java %s:\n%s\n' "${OFBIZ_JAVA_24_09}" "${OFBIZ_RELEASES_24_09}"
    printf '18.12 releases - Java %s:\n%s\n' "${OFBIZ_JAVA_18_12}" "${OFBIZ_RELEASES_18_12}"
    printf '17.12 releases - Java %s:\n%s\n' "${OFBIZ_JAVA_17_12}" "${OFBIZ_RELEASES_17_12}"
}

ofbiz_resolve_alias() {
    local requested="${1:-latest}"

    case "${requested}" in
        latest)
            printf '%s\n' "${OFBIZ_DEFAULT_VERSION}"
            ;;
        24.09)
            printf '%s\n' "${OFBIZ_LATEST_24_09}"
            ;;
        18.12)
            printf '%s\n' "${OFBIZ_LATEST_18_12}"
            ;;
        17.12)
            printf '%s\n' "${OFBIZ_LATEST_17_12}"
            ;;
        *)
            printf '%s\n' "${requested}"
            ;;
    esac
}

ofbiz_is_known_release() {
    local version="${1:?version required}"
    local all_releases

    all_releases="${OFBIZ_RELEASES_24_09}
${OFBIZ_RELEASES_18_12}
${OFBIZ_RELEASES_17_12}"

    grep -Fxq "${version}" <<< "${all_releases}"
}

ofbiz_required_java() {
    local version="${1:?version required}"

    case "${version}" in
        24.09.*)
            printf '%s\n' "${OFBIZ_JAVA_24_09}"
            ;;
        18.12.*)
            printf '%s\n' "${OFBIZ_JAVA_18_12}"
            ;;
        17.12.*)
            printf '%s\n' "${OFBIZ_JAVA_17_12}"
            ;;
        *)
            return 1
            ;;
    esac
}

ofbiz_resolve_version() {
    local requested="${1:-latest}"
    local resolved

    resolved="$(ofbiz_resolve_alias "${requested}")"

    if ! ofbiz_is_known_release "${resolved}"; then
        printf 'ERROR: Unsupported OFBiz release: %s\n' "${requested}" >&2
        printf 'Run: bash %s release list\n' "${OFBIZ_CONTROLLER}" >&2
        return 1
    fi

    printf '%s\n' "${resolved}"
}
