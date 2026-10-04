# Dosya Yolu: /services/docker-service.sh
# Amac: OFBiz release ve snapshot Docker image/container is kurallarini yonetir
# Service - Shell
# Version: 1.2.0
# Aciklama: Resmi image pull, kaynak koddan build, container run ve smoke test akislarini koordine eder
#
# Bagimli Oldugu Katman: Service | Repo | Tool | Config

set -euo pipefail

readonly DOCKER_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOCKER_SERVICE_ROOT="$(cd "${DOCKER_SERVICE_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/config/sources.conf"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/config/docker.conf"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/services/version-resolver.sh"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/services/snapshot-resolver.sh"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/repositories/docker-repository.sh"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/tools/docker-tool.sh"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/tools/release-tool.sh"
# shellcheck source=/dev/null
source "${DOCKER_SERVICE_ROOT}/tools/git-tool.sh"

ofbiz_docker_service_fail() {
    printf '[docker-service] ERROR: %s\n' "$*" >&2
    return 1
}

ofbiz_docker_service_require() {
    ofbiz_docker_tool_require || ofbiz_docker_service_fail "Docker daemon is not available."
}

ofbiz_docker_service_resolve() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local identifier

    ofbiz_docker_repository_validate_variant "${variant}"         || ofbiz_docker_service_fail "Unsupported Docker variant: ${variant}"

    case "${type}" in
        release)
            identifier="$(ofbiz_resolve_version "${requested}")"
            ;;
        snapshot)
            identifier="$(ofbiz_snapshot_resolve_branch "${requested}")"
            ;;
        *)
            ofbiz_docker_service_fail "Unsupported Docker target type: ${type}"
            ;;
    esac

    printf '%s\n' "${identifier}"
}

ofbiz_docker_service_required_java() {
    local type="${1:?type required}"
    local identifier="${2:?identifier required}"

    case "${type}" in
        release)
            ofbiz_required_java "${identifier}"
            ;;
        snapshot)
            ofbiz_snapshot_required_java "${identifier}"
            ;;
        *)
            return 1
            ;;
    esac
}

ofbiz_docker_service_official_image() {
    local type="${1:?type required}"
    local identifier="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"

    case "${type}" in
        release)
            ofbiz_docker_repository_release_official_image "${identifier}" "${variant}"
            ;;
        snapshot)
            ofbiz_docker_repository_snapshot_official_image "${identifier}" "${variant}"
            ;;
        *)
            return 1
            ;;
    esac
}

ofbiz_docker_service_pull() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local identifier
    local image

    ofbiz_docker_service_require

    identifier="$(ofbiz_docker_service_resolve "${type}" "${requested}" "${variant}")"
    image="$(ofbiz_docker_service_official_image "${type}" "${identifier}" "${variant}")"         || ofbiz_docker_service_fail "No official image mapping for ${type}:${identifier} ${variant}."

    ofbiz_docker_tool_manifest_exists "${image}"         || ofbiz_docker_service_fail "Official image does not exist: ${image}. Use docker build instead."

    ofbiz_docker_tool_pull "${image}"
    printf '%s\n' "${image}"
}

ofbiz_docker_service_prepare_release_source() {
    local version="${1:?version required}"
    local work_dir="${2:?work dir required}"

    ofbiz_tool_download_release         "${version}"         "${OFBIZ_CURRENT_BASE_URL}"         "${OFBIZ_ARCHIVE_BASE_URL}"         "${work_dir}"

    printf '%s/apache-ofbiz-%s\n' "${work_dir}" "${version}"
}

ofbiz_docker_service_prepare_snapshot_source() {
    local branch="${1:?branch required}"
    local work_dir="${2:?work dir required}"
    local source_dir="${work_dir}/ofbiz-framework"

    ofbiz_tool_git_clone_branch "${OFBIZ_GIT_REPOSITORY_URL}" "${branch}" "${source_dir}"
    printf '%s\n' "${source_dir}"
}

ofbiz_docker_service_build() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local identifier
    local image
    local work_dir
    local source_dir
    local dockerfile
    local java_major=""

    ofbiz_docker_service_require

    identifier="$(ofbiz_docker_service_resolve "${type}" "${requested}" "${variant}")"
    image="${OFBIZ_IMAGE:-$(ofbiz_docker_repository_local_image "${type}" "${identifier}" "${variant}")}"
    work_dir="$(mktemp -d)"

    (
        trap 'rm -rf -- "${work_dir}"' EXIT

        case "${type}" in
            release)
                source_dir="$(ofbiz_docker_service_prepare_release_source "${identifier}" "${work_dir}")"
                ;;
            snapshot)
                source_dir="$(ofbiz_docker_service_prepare_snapshot_source "${identifier}" "${work_dir}")"
                ;;
        esac

        [[ -d "${source_dir}" ]] || ofbiz_docker_service_fail "Docker source directory not found."

        dockerfile="${source_dir}/Dockerfile"

        if [[ ! -f "${dockerfile}" ]]; then
            dockerfile="${DOCKER_SERVICE_ROOT}/tools/docker/Dockerfile.compat"
            java_major="$(ofbiz_docker_service_required_java "${type}" "${identifier}")"
        fi

        ofbiz_docker_tool_build \
            "${source_dir}" \
            "${image}" \
            "${variant}" \
            "${dockerfile}" \
            "${java_major}"
    )

    printf '%s\n' "${image}"
}

