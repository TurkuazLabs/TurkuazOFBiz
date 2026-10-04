# Dosya Yolu: /repositories/install-repository.sh
# Amac: OFBiz release ve snapshot kurulumlarinin dosya sistemi durumunu yonetir
# Repo - Shell
# Version: 1.2.0
# Aciklama: Kurulum dizinleri, metadata, staging, atomik replacement ve aktif symlink durumunu yonetir
#
# Bagimli Oldugu Katman: Repo | Config

if [[ "${OFBIZ_INSTALL_REPOSITORY_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
OFBIZ_INSTALL_REPOSITORY_LOADED="1"

set -euo pipefail

readonly INSTALL_REPOSITORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_REPOSITORY_ROOT="$(cd "${INSTALL_REPOSITORY_DIR}/.." && pwd)"
readonly INSTALL_RUNTIME_CONFIG="${INSTALL_REPOSITORY_ROOT}/config/runtime.conf"

# shellcheck source=/dev/null
source "${INSTALL_RUNTIME_CONFIG}"

ofbiz_repository_root() {
    printf '%s\n' "${OFBIZ_INSTALL_ROOT:-${OFBIZ_DEFAULT_INSTALL_ROOT}}"
}

ofbiz_repository_releases_dir() {
    printf '%s/%s\n' "$(ofbiz_repository_root)" "${OFBIZ_RELEASES_DIR_NAME}"
}

ofbiz_repository_snapshots_dir() {
    printf '%s/%s\n' "$(ofbiz_repository_root)" "${OFBIZ_SNAPSHOTS_DIR_NAME}"
}

ofbiz_repository_jdks_dir() {
    printf '%s/%s\n' "$(ofbiz_repository_root)" "${OFBIZ_JDKS_DIR_NAME}"
}

ofbiz_repository_current_link() {
    printf '%s/%s\n' "$(ofbiz_repository_root)" "${OFBIZ_CURRENT_LINK_NAME}"
}

ofbiz_repository_release_path() {
    local version="${1:?version required}"
    printf '%s/%s%s\n' "$(ofbiz_repository_releases_dir)" "${OFBIZ_RELEASE_DIR_PREFIX}" "${version}"
}

ofbiz_repository_snapshot_safe_name() {
    local branch="${1:?branch required}"
    printf '%s\n' "${branch//\//__}"
}

ofbiz_repository_snapshot_path() {
    local branch="${1:?branch required}"
    local safe_name

    safe_name="$(ofbiz_repository_snapshot_safe_name "${branch}")"
    printf '%s/%s%s\n' "$(ofbiz_repository_snapshots_dir)" "${OFBIZ_SNAPSHOT_DIR_PREFIX}" "${safe_name}"
}

ofbiz_repository_init() {
    mkdir -p         "$(ofbiz_repository_releases_dir)"         "$(ofbiz_repository_snapshots_dir)"         "$(ofbiz_repository_jdks_dir)"
}

ofbiz_repository_exists() {
    local path="${1:?path required}"
    [[ -d "${path}" ]]
}

ofbiz_repository_set_current() {
    local path="${1:?path required}"
    local current_link

    [[ -d "${path}" ]] || return 1

    current_link="$(ofbiz_repository_current_link)"

    if [[ -e "${current_link}" && ! -L "${current_link}" ]]; then
        printf '[install-repository] ERROR: Current path exists and is not a symlink: %s\n' "${current_link}" >&2
        return 1
    fi

    ln -sfn "${path}" "${current_link}"
}

ofbiz_repository_current_path() {
    local current_link

    current_link="$(ofbiz_repository_current_link)"

    [[ -L "${current_link}" ]] || return 1
    readlink -f "${current_link}"
}

ofbiz_repository_write_metadata() {
    local path="${1:?path required}"
    local type="${2:?type required}"
    local identifier="${3:?identifier required}"
    local java_major="${4:?java major required}"
    local metadata_file="${path}/${OFBIZ_METADATA_FILE_NAME}"

    cat > "${metadata_file}" <<EOF
type=${type}
identifier=${identifier}
java_major=${java_major}
EOF
}

ofbiz_repository_metadata_value() {
    local path="${1:?path required}"
    local key="${2:?key required}"
    local metadata_file="${path}/${OFBIZ_METADATA_FILE_NAME}"

    [[ -f "${metadata_file}" ]] || return 1
    sed -n "s/^${key}=//p" "${metadata_file}" | head -n 1
}

ofbiz_repository_install_is_valid() {
    local path="${1:?path required}"
    local type="${2:?type required}"
    local identifier="${3:?identifier required}"
    local java_major="${4:?java major required}"

    [[ -d "${path}" ]] || return 1
    [[ -x "${path}/gradlew" ]] || return 1
    [[ "$(ofbiz_repository_metadata_value "${path}" type 2>/dev/null || true)" == "${type}" ]] || return 1
    [[ "$(ofbiz_repository_metadata_value "${path}" identifier 2>/dev/null || true)" == "${identifier}" ]] || return 1
    [[ "$(ofbiz_repository_metadata_value "${path}" java_major 2>/dev/null || true)" == "${java_major}" ]] || return 1

    if [[ "${type}" == "${OFBIZ_TYPE_SNAPSHOT}" ]]; then
        [[ -d "${path}/.git" ]] || return 1
    fi
}

ofbiz_repository_create_staging_dir() {
    local parent_dir="${1:?parent dir required}"
    local label="${2:?label required}"

    mkdir -p "${parent_dir}"
    mktemp -d "${parent_dir}/.${label}.staging.XXXXXX"
}

ofbiz_repository_replace_directory() {
    local source_path="${1:?source path required}"
    local target_path="${2:?target path required}"
    local backup_path=""

    [[ -d "${source_path}" ]] || return 1

    if [[ -e "${target_path}" || -L "${target_path}" ]]; then
        backup_path="${target_path}.backup.$$"
        rm -rf -- "${backup_path}"
        mv -- "${target_path}" "${backup_path}"
    fi

    if mv -- "${source_path}" "${target_path}"; then
        [[ -z "${backup_path}" ]] || rm -rf -- "${backup_path}"
        return 0
    fi

    if [[ -n "${backup_path}" && -e "${backup_path}" ]]; then
        mv -- "${backup_path}" "${target_path}" || true
    fi

    return 1
}

ofbiz_repository_list_releases() {
    local releases_dir
    local item

    releases_dir="$(ofbiz_repository_releases_dir)"

    [[ -d "${releases_dir}" ]] || return 0

    for item in "${releases_dir}"/"${OFBIZ_RELEASE_DIR_PREFIX}"*; do
        [[ -d "${item}" ]] || continue
        basename "${item}" | sed "s/^${OFBIZ_RELEASE_DIR_PREFIX}//"
    done
}

ofbiz_repository_list_snapshots() {
    local snapshots_dir
    local item
    local identifier

    snapshots_dir="$(ofbiz_repository_snapshots_dir)"

    [[ -d "${snapshots_dir}" ]] || return 0

    for item in "${snapshots_dir}"/"${OFBIZ_SNAPSHOT_DIR_PREFIX}"*; do
        [[ -d "${item}" ]] || continue

        identifier="$(ofbiz_repository_metadata_value "${item}" identifier || true)"
        if [[ -n "${identifier}" ]]; then
            printf '%s\n' "${identifier}"
        else
            basename "${item}" | sed "s/^${OFBIZ_SNAPSHOT_DIR_PREFIX}//"
        fi
    done
}
