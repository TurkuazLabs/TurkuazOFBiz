# Dosya Yolu: /install.sh
# Amac: Linux ve WSL kullanicisi icin TurkuazOFBiz Docker kurulumunu tek komutta yonetir
# Tool - Shell
# Version: 1.2.0
# Aciklama: Stabil TurkuazOFBiz release'ini hazirlar, Docker'i dogrular, OFBiz 24.09.07 demo container'ini baslatir ve tarayiciyi acar
#
# Bagimli Oldugu Katman: Tool | Controller | Service | Config

set -euo pipefail

readonly PROJECT_REPOSITORY="TurkuazLabs/TurkuazOFBiz"
readonly PROJECT_URL="https://github.com/${PROJECT_REPOSITORY}"
readonly APP_HOME="${TURKUAZOFBIZ_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/turkuazofbiz}"
readonly MANAGED_REPO="${APP_HOME}/repo"
readonly SECRET_FILE="${APP_HOME}/admin-password.txt"

ACTION="${1:-install}"
OFBIZ_VERSION="${OFBIZ_VERSION:-24.09.07}"
OFBIZ_VARIANT="${OFBIZ_VARIANT:-demo}"
OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT:-8443}"
OFBIZ_APP_PATH="${OFBIZ_APP_PATH:-/partymgr}"

log() {
    printf '\n[TurkuazOFBiz] %s\n' "$*"
}

fail() {
    printf '\n[TurkuazOFBiz] ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    local name="${1:?command required}"
    command -v "${name}" >/dev/null 2>&1 || fail "Gerekli komut bulunamadi: ${name}"
}

script_repo_root() {
    local script_path
    local root

    script_path="${BASH_SOURCE[0]:-}"

    if [[ -z "${script_path}" || ! -f "${script_path}" ]]; then
        return 1
    fi

    root="$(cd "$(dirname "${script_path}")" && pwd)"

    [[ -f "${root}/controllers/ofbiz.sh" ]] || return 1
    printf '%s\n' "${root}"
}

latest_release_tag() {
    local latest_url

    require_command curl

    latest_url="$(curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --output /dev/null \
        --write-out '%{url_effective}' \
        "${PROJECT_URL}/releases/latest")"

    basename "${latest_url}"
}

sync_managed_repo() {
    local tag
    local temp_root
    local archive
    local source_root

    require_command curl
    require_command tar

    tag="$(latest_release_tag)"
    temp_root="$(mktemp -d)"
    archive="${temp_root}/turkuazofbiz.tar.gz"

    log "Stabil TurkuazOFBiz ${tag} indiriliyor"

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        "${PROJECT_URL}/archive/refs/tags/${tag}.tar.gz" \
        --output "${archive}"

    mkdir -p "${temp_root}/extract" "${MANAGED_REPO}"

    tar -xzf "${archive}" -C "${temp_root}/extract"

    source_root="$(find "${temp_root}/extract" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -n "${source_root}" ]] || fail "Release arsivi acilamadi."

    find "${MANAGED_REPO}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
    cp -a "${source_root}/." "${MANAGED_REPO}/"

    rm -rf -- "${temp_root}"
}

resolve_repo_root() {
    local local_root

    if local_root="$(script_repo_root 2>/dev/null)"; then
        printf '%s\n' "${local_root}"
        return
    fi

    if [[ ! -f "${MANAGED_REPO}/controllers/ofbiz.sh" ]]; then
        sync_managed_repo
    fi

    printf '%s\n' "${MANAGED_REPO}"
}

ensure_docker() {
    require_command docker

    if ! docker info >/dev/null 2>&1; then
        fail "Docker daemon erisilebilir degil. WSL kullaniyorsan Docker Desktop WSL integration acik olmali."
    fi
}

admin_password() {
    local password

    mkdir -p "${APP_HOME}"

    if [[ "${OFBIZ_VARIANT}" == "demo" ]]; then
        password="ofbiz"
        printf '%s\n' "${password}" > "${SECRET_FILE}"
        chmod 600 "${SECRET_FILE}"
        printf '%s\n' "${password}"
        return
    fi

    if [[ -s "${SECRET_FILE}" ]]; then
        cat "${SECRET_FILE}"
        return
    fi

    if command -v openssl >/dev/null 2>&1; then
        password="$(openssl rand -hex 20)"
    else
        password="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"
    fi

    printf '%s\n' "${password}" > "${SECRET_FILE}"
    chmod 600 "${SECRET_FILE}"
    printf '%s\n' "${password}"
}

