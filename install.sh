# Dosya Yolu: /install.sh
# Amac: Linux ve WSL kullanicisi icin Native veya Docker TurkuazOFBiz kurulumunu tek arabirimden yonetir
# Controller - Shell
# Version: 2.0.1
# Aciklama: Ortak mode/target/version/variant modeliyle native Linux ve Docker kurulum, start, stop, status, doctor ve open aksiyonlarini yonlendirir
#
# Bagimli Oldugu Katman: Controller | Service | Repo | Tool | View | Config

set -euo pipefail

readonly PROJECT_REPOSITORY="TurkuazLabs/TurkuazOFBiz"
readonly PROJECT_URL="https://github.com/${PROJECT_REPOSITORY}"
readonly APP_HOME="${TURKUAZOFBIZ_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/turkuazofbiz}"
readonly MANAGED_REPO="${APP_HOME}/repo"
readonly STATE_FILE="${APP_HOME}/installer-state.conf"
readonly SECRET_FILE="${APP_HOME}/admin-password.txt"

ACTION="${1:-install}"
INSTALL_MODE="${OFBIZ_INSTALL_MODE:-}"
TARGET_TYPE="${OFBIZ_TARGET_TYPE:-}"
OFBIZ_VERSION="${OFBIZ_VERSION:-}"
OFBIZ_VARIANT="${OFBIZ_VARIANT:-}"
OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT:-}"
OFBIZ_APP_PATH="${OFBIZ_APP_PATH:-/partymgr}"
NATIVE_INSTALL_ROOT="${OFBIZ_NATIVE_INSTALL_ROOT:-/opt/ofbiz}"

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

can_interact() {
    [[ -r /dev/tty && -w /dev/tty ]]
}

