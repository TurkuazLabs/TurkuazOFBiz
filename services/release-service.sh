# Dosya Yolu: /services/release-service.sh
# Amac: Apache OFBiz resmi release kurulum is kurallarini yonetir
# Service - Shell
# Version: 1.0.1
# Aciklama: Release secimi, JDK hazirlama, indirme, demo veri ve aktif surum islemlerini koordine eder
#
# Bagimli Oldugu Katman: Service | Repo | Tool | Config

set -euo pipefail

readonly RELEASE_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RELEASE_ROOT_DIR="$(cd "${RELEASE_SERVICE_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/config/sources.conf"
# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/services/version-resolver.sh"
# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/repositories/install-repository.sh"
# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/tools/system-tool.sh"
# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/tools/java-tool.sh"
# shellcheck source=/dev/null
source "${RELEASE_ROOT_DIR}/tools/release-tool.sh"

ofbiz_release_service_fail() {
    printf '[release-service] ERROR: %s\n' "$*" >&2
    return 1
}

ofbiz_release_service_require_environment() {
    ofbiz_tool_require_root || ofbiz_release_service_fail "Root permission is required."
    ofbiz_tool_install_base_packages || ofbiz_release_service_fail "Base package installation failed."
    ofbiz_repository_init
}

ofbiz_release_service_prepare_runtime() {
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

ofbiz_release_service_install() {
    local requested="${1:-latest}"
    local version
    local java_major
    local runtime_path
    local java_home
    local force_reinstall="${OFBIZ_FORCE_REINSTALL:-${OFBIZ_DEFAULT_FORCE_REINSTALL}}"

    ofbiz_release_service_require_environment

    version="$(ofbiz_resolve_version "${requested}")"
    java_major="$(ofbiz_required_java "${version}")"
    runtime_path="$(ofbiz_repository_release_path "${version}")"

    if ofbiz_repository_exists "${runtime_path}" && [[ "${force_reinstall}" != "1" ]]; then
        ofbiz_repository_set_current "${runtime_path}"
        printf 'Release already installed and activated: %s\n' "${version}"
        return
    fi

    java_home="$(ofbiz_tool_install_temurin_jdk         "${java_major}"         "$(ofbiz_repository_jdks_dir)"         "${ADOPTIUM_API_BASE_URL}")"

    rm -rf "${runtime_path}"

    ofbiz_tool_download_release         "${version}"         "${OFBIZ_CURRENT_BASE_URL}"         "${OFBIZ_ARCHIVE_BASE_URL}"         "$(ofbiz_repository_releases_dir)"

    [[ -d "${runtime_path}" ]] || ofbiz_release_service_fail "Release extraction failed: ${runtime_path}"

    ofbiz_release_service_prepare_runtime "${runtime_path}" "${java_home}"
    ofbiz_repository_write_metadata "${runtime_path}" "${OFBIZ_TYPE_RELEASE}" "${version}" "${java_major}"
    ofbiz_repository_set_current "${runtime_path}"

    printf 'Installed release: %s\n' "${version}"
}

ofbiz_release_service_list() {
    ofbiz_list_versions
}

ofbiz_release_service_installed() {
    ofbiz_repository_list_releases
}

ofbiz_release_service_use() {
    local requested="${1:?version required}"
    local version
    local runtime_path

    ofbiz_tool_require_root || ofbiz_release_service_fail "Root permission is required."

    version="$(ofbiz_resolve_version "${requested}")"
    runtime_path="$(ofbiz_repository_release_path "${version}")"

    ofbiz_repository_exists "${runtime_path}" || ofbiz_release_service_fail "Release is not installed: ${version}"
    ofbiz_repository_set_current "${runtime_path}"

    printf 'Active release: %s\n' "${version}"
}
