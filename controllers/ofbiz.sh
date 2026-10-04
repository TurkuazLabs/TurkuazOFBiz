# Dosya Yolu: /controllers/ofbiz.sh
# Amac: OFBiz komut satiri isteklerini alip ilgili Service katmanina yonlendirir
# Controller - Shell
# Version: 4.2.0
# Aciklama: Release, snapshot, runtime ve Docker komutlari icin ince routing controller'i
#
# Bagimli Oldugu Katman: Controller | Service | View

set -euo pipefail

readonly CONTROLLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OFBIZ_ROOT_DIR="$(cd "${CONTROLLER_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${OFBIZ_ROOT_DIR}/services/release-service.sh"
# shellcheck source=/dev/null
source "${OFBIZ_ROOT_DIR}/services/snapshot-service.sh"
# shellcheck source=/dev/null
source "${OFBIZ_ROOT_DIR}/services/runtime-service.sh"
# shellcheck source=/dev/null
source "${OFBIZ_ROOT_DIR}/services/docker-service.sh"
# shellcheck source=/dev/null
source "${OFBIZ_ROOT_DIR}/views/help-view.sh"

ofbiz_controller_release() {
    local action="${1:-list}"
    local target="${2:-latest}"

    case "${action}" in
        list)
            ofbiz_release_service_list
            ;;
        install)
            ofbiz_release_service_install "${target}"
            ;;
        installed)
            ofbiz_release_service_installed
            ;;
        use)
            ofbiz_release_service_use "${target}"
            ;;
        *)
            ofbiz_view_help
            return 1
            ;;
    esac
}

ofbiz_controller_snapshot() {
    local action="${1:-list}"
    local target="${2:-trunk}"

    case "${action}" in
        list)
            ofbiz_snapshot_service_list
            ;;
        install)
            ofbiz_snapshot_service_install "${target}"
            ;;
        update)
            ofbiz_snapshot_service_update "${target}"
            ;;
        installed)
            ofbiz_snapshot_service_installed
            ;;
        use)
            ofbiz_snapshot_service_use "${target}"
            ;;
        *)
            ofbiz_view_help
            return 1
            ;;
    esac
}

ofbiz_controller_docker() {
    local action="${1:-help}"
    local type="${2:-release}"
    local target="${3:-latest}"
    local variant="${4:-runtime}"

    case "${action}" in
        pull)
            ofbiz_docker_service_pull "${type}" "${target}" "${variant}"
            ;;
        build)
            ofbiz_docker_service_build "${type}" "${target}" "${variant}"
            ;;
        run)
            ofbiz_docker_service_run "${type}" "${target}" "${variant}"
            ;;
        smoke)
            ofbiz_docker_service_smoke "${type}" "${target}" "${variant}"
            ;;
        status)
            ofbiz_docker_service_status "${2:-ofbiz}"
            ;;
        stop)
            ofbiz_docker_service_stop "${2:?container name required}"
            ;;
        *)
            ofbiz_view_help
            return 1
            ;;
    esac
}

ofbiz_controller_main() {
    local domain="${1:-help}"

    case "${domain}" in
        release)
            ofbiz_controller_release "${2:-list}" "${3:-latest}"
            ;;
        snapshot)
            ofbiz_controller_snapshot "${2:-list}" "${3:-trunk}"
            ;;
        docker)
            ofbiz_controller_docker "${2:-help}" "${3:-release}" "${4:-latest}" "${5:-runtime}"
            ;;
        current)
            ofbiz_runtime_service_current
            ;;
        run)
            ofbiz_runtime_service_run "${2:-start}" "${3:-current}"
            ;;
        list)
            ofbiz_release_service_list
            ;;
        install)
            ofbiz_release_service_install "${2:-latest}"
            ;;
        installed)
            ofbiz_release_service_installed
            ;;
        use)
            ofbiz_release_service_use "${2:-latest}"
            ;;
        -h|--help|help)
            ofbiz_view_help
            ;;
        *)
            ofbiz_view_help
            return 1
            ;;
    esac
}

ofbiz_controller_main "$@"