read_choice() {
    local prompt="${1:?prompt required}"
    local minimum="${2:?minimum required}"
    local maximum="${3:?maximum required}"
    local default_value="${4:-1}"
    local value=""

    while true; do
        printf '%s [%s]: ' "${prompt}" "${default_value}" >&2
        if can_interact; then
            IFS= read -r value < /dev/tty || value=""
        else
            value=""
        fi

        [[ -n "${value}" ]] || value="${default_value}"

        if [[ "${value}" =~ ^[0-9]+$ ]] && (( value >= minimum && value <= maximum )); then
            printf '%s\n' "${value}"
            return
        fi

        printf 'Gecersiz secim. %s-%s arasinda bir deger girin.\n' "${minimum}" "${maximum}" >&2
    done
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

    latest_url="$(curl         --fail         --silent         --show-error         --location         --output /dev/null         --write-out '%{url_effective}'         "${PROJECT_URL}/releases/latest")"

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

    curl         --fail         --silent         --show-error         --location         "${PROJECT_URL}/archive/refs/tags/${tag}.tar.gz"         --output "${archive}"

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

config_multiline_values() {
    local config_file="${1:?config file required}"
    local variable_name="${2:?variable required}"

    awk -v name="${variable_name}" '
        $0 ~ "^" name "=\"" {
            active=1
            sub("^[^\"]*\"", "")
            if ($0 ~ /\"$/) {
                sub(/\"$/, "")
                if (length($0)) print
                exit
            }
            if (length($0)) print
            next
        }
        active {
            if ($0 ~ /\"$/) {
                sub(/\"$/, "")
                if (length($0)) print
                exit
            }
            if (length($0)) print
        }
    ' "${config_file}"
}

select_install_mode() {
    local choice

    can_interact || {
        INSTALL_MODE="${INSTALL_MODE:-native}"
        return
    }

    printf '\n============================================================\n'
    printf ' TurkuazOFBiz - Kurulum Modu\n'
    printf '============================================================\n'
    printf ' 1 - Native  (Docker gerekmez, onerilen)\n'
    printf ' 2 - Docker  (container tabanli alternatif)\n'

    choice="$(read_choice "Kurulum modu" 1 2 1)"
    INSTALL_MODE="$([[ "${choice}" == "1" ]] && printf native || printf docker)"
}

select_value_menu() {
    local title="${1:?title required}"
    shift
    local values=("$@")
    local index
    local choice

    [[ "${#values[@]}" -gt 0 ]] || fail "Secim listesi bos: ${title}"

    printf '\n%s\n' "${title}" >&2
    for ((index=0; index<${#values[@]}; index++)); do
        if (( index == 0 )); then
            printf ' %2d - %s  [onerilen/en yeni]\n' "$((index + 1))" "${values[index]}" >&2
        else
            printf ' %2d - %s\n' "$((index + 1))" "${values[index]}" >&2
        fi
    done

    choice="$(read_choice "Secim" 1 "${#values[@]}" 1)"
    printf '%s\n' "${values[choice - 1]}"
}

select_target() {
    local repo_root="${1:?repo root required}"
    local versions_config="${repo_root}/config/versions.conf"
    local snapshots_config="${repo_root}/config/snapshots.conf"
    local family
    local values=()

    can_interact || {
        TARGET_TYPE="${TARGET_TYPE:-release}"
        OFBIZ_VERSION="${OFBIZ_VERSION:-24.09.07}"
        OFBIZ_VARIANT="${OFBIZ_VARIANT:-demo}"
        return
    }

    printf '\n============================================================\n'
    printf ' TurkuazOFBiz - OFBiz Hedef Secimi\n'
    printf '============================================================\n'
    printf ' 1 - Release 24.09\n'
    printf ' 2 - Release 18.12\n'
    printf ' 3 - Release 17.12\n'

    if [[ "${INSTALL_MODE}" == "docker" || "${INSTALL_MODE}" == "native" ]]; then
        printf ' 4 - Snapshot / branch\n'
    fi

    family="$(read_choice "Kurulacak seri" 1 4 1)"

    case "${family}" in
        1)
            TARGET_TYPE="release"
            mapfile -t values < <(config_multiline_values "${versions_config}" "OFBIZ_RELEASES_24_09" | sort -Vr)
            OFBIZ_VERSION="$(select_value_menu "24.09 surumu" "${values[@]}")"
            ;;
        2)
            TARGET_TYPE="release"
            mapfile -t values < <(config_multiline_values "${versions_config}" "OFBIZ_RELEASES_18_12" | sort -Vr)
            OFBIZ_VERSION="$(select_value_menu "18.12 surumu" "${values[@]}")"
            ;;
        3)
            TARGET_TYPE="release"
            mapfile -t values < <(config_multiline_values "${versions_config}" "OFBIZ_RELEASES_17_12" | sort -Vr)
            OFBIZ_VERSION="$(select_value_menu "17.12 surumu" "${values[@]}")"
            ;;
        4)
            TARGET_TYPE="snapshot"
            mapfile -t values < <(config_multiline_values "${snapshots_config}" "OFBIZ_SNAPSHOT_BRANCHES")
            OFBIZ_VERSION="$(select_value_menu "Snapshot branch" "${values[@]}")"
            ;;
    esac

    printf '\nCalisma verisi:\n'
    printf ' 1 - Demo    (hazir ornek veri; kullaniciya hazir)\n'
    printf ' 2 - Runtime (seed/production bootstrap)\n'

    family="$(read_choice "Varyant" 1 2 1)"
    OFBIZ_VARIANT="$([[ "${family}" == "1" ]] && printf demo || printf runtime)"

    printf '\nSecilen: %s / %s / %s / %s\n'         "${INSTALL_MODE}" "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
}

save_state() {
    mkdir -p "${APP_HOME}"

    cat > "${STATE_FILE}" <<EOF
mode=${INSTALL_MODE}
target_type=${TARGET_TYPE}
target=${OFBIZ_VERSION}
variant=${OFBIZ_VARIANT}
https_port=${OFBIZ_HTTPS_PORT}
native_install_root=${NATIVE_INSTALL_ROOT}
EOF

    chmod 600 "${STATE_FILE}"
}

state_value() {
    local key="${1:?key required}"
    sed -n "s/^${key}=//p" "${STATE_FILE}" | head -n 1
}

restore_state() {
    [[ -f "${STATE_FILE}" ]] || fail "Kayitli kurulum bulunamadi. Once install action calistirin."

    INSTALL_MODE="${INSTALL_MODE:-$(state_value mode)}"
    TARGET_TYPE="${TARGET_TYPE:-$(state_value target_type)}"
    OFBIZ_VERSION="${OFBIZ_VERSION:-$(state_value target)}"
    OFBIZ_VARIANT="${OFBIZ_VARIANT:-$(state_value variant)}"
    OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT:-$(state_value https_port)}"
    NATIVE_INSTALL_ROOT="${NATIVE_INSTALL_ROOT:-$(state_value native_install_root)}"
}

ensure_defaults() {
    INSTALL_MODE="${INSTALL_MODE:-native}"
    TARGET_TYPE="${TARGET_TYPE:-release}"
    OFBIZ_VERSION="${OFBIZ_VERSION:-24.09.07}"
    OFBIZ_VARIANT="${OFBIZ_VARIANT:-demo}"
    OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT:-8443}"
}

ensure_docker() {
    require_command docker
    docker info >/dev/null 2>&1 || fail "Docker daemon erisilebilir degil."
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
    local safe_target
    safe_target="${OFBIZ_VERSION//./-}"
    safe_target="${safe_target//\//-}"
    printf 'ofbiz-%s-%s\n' "${TARGET_TYPE}" "${safe_target}"
}

ofbiz_url() {
    printf 'https://localhost:%s%s\n' "${OFBIZ_HTTPS_PORT}" "${OFBIZ_APP_PATH}"
}

wait_ofbiz_ready() {
    local url
    local http_code
    local attempt

    require_command curl
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

run_native_controller() {
    local repo_root="${1:?repo root required}"
    shift

    require_command sudo

    sudo env         OFBIZ_INSTALL_ROOT="${NATIVE_INSTALL_ROOT}"         OFBIZ_LOAD_DEMO="$([[ "${OFBIZ_VARIANT}" == "demo" ]] && printf 1 || printf 0)"         bash "${repo_root}/controllers/ofbiz.sh" "$@"
}

install_native() {
    local repo_root="${1:?repo root required}"
    local target_ref

    log "Native Linux kurulumu: ${TARGET_TYPE} / ${OFBIZ_VERSION} / ${OFBIZ_VARIANT}"

    if [[ "${TARGET_TYPE}" == "release" ]]; then
        run_native_controller "${repo_root}" release install "${OFBIZ_VERSION}"
        target_ref="release:${OFBIZ_VERSION}"
    else
        run_native_controller "${repo_root}" snapshot install "${OFBIZ_VERSION}"
        target_ref="snapshot:${OFBIZ_VERSION}"
    fi

    save_state

    log "Native OFBiz arka planda baslatiliyor"
    sudo env OFBIZ_INSTALL_ROOT="${NATIVE_INSTALL_ROOT}"         bash "${repo_root}/controllers/ofbiz.sh" run background "${target_ref}"

    wait_ofbiz_ready

    printf '\n============================================================\n'
    printf ' TurkuazOFBiz Native hazir\n'
    printf '============================================================\n'
    printf ' Hedef       : %s / %s / %s\n' "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
    printf ' Adres       : %s\n' "$(ofbiz_url)"

    if [[ "${OFBIZ_VARIANT}" == "demo" ]]; then
        printf ' Kullanici   : admin\n'
        printf ' Parola      : ofbiz\n'
    else
        printf ' Runtime     : seed/production bootstrap; demo admin hesabi uretilmez.\n'
    fi

    open_browser
}

prepare_docker_image() {
    local repo_root="${1:?repo root required}"

    if (
        cd "${repo_root}"
        bash controllers/ofbiz.sh docker pull "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
    ); then
        return
    fi

    log "Resmi image bulunamadi; local Docker image build ediliyor"
    (
        cd "${repo_root}"
        bash controllers/ofbiz.sh docker build "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
    )
}

install_docker() {
    local repo_root="${1:?repo root required}"
    local password

    ensure_docker
    password="$(admin_password)"

    log "Docker ortam kontrolu"
    (
        cd "${repo_root}"
        bash controllers/ofbiz.sh doctor docker
    )

    prepare_docker_image "${repo_root}"

    log "Apache OFBiz Docker container baslatiliyor"
    (
        cd "${repo_root}"
        OFBIZ_ADMIN_PASSWORD="${password}"         OFBIZ_HTTPS_PORT="${OFBIZ_HTTPS_PORT}"             bash controllers/ofbiz.sh docker run                 "${TARGET_TYPE}"                 "${OFBIZ_VERSION}"                 "${OFBIZ_VARIANT}"
    )

    wait_ofbiz_ready
    save_state

    printf '\n============================================================\n'
    printf ' TurkuazOFBiz Docker hazir\n'
    printf '============================================================\n'
    printf ' Hedef       : %s / %s / %s\n' "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"
    printf ' Adres       : %s\n' "$(ofbiz_url)"
    printf ' Kullanici   : admin\n'
    printf ' Parola      : %s\n' "${password}"
    printf ' Parola dosya: %s\n' "${SECRET_FILE}"

    open_browser
}

install_ofbiz() {
    local repo_root

    repo_root="$(resolve_repo_root)"
    select_install_mode
    select_target "${repo_root}"
    ensure_defaults

    case "${INSTALL_MODE}" in
        native)
            install_native "${repo_root}"
            ;;
        docker)
            install_docker "${repo_root}"
            ;;
        *)
            fail "Desteklenmeyen kurulum modu: ${INSTALL_MODE}"
            ;;
    esac
}