ofbiz_docker_service_resolve_runtime_image() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local identifier
    local official_image
    local local_image

    identifier="$(ofbiz_docker_service_resolve "${type}" "${requested}" "${variant}")"

    if official_image="$(ofbiz_docker_service_official_image "${type}" "${identifier}" "${variant}" 2>/dev/null)"; then
        if ofbiz_docker_tool_manifest_exists "${official_image}"; then
            printf '%s\n' "${official_image}"
            return
        fi
    fi

    local_image="$(ofbiz_docker_repository_local_image "${type}" "${identifier}" "${variant}")"

    if docker image inspect "${local_image}" >/dev/null 2>&1; then
        printf '%s\n' "${local_image}"
        return
    fi

    ofbiz_docker_service_fail "No usable image. Pull official image or build local image first."
}

ofbiz_docker_service_run() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local identifier
    local image
    local container_name
    local data_load
    local admin_password

    ofbiz_docker_service_require

    identifier="$(ofbiz_docker_service_resolve "${type}" "${requested}" "${variant}")"
    image="$(ofbiz_docker_service_resolve_runtime_image "${type}" "${identifier}" "${variant}")"
    container_name="$(ofbiz_docker_repository_container_name "${type}" "${identifier}")"

    if ofbiz_docker_tool_image_is_compat "${image}"; then
        if [[ "${variant}" != "${OFBIZ_DOCKER_VARIANT_DEMO}" ]]; then
            ofbiz_docker_service_fail                 "Legacy compat runtime image has no automatic data initialization. Build and run the demo variant."
        fi

        ofbiz_docker_tool_run_compat             "${image}"             "${container_name}"             "${OFBIZ_HTTPS_BIND:-${OFBIZ_DOCKER_DEFAULT_HTTPS_BIND}}"             "${OFBIZ_HTTPS_PORT:-${OFBIZ_DOCKER_DEFAULT_HTTPS_PORT}}"

        printf '%s\n' "${container_name}"
        return
    fi

    data_load="${OFBIZ_DATA_LOAD:-${OFBIZ_DOCKER_DEFAULT_DATA_LOAD}}"
    admin_password="${OFBIZ_ADMIN_PASSWORD:-}"

    [[ -n "${admin_password}" ]]         || ofbiz_docker_service_fail "OFBIZ_ADMIN_PASSWORD must be set before running a modern container."

    ofbiz_docker_tool_run         "${image}"         "${container_name}"         "${data_load}"         "${OFBIZ_ADMIN_USER:-${OFBIZ_DOCKER_DEFAULT_ADMIN_USER}}"         "${admin_password}"         "${OFBIZ_HOST:-${OFBIZ_DOCKER_DEFAULT_HOST}}"         "${OFBIZ_HTTPS_BIND:-${OFBIZ_DOCKER_DEFAULT_HTTPS_BIND}}"         "${OFBIZ_HTTPS_PORT:-${OFBIZ_DOCKER_DEFAULT_HTTPS_PORT}}"

    printf '%s\n' "${container_name}"
}

ofbiz_docker_service_smoke() {
    local type="${1:?type required}"
    local requested="${2:?identifier required}"
    local variant="${3:-demo}"
    local identifier
    local image
    local result="0"

    ofbiz_docker_service_require

    identifier="$(ofbiz_docker_service_resolve "${type}" "${requested}" "${variant}")"
    image="$(ofbiz_docker_service_resolve_runtime_image "${type}" "${identifier}" "${variant}")"

    if ! ofbiz_docker_tool_smoke         "${image}"         "${OFBIZ_DOCKER_SMOKE_CONTAINER}"         "${OFBIZ_DOCKER_SMOKE_PORT}"         "${OFBIZ_DOCKER_SMOKE_URL}"         "${OFBIZ_DOCKER_SMOKE_TIMEOUT_SECONDS}"; then
        result="1"
        ofbiz_docker_tool_logs "${OFBIZ_DOCKER_SMOKE_CONTAINER}" >&2 || true
    fi

    ofbiz_docker_tool_remove "${OFBIZ_DOCKER_SMOKE_CONTAINER}" >/dev/null 2>&1 || true
    [[ "${result}" == "0" ]] || return 1

    printf 'Docker smoke test successful: %s\n' "${image}"
}

ofbiz_docker_service_status() {
    local container_name="${1:-${OFBIZ_DOCKER_DEFAULT_CONTAINER_NAME}}"
    ofbiz_docker_tool_status "${container_name}"
}

ofbiz_docker_service_stop() {
    local container_name="${1:?container name required}"
    ofbiz_docker_tool_stop "${container_name}"
}
