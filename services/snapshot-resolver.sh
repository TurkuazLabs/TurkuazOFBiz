# Dosya Yolu: /services/snapshot-resolver.sh
# Amac: OFBiz snapshot aliaslarini gercek Apache branch isimlerine cozer
# Service - Shell
# Version: 1.1.0
# Aciklama: Trunk, 24.09 ve 22.01 snapshot secimlerini dogrular ve Java gereksinimini verir
#
# Bagimli Oldugu Katman: Service | Config

if [[ "${OFBIZ_SNAPSHOT_RESOLVER_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
OFBIZ_SNAPSHOT_RESOLVER_LOADED="1"

set -euo pipefail

readonly SNAPSHOT_RESOLVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SNAPSHOT_RESOLVER_ROOT="$(cd "${SNAPSHOT_RESOLVER_DIR}/.." && pwd)"
readonly SNAPSHOT_CONFIG="${SNAPSHOT_RESOLVER_ROOT}/config/snapshots.conf"

# shellcheck source=/dev/null
source "${SNAPSHOT_CONFIG}"

ofbiz_snapshot_list() {
    printf 'Aliases:\n'
    printf '  trunk -> %s\n' "${OFBIZ_SNAPSHOT_ALIAS_TRUNK}"
    printf '  24.09 -> %s\n' "${OFBIZ_SNAPSHOT_ALIAS_24_09}"
    printf '  22.01 -> %s\n' "${OFBIZ_SNAPSHOT_ALIAS_22_01}"
    printf '\nBranches:\n%s\n' "${OFBIZ_SNAPSHOT_BRANCHES}"
}

ofbiz_snapshot_resolve_alias() {
    local requested="${1:-${OFBIZ_SNAPSHOT_DEFAULT}}"

    case "${requested}" in
        trunk)
            printf '%s\n' "${OFBIZ_SNAPSHOT_ALIAS_TRUNK}"
            ;;
        24.09)
            printf '%s\n' "${OFBIZ_SNAPSHOT_ALIAS_24_09}"
            ;;
        22.01)
            printf '%s\n' "${OFBIZ_SNAPSHOT_ALIAS_22_01}"
            ;;
        *)
            printf '%s\n' "${requested}"
            ;;
    esac
}

ofbiz_snapshot_is_known_branch() {
    local branch="${1:?branch required}"
    grep -Fxq "${branch}" <<< "${OFBIZ_SNAPSHOT_BRANCHES}"
}

ofbiz_snapshot_resolve_branch() {
    local requested="${1:-${OFBIZ_SNAPSHOT_DEFAULT}}"
    local branch

    branch="$(ofbiz_snapshot_resolve_alias "${requested}")"

    if ! ofbiz_snapshot_is_known_branch "${branch}"; then
        printf 'ERROR: Unsupported OFBiz snapshot branch: %s\n' "${requested}" >&2
        return 1
    fi

    printf '%s\n' "${branch}"
}

ofbiz_snapshot_required_java() {
    local branch="${1:?branch required}"

    case "${branch}" in
        trunk)
            printf '%s\n' "${OFBIZ_SNAPSHOT_JAVA_TRUNK}"
            ;;
        release24.09)
            printf '%s\n' "${OFBIZ_SNAPSHOT_JAVA_24_09}"
            ;;
        release22.01)
            printf '%s\n' "${OFBIZ_SNAPSHOT_JAVA_22_01}"
            ;;
        *)
            return 1
            ;;
    esac
}
