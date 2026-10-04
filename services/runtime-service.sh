# Dosya Yolu: /services/runtime-service.sh
# Amac: Aktif veya belirtilen OFBiz release/snapshot hedefini calistirma is kurallarini yonetir
# Service - Shell
# Version: 1.0.0
# Aciklama: Runtime hedefini cozer, Java bilgisini belirler ve calistirma Tool'unu cagirir
#
# Bagimli Oldugu Katman: Service | Repo | Tool | Config

set -euo pipefail

readonly RUNTIME_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RUNTIME_ROOT_DIR="$(cd "${RUNTIME_SERVICE_DIR}/.." && pwd)"
readonly RUNTIME_TOOL="${RUNTIME_ROOT_DIR}/tools/ofbiz-run.sh"

# shellcheck source=/dev/null
source "${RUNTIME_ROOT_DIR}/services/version-resolver.sh"
# shellcheck source=/dev/null
source "${RUNTIME_ROOT_DIR}/services/snapshot-resolver.sh"
# shellcheck source=/dev/null
source "${RUNTIME_ROOT_DIR}/repositories/install-repository.sh"

ofbiz_runtime_service_fail() {
    printf '[runtime-service] ERROR: %s\n' "$*" >&2
    return 1
}

ofbiz_runtime_service_target_path() {
    local target="${1:-current}"
    local identifier

    case "${target}" in
        current|"")
            ofbiz_repository_current_path
            ;;
        snapshot:*)
            identifier="$(ofbiz_snapshot_resolve_branch "${target#snapshot:}")"
            ofbiz_repository_snapshot_path "${identifier}"
            ;;
        release:*)
            identifier="$(ofbiz_resolve_version "${target#release:}")"
            ofbiz_repository_release_path "${identifier}"
            ;;
        *)
            identifier="$(ofbiz_resolve_version "${target}")"
            ofbiz_repository_release_path "${identifier}"
            ;;
    esac
}

ofbiz_runtime_service_metadata() {
    local runtime_path="${1:?runtime path required}"
    local key="${2:?key required}"
    local value

    value="$(ofbiz_repository_metadata_value "${runtime_path}" "${key}" || true)"
    if [[ -n "${value}" ]]; then
        printf '%s\n' "${value}"
        return
    fi

    case "${key}" in
        type)
            if [[ "${runtime_path}" == *"/${OFBIZ_SNAPSHOTS_DIR_NAME}/"* ]]; then
                printf '%s\n' "${OFBIZ_TYPE_SNAPSHOT}"
            else
                printf '%s\n' "${OFBIZ_TYPE_RELEASE}"
            fi
            ;;
        identifier)
            if [[ "${runtime_path}" == *"/${OFBIZ_SNAPSHOTS_DIR_NAME}/"* ]]; then
                basename "${runtime_path}" | sed "s/^${OFBIZ_SNAPSHOT_DIR_PREFIX}//"
            else
                basename "${runtime_path}" | sed "s/^${OFBIZ_RELEASE_DIR_PREFIX}//"
            fi
            ;;
        java_major)
            local runtime_type
            local identifier
            runtime_type="$(ofbiz_runtime_service_metadata "${runtime_path}" type)"
            identifier="$(ofbiz_runtime_service_metadata "${runtime_path}" identifier)"

            if [[ "${runtime_type}" == "${OFBIZ_TYPE_SNAPSHOT}" ]]; then
                ofbiz_snapshot_required_java "${identifier}"
            else
                ofbiz_required_java "${identifier}"
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

ofbiz_runtime_service_run() {
    local action="${1:-start}"
    local target="${2:-current}"
    local runtime_path
    local java_major
    local java_home

    runtime_path="$(ofbiz_runtime_service_target_path "${target}")"
    [[ -d "${runtime_path}" ]] || ofbiz_runtime_service_fail "Runtime target is not installed: ${target}"

    java_major="$(ofbiz_runtime_service_metadata "${runtime_path}" java_major)"
    java_home="$(ofbiz_repository_jdks_dir)/temurin-${java_major}"

    [[ -x "${java_home}/bin/java" ]] || ofbiz_runtime_service_fail "Required JDK is not installed: ${java_home}"

    bash "${RUNTIME_TOOL}" "${runtime_path}" "${java_home}" "${action}"
}

ofbiz_runtime_service_current() {
    local runtime_path
    local runtime_type
    local identifier

    runtime_path="$(ofbiz_repository_current_path)" || {
        printf 'No active OFBiz target.\n'
        return
    }

    runtime_type="$(ofbiz_runtime_service_metadata "${runtime_path}" type)"
    identifier="$(ofbiz_runtime_service_metadata "${runtime_path}" identifier)"

    printf '%s:%s\n' "${runtime_type}" "${identifier}"
}