start_native() {
    local repo_root="${1:?repo root required}"
    local target_ref="${TARGET_TYPE}:${OFBIZ_VERSION}"

    sudo env OFBIZ_INSTALL_ROOT="${NATIVE_INSTALL_ROOT}"         bash "${repo_root}/controllers/ofbiz.sh" run background "${target_ref}"

    wait_ofbiz_ready
    open_browser
}

start_docker() {
    local container

    ensure_docker
    container="$(container_name)"

    if docker inspect "${container}" >/dev/null 2>&1; then
        docker start "${container}" >/dev/null
        wait_ofbiz_ready
        open_browser
    else
        install_docker "$(resolve_repo_root)"
    fi
}

start_ofbiz() {
    restore_state

    case "${INSTALL_MODE}" in
        native) start_native "$(resolve_repo_root)" ;;
        docker) start_docker ;;
        *) fail "Kayitli kurulum modu gecersiz: ${INSTALL_MODE}" ;;
    esac
}

stop_ofbiz() {
    local repo_root
    local container
    local target_ref

    restore_state

    if [[ "${INSTALL_MODE}" == "native" ]]; then
        repo_root="$(resolve_repo_root)"
        target_ref="${TARGET_TYPE}:${OFBIZ_VERSION}"
        sudo env OFBIZ_INSTALL_ROOT="${NATIVE_INSTALL_ROOT}"             bash "${repo_root}/controllers/ofbiz.sh" run stop "${target_ref}"
        return
    fi

    ensure_docker
    container="$(container_name)"
    docker stop "${container}" >/dev/null 2>&1 || true
    printf 'TurkuazOFBiz container durduruldu: %s\n' "${container}"
}

