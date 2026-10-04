# Dosya Yolu: /services/snapshot-service.sh
# Amac: Apache OFBiz branch tabanli snapshot kurulum is kurallarini yonetir
# Service - Shell
# Version: 1.0.1
# Aciklama: Trunk ve release branch clone, update, JDK, demo veri ve aktif snapshot islemlerini koordine eder
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

    if ofbiz_repository_exists "${runtime_path}" && [[ "${force_reinstall}" != "1" ]]; then
        ofbiz_repository_set_current "${runtime_path}"
        printf 'Snapshot already installed and activated: %s\n' "${branch}"
        return
    fi

    java_home="$(ofbiz_tool_install_temurin_jdk         "${java_major}"         "$(ofbiz_repository_jdks_dir)"         "${ADOPTIUM_API_BASE_URL}")"

    rm -rf "${runtime_path}"

    ofbiz_tool_git_clone_branch "${OFBIZ_GIT_REPOSITORY_URL}" "${branch}" "${runtime_path}"
    ofbiz_snapshot_service_prepare_runtime "${runtime_path}" "${java_home}"
    ofbiz_repository_write_metadata "${runtime_path}" "${OFBIZ_TYPE_SNAPSHOT}" "${branch}" "${java_major}"
    ofbiz_repository_set_current "${runtime_path}"

    printf 'Installed snapshot: %s @ %s\n' "${branch}" "$(ofbiz_tool_git_revision "${runtime_path}")"
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

    ofbiz_repository_exists "${runtime_path}" || ofbiz_snapshot_service_fail "Snapshot is not installed: ${branch}"

    java_home="$(ofbiz_tool_install_temurin_jdk         "${java_major}"         "$(ofbiz_repository_jdks_dir)"         "${ADOPTIUM_API_BASE_URL}")"

    ofbiz_tool_git_update_branch "${branch}" "${runtime_path}"
    ofbiz_snapshot_service_prepare_runtime "${runtime_path}" "${java_home}"
    ofbiz_repository_write_metadata "${runtime_path}" "${OFBIZ_TYPE_SNAPSHOT}" "${branch}" "${java_major}"
    ofbiz_repository_set_current "${runtime_path}"

    printf 'Updated snapshot: %s @ %s\n' "${branch}" "$(ofbiz_tool_git_revision "${runtime_path}")"
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
    local runtime_path

    ofbiz_tool_require_root || ofbiz_snapshot_service_fail "Root permission is required."

    branch="$(ofbiz_snapshot_resolve_branch "${requested}")"
    runtime_path="$(ofbiz_repository_snapshot_path "${branch}")"

    ofbiz_repository_exists "${runtime_path}" || ofbiz_snapshot_service_fail "Snapshot is not installed: ${branch}"
    ofbiz_repository_set_current "${runtime_path}"

    printf 'Active snapshot: %s\n' "${branch}"
}
