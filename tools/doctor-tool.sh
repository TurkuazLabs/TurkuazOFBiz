# Dosya Yolu: /tools/doctor-tool.sh
# Amac: TurkuazOFBiz doctor servisi icin dis sistem ve yerel ortam kontrollerini saglar
# Tool - Shell
# Version: 1.0.0
# Aciklama: Komut, HTTP, Git branch ve Docker daemon kontrollerini yan etkisiz olarak yapar
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_doctor_tool_command_exists() {
    local command_name="${1:?command name required}"
    command -v "${command_name}" >/dev/null 2>&1
}

ofbiz_doctor_tool_http_exists() {
    local url="${1:?url required}"

    curl         --fail         --silent         --show-error         --location         --head         --retry 2         --connect-timeout 15         --max-time 60         "${url}" >/dev/null
}

ofbiz_doctor_tool_git_branch_exists() {
    local repository_url="${1:?repository url required}"
    local branch="${2:?branch required}"

    git ls-remote         --exit-code         --heads         "${repository_url}"         "refs/heads/${branch}" >/dev/null 2>&1
}

ofbiz_doctor_tool_docker_cli_exists() {
    command -v docker >/dev/null 2>&1
}

ofbiz_doctor_tool_docker_ready() {
    ofbiz_doctor_tool_docker_cli_exists || return 1
    docker info >/dev/null 2>&1
}

ofbiz_doctor_tool_docker_image_exists() {
    local image="${1:?image required}"

    ofbiz_doctor_tool_docker_cli_exists || return 1
    docker manifest inspect "${image}" >/dev/null 2>&1
}