status_ofbiz() {
    local repo_root
    local container
    local target_ref

    restore_state
    printf 'Kurulum modu : %s\n' "${INSTALL_MODE}"
    printf 'Hedef         : %s / %s / %s\n' "${TARGET_TYPE}" "${OFBIZ_VERSION}" "${OFBIZ_VARIANT}"

    if [[ "${INSTALL_MODE}" == "native" ]]; then
        repo_root="$(resolve_repo_root)"
        target_ref="${TARGET_TYPE}:${OFBIZ_VERSION}"
        sudo env OFBIZ_INSTALL_ROOT="${NATIVE_INSTALL_ROOT}"             bash "${repo_root}/controllers/ofbiz.sh" run status "${target_ref}"
        return
    fi

    ensure_docker
    container="$(container_name)"
    docker ps -a         --filter "name=^/${container}$"         --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
}

doctor_ofbiz() {
    local repo_root

    repo_root="$(resolve_repo_root)"

    if [[ -f "${STATE_FILE}" ]]; then
        restore_state
    else
        ensure_defaults
    fi

    if [[ "${INSTALL_MODE}" == "docker" ]]; then
        ensure_docker
        (
            cd "${repo_root}"
            bash controllers/ofbiz.sh doctor docker
        )
    else
        (
            cd "${repo_root}"
            bash controllers/ofbiz.sh doctor local
        )
    fi
}

password_ofbiz() {
    restore_state

    if [[ "${INSTALL_MODE}" == "native" ]]; then
        if [[ "${OFBIZ_VARIANT}" == "demo" ]]; then
            printf 'Kullanici    : admin\n'
            printf 'Parola       : ofbiz\n'
        else
            printf 'Native runtime seed/production bootstrap demo admin hesabi uretmez.\n'
        fi
        return
    fi

    [[ -s "${SECRET_FILE}" ]] || fail "Admin parola dosyasi bulunamadi: ${SECRET_FILE}"

    printf 'Kullanici    : admin\n'
    printf 'Parola       : %s\n' "$(cat "${SECRET_FILE}")"
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
        if [[ -f "${STATE_FILE}" ]]; then
            restore_state
        else
            ensure_defaults
        fi
        open_browser
        ;;
    password)
        password_ofbiz
        ;;
    *)
        fail "Bilinmeyen action: ${ACTION}. Desteklenen: install, start, stop, status, doctor, open, password"
        ;;
esac
