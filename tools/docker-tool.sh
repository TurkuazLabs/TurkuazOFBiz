# Dosya Yolu: /tools/docker-tool.sh
# Amac: Docker CLI islemlerini OFBiz Service katmani icin adaptor olarak sunar
# Tool - Shell
# Version: 1.1.0
# Aciklama: Image pull/build, container run/stop/status, manifest ve HTTPS smoke test islemlerini yonetir
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_docker_tool_require() {
    command -v docker >/dev/null 2>&1
    docker info >/dev/null 2>&1
}

ofbiz_docker_tool_pull() {
    local image="${1:?image required}"
    docker pull "${image}"
}

ofbiz_docker_tool_manifest_exists() {
    local image="${1:?image required}"
    docker manifest inspect "${image}" >/dev/null 2>&1
}

ofbiz_docker_tool_build() {
    local source_dir="${1:?source dir required}"
    local image="${2:?image required}"
    local variant="${3:?variant required}"
    local dockerfile="${4:-${source_dir}/Dockerfile}"
    local java_major="${5:-}"
    local build_args=()

    if [[ -n "${java_major}" ]]; then
        build_args+=(--build-arg "JAVA_MAJOR=${java_major}")
    fi

    DOCKER_BUILDKIT=1 docker build         "${build_args[@]}"         --target "${variant}"         --file "${dockerfile}"         --tag "${image}"         "${source_dir}"
}

ofbiz_docker_tool_run() {
    local image="${1:?image required}"
    local container_name="${2:?container name required}"
    local data_load="${3:?data load required}"
    local admin_user="${4:?admin user required}"
    local admin_password="${5:?admin password required}"
    local host="${6:?host required}"
    local bind_address="${7:?bind address required}"
    local https_port="${8:?https port required}"

    docker rm -f "${container_name}" >/dev/null 2>&1 || true

    docker run -d         --name "${container_name}"         --restart unless-stopped         --publish "${bind_address}:${https_port}:8443"         --env "OFBIZ_DATA_LOAD=${data_load}"         --env "OFBIZ_ADMIN_USER=${admin_user}"         --env "OFBIZ_ADMIN_PASSWORD=${admin_password}"         --env "OFBIZ_HOST=${host}"         --volume "${container_name}-runtime:/ofbiz/runtime"         --volume "${container_name}-config:/ofbiz/config"         --volume "${container_name}-lib-extra:/ofbiz/lib-extra"         "${image}"
}

ofbiz_docker_tool_stop() {
    local container_name="${1:?container name required}"
    docker stop "${container_name}"
}

ofbiz_docker_tool_remove() {
    local container_name="${1:?container name required}"
    docker rm -f "${container_name}"
}

ofbiz_docker_tool_status() {
    local container_name="${1:?container name required}"
    docker inspect         --format '{{.Name}} {{.State.Status}} {{.Config.Image}}'         "${container_name}"
}

ofbiz_docker_tool_logs() {
    local container_name="${1:?container name required}"
    docker logs "${container_name}"
}

ofbiz_docker_tool_smoke() {
    local image="${1:?image required}"
    local container_name="${2:?container name required}"
    local port="${3:?port required}"
    local url="${4:?url required}"
    local timeout_seconds="${5:?timeout required}"
    local elapsed="0"
    local http_code="000"

    docker rm -f "${container_name}" >/dev/null 2>&1 || true

    docker run -d         --name "${container_name}"         --publish "127.0.0.1:${port}:8443"         --env "OFBIZ_SKIP_INIT=1"         --env "OFBIZ_HOST=localhost"         "${image}" >/dev/null

    while (( elapsed < timeout_seconds )); do
        http_code="$(curl             --insecure             --silent             --output /dev/null             --write-out '%{http_code}'             "${url}" 2>/dev/null || true)"

        if [[ "${http_code}" =~ ^[23][0-9][0-9]$ ]]; then
            printf '[ofbiz-docker] HTTPS ready with status %s after %ss\n' "${http_code}" "${elapsed}" >&2
            return 0
        fi

        if [[ "$(docker inspect --format '{{.State.Running}}' "${container_name}" 2>/dev/null || true)" != "true" ]]; then
            printf '[ofbiz-docker] Container stopped before readiness.\n' >&2
            return 1
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    printf '[ofbiz-docker] HTTPS smoke timeout. Last status: %s\n' "${http_code}" >&2
    return 1
}
