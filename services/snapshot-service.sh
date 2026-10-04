# Dosya Yolu: /services/snapshot-service.sh
# Amac: Apache OFBiz branch tabanli snapshot kurulum is kurallarini yonetir
# Service - Shell
# Version: 1.1.0
# Aciklama: Snapshot clone/update, JDK, staging, atomik replacement ve aktif snapshot islemlerini koordine eder
#
# Bagimli Oldugu Katman: Service | Repo | Tool | Config

set -euo pipefail

readonly SNAPSHOT_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SNAPSHOT_SERVICE_ROOT_DIR="$(cd "${SNAPSHOT_SERVICE_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/config/sources.conf"
# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/services/snapshot-resolver.sh"
# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/repositories/install-repository.sh"
# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/tools/system-tool.sh"
# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/tools/java-tool.sh"
# shellcheck source=/dev/null
source "${SNAPSHOT_SERVICE_ROOT_DIR}/tools/git-tool.sh"

ofbiz_snapshot_service_fail() {
    printf '[snapshot-service] ERROR: %s\n' "$*" >&2
    return 1
}

ofbiz_snapshot_service_require_environment() {
    ofbiz_tool_require_root || ofbiz_snapshot_service_fail "Root permission is required."
    ofbiz_tool_install_base_packages || ofbiz_snapshot_service_fail "Base package installation failed."
    ofbiz_repository_init
}

ofbiz_snapshot_service_prepare_runtime() {
    local runtime_path="${1:?runtime path required}"
    local java_home="${2:?java home required}"
    local load_demo="${OFBIZ_LOAD_DEMO:-${OFBIZ_DEFAULT_LOAD_DEMO}}"

    export JAVA_HOME="${java_home}"
    export PATH="${JAVA_HOME}/bin:${PATH}"

    cd "${runtime_path}"

    if [[ -f "gradle/init-gradle-wrapper.sh" ]]; then
        bash gradle/init-gradle-wrapper.sh
    fi

    chmod +x gradlew

    if [[ "${load_demo}" == "1" ]]; then
        ./gradlew --no-daemon loadAll
    fi
}

ofbiz_snapshot_service_stage_replace() {
    local branch="${1:?branch required}"
    local java_major="${2:?java major required}"
    local java_home="${3:?java home required}"
    local runtime_path="${4:?runtime path required}"

    (
        local safe_name
        local staging_root
        local staging_runtime

        safe_name="$(ofbiz_repository_snapshot_safe_name "${branch}")"
        staging_root="$(ofbiz_repository_create_staging_dir             "$(ofbiz_repository_snapshots_dir)"             "snapshot-${safe_name}")"
        trap 'rm -rf -- "${staging_root}"' EXIT

        staging_runtime="${staging_root}/${OFBIZ_SNAPSHOT_DIR_PREFIX}${safe_name}"

        ofbiz_tool_git_clone_branch             "${OFBIZ_GIT_REPOSITORY_URL}"             "${branch}"             "${staging_runtime}"

        ofbiz_snapshot_service_prepare_runtime "${staging_runtime}" "${java_home}"
        ofbiz_repository_write_metadata             "${staging_runtime}"             "${OFBIZ_TYPE_SNAPSHOT}"             "${branch}"             "${java_major}"

        ofbiz_repository_install_is_valid             "${staging_runtime}"             "${OFBIZ_TYPE_SNAPSHOT}"             "${branch}"             "${java_major}"             || ofbiz_snapshot_service_fail "Staged snapshot validation failed: ${branch}"

        ofbiz_repository_replace_directory "${staging_runtime}" "${runtime_path}"             || ofbiz_snapshot_service_fail "Atomic snapshot replacement failed: ${branch}"
    )
}

ofbiz_snapshot_service_install() {
    local requested="${1:-${OFBIZ_SNAPSHOT_DEFAULT}}"
    local branch
    local java_major
    local runtime_path
    local java_home
    local force_reinstall="${OFBIZ_FORCE_REINSTALL:-${OFBIZ_DEFAULT_FORCE_REINSTALL}}"

    ofbiz_snapshot_service_require_environment

    branch="$(ofbiz_snapshot_resolve_branch "${requested}")"
    java_major="$(ofbiz_snapshot_required_java "${branch}")"
    runtime_path="$(ofbiz_repository_snapshot_path "${branch}")"

    java_home="$(ofbiz_tool_install_temurin_jdk         "${java_major}"         "$(ofbiz_repository_jdks_dir)"         "${ADOPTIUM_API_BASE_URL}")"

    if [[ "${force_reinstall}" != "1" ]]         && ofbiz_repository_install_is_valid             "${runtime_path}"             "${OFBIZ_TYPE_SNAPSHOT}"             "${branch}"             "${java_major}"; then
        ofbiz_repository_set_current "${runtime_path}"
        printf 'Snapshot already installed and activated: %s\n' "${branch}"
        return
    fi

    ofbiz_snapshot_service_stage_replace         "${branch}"         "${java_major}"         "${java_home}"         "${runtime_path}"

    ofbiz_repository_install_is_valid         "${runtime_path}"         "${OFBIZ_TYPE_SNAPSHOT}"         "${branch}"         "${java_major}"         || ofbiz_snapshot_service_fail "Installed snapshot validation failed: ${branch}"

    ofbiz_repository_set_current "${runtime_path}"

    printf 'Installed snapshot: %s @ %s\n'         "${branch}"         "$(ofbiz_tool_git_revision "${runtime_path}")"
}

ofbiz_snapshot_service_update() {
    local requested="${1:-${OFBIZ_SNAPSHOT_DEFAULT}}"
    local branch
    local java_major
    local runtime_path
    local java_home

    ofbiz_snapshot_service_require_environment

    branch="$(ofbiz_snapshot_resolve_branch "${requested}")"
    java_major="$(ofbiz_snapshot_required_java "${branch}")"
    runtime_path="$(ofbiz_repository_snapshot_path "${branch}")"

    ofbiz_repository_exists "${runtime_path}"         || ofbiz_snapshot_service_fail "Snapshot is not installed: ${branch}"

    java_home="$(ofbiz_tool_install_temurin_jdk         "${java_major}"         "$(ofbiz_repository_jdks_dir)"         "${ADOPTIUM_API_BASE_URL}")"

    ofbiz_snapshot_service_stage_replace         "${branch}"         "${java_major}"         "${java_home}"         "${runtime_path}"

    ofbiz_repository_install_is_valid         "${runtime_path}"         "${OFBIZ_TYPE_SNAPSHOT}"         "${branch}"         "${java_major}"         || ofbiz_snapshot_service_fail "Updated snapshot validation failed: ${branch}"

    ofbiz_repository_set_current "${runtime_path}"

    printf 'Updated snapshot: %s @ %s\n'         "${branch}"         "$(ofbiz_tool_git_revision "${runtime_path}")"
}

ofbiz_snapshot_service_list() {
    ofbiz_snapshot_list
}

ofbiz_snapshot_service_installed() {
    ofbiz_repository_list_snapshots
}

ofbiz_snapshot_service_use() {
    local requested="${1:?snapshot required}"
    local branch
    local java_major
    local runtime_path

    ofbiz_tool_require_root || ofbiz_snapshot_service_fail "Root permission is required."

    branch="$(ofbiz_snapshot_resolve_branch "${requested}")"
    java_major="$(ofbiz_snapshot_required_java "${branch}")"
    runtime_path="$(ofbiz_repository_snapshot_path "${branch}")"

    ofbiz_repository_install_is_valid         "${runtime_path}"         "${OFBIZ_TYPE_SNAPSHOT}"         "${branch}"         "${java_major}"         || ofbiz_snapshot_service_fail "Snapshot is incomplete or not installed: ${branch}"

    ofbiz_repository_set_current "${runtime_path}"

    printf 'Active snapshot: %s\n' "${branch}"
}
