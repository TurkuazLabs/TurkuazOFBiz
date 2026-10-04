# Dosya Yolu: /repositories/docker-repository.sh
# Amac: OFBiz Docker hedefleri icin resmi ve local image referanslarini cozer
# Repo - Shell
# Version: 1.0.0
# Aciklama: Release/snapshot kimligi ve runtime/demo varyantindan image ve container isimleri uretir
#
# Bagimli Oldugu Katman: Repo | Config

if [[ "${OFBIZ_DOCKER_REPOSITORY_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
OFBIZ_DOCKER_REPOSITORY_LOADED="1"

set -euo pipefail

readonly DOCKER_REPOSITORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOCKER_REPOSITORY_ROOT="$(cd "${DOCKER_REPOSITORY_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${DOCKER_REPOSITORY_ROOT}/config/docker.conf"

ofbiz_docker_repository_validate_variant() {
    local variant="${1:?variant required}"

    [[ "${variant}" == "${OFBIZ_DOCKER_VARIANT_RUNTIME}" || "${variant}" == "${OFBIZ_DOCKER_VARIANT_DEMO}" ]]
}

ofbiz_docker_repository_release_official_image() {
    local version="${1:?version required}"
    local variant="${2:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local tag="${version}"

    ofbiz_docker_repository_validate_variant "${variant}" || return 1

    if [[ "${variant}" == "${OFBIZ_DOCKER_VARIANT_DEMO}" ]]; then
        tag="${version}${OFBIZ_DOCKER_RELEASE_DEMO_SUFFIX}"
    fi

    printf '%s:%s\n' "${OFBIZ_DOCKER_REGISTRY}" "${tag}"
}

ofbiz_docker_repository_snapshot_official_image() {
    local branch="${1:?branch required}"
    local variant="${2:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local tag=""

    ofbiz_docker_repository_validate_variant "${variant}" || return 1

    case "${branch}:${variant}" in
        trunk:runtime)
            tag="${OFBIZ_DOCKER_SNAPSHOT_TRUNK_RUNTIME_TAG}"
            ;;
        trunk:demo)
            tag="${OFBIZ_DOCKER_SNAPSHOT_TRUNK_DEMO_TAG}"
            ;;
        release24.09:runtime)
            tag="${OFBIZ_DOCKER_SNAPSHOT_24_09_RUNTIME_TAG}"
            ;;
        release24.09:demo)
            tag="${OFBIZ_DOCKER_SNAPSHOT_24_09_DEMO_TAG}"
            ;;
        *)
            return 1
            ;;
    esac

    printf '%s:%s\n' "${OFBIZ_DOCKER_REGISTRY}" "${tag}"
}

ofbiz_docker_repository_local_image() {
    local type="${1:?type required}"
    local identifier="${2:?identifier required}"
    local variant="${3:-${OFBIZ_DOCKER_DEFAULT_VARIANT}}"
    local safe_identifier

    ofbiz_docker_repository_validate_variant "${variant}" || return 1

    safe_identifier="${identifier//\//-}"
    printf '%s:%s-%s-%s\n' "${OFBIZ_DOCKER_LOCAL_IMAGE_PREFIX}" "${type}" "${safe_identifier}" "${variant}"
}

ofbiz_docker_repository_container_name() {
    local type="${1:?type required}"
    local identifier="${2:?identifier required}"
    local safe_identifier

    safe_identifier="${identifier//\//-}"
    safe_identifier="${safe_identifier//./-}"

    printf '%s-%s-%s\n'         "${OFBIZ_DOCKER_CONTAINER_NAME:-${OFBIZ_DOCKER_DEFAULT_CONTAINER_NAME}}"         "${type}"         "${safe_identifier}"
}