container_name() {
    printf 'ofbiz-release-%s\n' "${OFBIZ_VERSION//./-}"
}

ofbiz_url() {
    printf 'https://localhost:%s%s\n' "${OFBIZ_HTTPS_PORT}" "${OFBIZ_APP_PATH}"
}

wait_ofbiz_ready() {
    local url
    local http_code
    local attempt

    url="$(ofbiz_url)"

    for attempt in $(seq 1 72); do
        http_code="$(curl             --insecure             --silent             --output /dev/null             --write-out '%{http_code}'             "${url}" 2>/dev/null || true)"

        if [[ "${http_code}" =~ ^[23][0-9][0-9]$ ]]; then
            printf '[TurkuazOFBiz] OFBiz hazir: HTTP %s\n' "${http_code}"
            return
        fi

        sleep 5
    done

    fail "OFBiz HTTPS hazirlik zaman asimina ugradi: ${url}"
}

open_browser() {
    local url

    url="$(ofbiz_url)"

    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command "Start-Process '${url}'" >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${url}" >/dev/null 2>&1 || true
    fi
}

install_ofbiz() {
    local repo_root
    local password

    ensure_docker
    repo_root="$(resolve_repo_root)"
    password="$(admin_password)"

    log "Docker ortam kontrolu"
    (
        cd "${repo_root}"
        bash controllers/ofbiz.sh doctor docker
    )

    log "Apache OFBiz ${OFBIZ_VERSION} ${OFBIZ_VARIANT} image hazirlaniyor"
    (
        cd "${repo_root}"
        bash controllers/ofbiz.sh docker pull release "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
    )

    log "Apache OFBiz baslatiliyor"
    (
        cd "${repo_root}"
        OFBIZ_ADMIN_PASSWORD="${password}" \
        OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT}" \
            bash controllers/ofbiz.sh docker run \
                release \
                "${OFBIZ_VERSION}" \
                "${OFBIZ_VARIANT}"
    )

    wait_ofbiz_ready

    printf '\n============================================================\n'
    printf ' TurkuazOFBiz hazir\n'
    printf '============================================================\n'
    printf ' Adres       : %s\n' "$(ofbiz_url)"
    printf ' Kullanici   : admin\n'
    printf ' Parola      : %s\n' "${password}"
    printf ' Parola dosya: %s\n\n' "${SECRET_FILE}"

    open_browser
}

start_ofbiz() {
    local container

    ensure_docker
    container="$(container_name)"

    if docker inspect "${container}" >/dev/null 2>&1; then
        docker start "${container}" >/dev/null
        wait_ofbiz_ready
        open_browser
    else
        install_ofbiz
    fi
}

stop_ofbiz() {
    local container

    ensure_docker
    container="$(container_name)"
    docker stop "${container}" >/dev/null 2>&1 || true
    printf 'TurkuazOFBiz container durduruldu: %s\n' "${container}"
}

status_ofbiz() {
    local container

    ensure_docker
    container="$(container_name)"

    docker ps -a \
        --filter "name=^/${container}$" \
        --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
}

doctor_ofbiz() {
    local repo_root

    ensure_docker
    repo_root="$(resolve_repo_root)"

    (
        cd "${repo_root}"
        bash controllers/ofbiz.sh doctor docker
    )
}

password_ofbiz() {
    local password

    if [[ "${OFBIZ_VARIANT}" == "demo" ]]; then
        password="$(admin_password)"
    elif [[ -s "${SECRET_FILE}" ]]; then
        password="$(cat "${SECRET_FILE}")"
    else
        fail "Runtime admin parola dosyasi bulunamadi: ${SECRET_FILE}"
    fi

    printf 'Kullanici    : admin\n'
    printf 'Parola       : %s\n' "${password}"
    printf 'Varyant      : %s\n' "${OFBIZ_VARIANT}"
    printf 'Parola dosya : %s\n' "${SECRET_FILE}"
}

case "${ACTION}" in
    install)
        install_ofbiz
        ;;
    start)
        start_ofbiz
        ;;
    stop)
        stop_ofbiz
        ;;
    status)
        status_ofbiz
        ;;
    doctor)
        doctor_ofbiz
        ;;
    open)
        open_browser
        ;;
    password)
        password_ofbiz
        ;;
    *)
        fail "Bilinmeyen action: ${ACTION}. Desteklenen: install, start, stop, status, doctor, open, password"
        ;;
esac
