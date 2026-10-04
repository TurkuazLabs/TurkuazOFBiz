# Dosya Yolu: /services/doctor-service.sh
# Amac: TurkuazOFBiz yerel ortam, release, snapshot ve Docker saglik kontrollerini koordine eder
# Service - Shell
# Version: 1.0.0
# Aciklama: Kurulum yapmadan bagimliliklari, uzak kaynaklari, branch'leri ve Docker durumunu raporlar
#
# Bagimli Oldugu Katman: Service | Repo | Tool | Config

set -euo pipefail

readonly DOCTOR_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOCTOR_ROOT_DIR="$(cd "${DOCTOR_SERVICE_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/config/sources.conf"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/services/version-resolver.sh"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/services/snapshot-resolver.sh"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/repositories/install-repository.sh"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/repositories/docker-repository.sh"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/tools/java-tool.sh"
# shellcheck source=/dev/null
source "${DOCTOR_ROOT_DIR}/tools/doctor-tool.sh"

OFBIZ_DOCTOR_FAILURES=0
OFBIZ_DOCTOR_WARNINGS=0

ofbiz_doctor_service_pass() {
    printf '[PASS] %s\n' "$*"
}

ofbiz_doctor_service_warn() {
    OFBIZ_DOCTOR_WARNINGS=$((OFBIZ_DOCTOR_WARNINGS + 1))
    printf '[WARN] %s\n' "$*"
}

ofbiz_doctor_service_fail() {
    OFBIZ_DOCTOR_FAILURES=$((OFBIZ_DOCTOR_FAILURES + 1))
    printf '[FAIL] %s\n' "$*"
}

ofbiz_doctor_service_reset() {
    OFBIZ_DOCTOR_FAILURES=0
    OFBIZ_DOCTOR_WARNINGS=0
}

ofbiz_doctor_service_summary() {
    printf '\nDoctor summary: %s failure(s), %s warning(s).\n'         "${OFBIZ_DOCTOR_FAILURES}"         "${OFBIZ_DOCTOR_WARNINGS}"

    [[ "${OFBIZ_DOCTOR_FAILURES}" -eq 0 ]]
}

ofbiz_doctor_service_check_command() {
    local command_name="${1:?command name required}"

    if ofbiz_doctor_tool_command_exists "${command_name}"; then
        ofbiz_doctor_service_pass "Command available: ${command_name}"
    else
        ofbiz_doctor_service_fail "Command missing: ${command_name}"
    fi
}

ofbiz_doctor_service_local_checks() {
    local command_name
    local install_root
    local current_path

    printf '== Local environment ==\n'

    for command_name in curl unzip tar git sha256sum sha512sum; do
        ofbiz_doctor_service_check_command "${command_name}"
    done

    install_root="$(ofbiz_repository_root)"

    if [[ -d "${install_root}" ]]; then
        ofbiz_doctor_service_pass "Install root exists: ${install_root}"
    else
        ofbiz_doctor_service_warn "Install root not created yet: ${install_root}"
    fi

    if current_path="$(ofbiz_repository_current_path 2>/dev/null)"; then
        if [[ -d "${current_path}" ]]; then
            ofbiz_doctor_service_pass "Active target: ${current_path}"
        else
            ofbiz_doctor_service_fail "Current symlink target is missing: ${current_path}"
        fi
    else
        ofbiz_doctor_service_warn "No active OFBiz target."
    fi
}

ofbiz_doctor_service_release_checks() {
    local requested="${1:-latest}"
    local version
    local java_major
    local archive_name
    local release_url_current
    local release_url_archive
    local checksum_url_current
    local checksum_url_archive
    local arch
    local adoptium_url

    printf '\n== Release ==\n'

    if ! version="$(ofbiz_resolve_version "${requested}")"; then
        ofbiz_doctor_service_fail "Release cannot be resolved: ${requested}"
        return
    fi

    java_major="$(ofbiz_required_java "${version}")"
    archive_name="apache-ofbiz-${version}.zip"

    ofbiz_doctor_service_pass "Release resolved: ${requested} -> ${version}"
    ofbiz_doctor_service_pass "Required Java major: ${java_major}"

    release_url_current="${OFBIZ_CURRENT_BASE_URL}/${archive_name}"
    release_url_archive="${OFBIZ_ARCHIVE_BASE_URL}/${archive_name}"
    checksum_url_current="${release_url_current}.sha512"
    checksum_url_archive="${release_url_archive}.sha512"

    if ofbiz_doctor_tool_http_exists "${release_url_current}"         || ofbiz_doctor_tool_http_exists "${release_url_archive}"; then
        ofbiz_doctor_service_pass "Release ZIP is reachable: ${archive_name}"
    else
        ofbiz_doctor_service_fail "Release ZIP is not reachable: ${archive_name}"
    fi

    if ofbiz_doctor_tool_http_exists "${checksum_url_current}"         || ofbiz_doctor_tool_http_exists "${checksum_url_archive}"; then
        ofbiz_doctor_service_pass "Release SHA-512 is reachable: ${archive_name}.sha512"
    else
        ofbiz_doctor_service_fail "Release SHA-512 is not reachable: ${archive_name}.sha512"
    fi

    if arch="$(ofbiz_tool_detect_adoptium_arch)"; then
        adoptium_url="${ADOPTIUM_API_BASE_URL}/${java_major}/ga/linux/${arch}/jdk/hotspot/normal/eclipse"

        if ofbiz_doctor_tool_http_exists "${adoptium_url}"; then
            ofbiz_doctor_service_pass "Adoptium JDK endpoint is reachable: Java ${java_major} / ${arch}"
        else
            ofbiz_doctor_service_fail "Adoptium JDK endpoint is not reachable: Java ${java_major} / ${arch}"
        fi
    else
        ofbiz_doctor_service_fail "Unsupported CPU architecture for Adoptium: $(uname -m)"
    fi
}

ofbiz_doctor_service_snapshot_checks() {
    local requested="${1:-trunk}"
    local branch
    local java_major

    printf '\n== Snapshot ==\n'

    if ! branch="$(ofbiz_snapshot_resolve_branch "${requested}")"; then
        ofbiz_doctor_service_fail "Snapshot cannot be resolved: ${requested}"
        return
    fi

    java_major="$(ofbiz_snapshot_required_java "${branch}")"

    ofbiz_doctor_service_pass "Snapshot resolved: ${requested} -> ${branch}"
    ofbiz_doctor_service_pass "Required Java major: ${java_major}"

    if ofbiz_doctor_tool_git_branch_exists "${OFBIZ_GIT_REPOSITORY_URL}" "${branch}"; then
        ofbiz_doctor_service_pass "Apache Git branch exists: ${branch}"
    else
        ofbiz_doctor_service_fail "Apache Git branch is not reachable: ${branch}"
    fi
}

ofbiz_doctor_service_docker_checks() {
    local release_image
    local snapshot_image

    printf '\n== Docker ==\n'

    if ! ofbiz_doctor_tool_docker_cli_exists; then
        ofbiz_doctor_service_warn "Docker CLI is not installed."
        return
    fi

    ofbiz_doctor_service_pass "Docker CLI is available."

    if ofbiz_doctor_tool_docker_ready; then
        ofbiz_doctor_service_pass "Docker daemon is ready."
    else
        ofbiz_doctor_service_warn "Docker daemon is not reachable."
    fi

    release_image="$(ofbiz_docker_repository_release_official_image "${OFBIZ_DEFAULT_VERSION}" runtime)"
    snapshot_image="$(ofbiz_docker_repository_snapshot_official_image trunk runtime)"

    if ofbiz_doctor_tool_docker_image_exists "${release_image}"; then
        ofbiz_doctor_service_pass "Official release image exists: ${release_image}"
    else
        ofbiz_doctor_service_warn "Official release image could not be verified: ${release_image}"
    fi

    if ofbiz_doctor_tool_docker_image_exists "${snapshot_image}"; then
        ofbiz_doctor_service_pass "Official snapshot image exists: ${snapshot_image}"
    else
        ofbiz_doctor_service_warn "Official snapshot image could not be verified: ${snapshot_image}"
    fi
}

ofbiz_doctor_service_run() {
    local scope="${1:-all}"
    local target="${2:-}"

    ofbiz_doctor_service_reset

    case "${scope}" in
        local)
            ofbiz_doctor_service_local_checks
            ;;
        release)
            ofbiz_doctor_service_release_checks "${target:-latest}"
            ;;
        snapshot)
            ofbiz_doctor_service_snapshot_checks "${target:-trunk}"
            ;;
        docker)
            ofbiz_doctor_service_docker_checks
            ;;
        all)
            ofbiz_doctor_service_local_checks
            ofbiz_doctor_service_release_checks "${target:-latest}"
            ofbiz_doctor_service_snapshot_checks trunk
            ofbiz_doctor_service_docker_checks
            ;;
        *)
            ofbiz_doctor_service_fail "Unknown doctor scope: ${scope}"
            ;;
    esac

    ofbiz_doctor_service_summary
}
