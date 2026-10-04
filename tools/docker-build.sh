# Dosya Yolu: /tools/docker-build.sh
# Amac: Eski Docker build komutlarini yeni Controller Docker akisina yonlendirir
# Tool - Shell
# Version: 3.0.0
# Aciklama: Geriye uyumlu wrapper; yeni kullanim controllers/ofbiz.sh docker komutlaridir
#
# Bagimli Oldugu Katman: Tool | Controller

set -euo pipefail

readonly TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OFBIZ_ROOT_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
readonly CONTROLLER="${OFBIZ_ROOT_DIR}/controllers/ofbiz.sh"

requested="${1:-latest}"

if [[ "${requested}" == "list" ]]; then
    exec bash "${CONTROLLER}" release list
fi

exec bash "${CONTROLLER}" docker build release "${requested}" "${OFBIZ_DOCKER_TARGET:-runtime}"
