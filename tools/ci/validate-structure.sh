# Dosya Yolu: /tools/ci/validate-structure.sh
# Amac: TurkuazOFBiz konfigurasyon yapisinin syntax, katman, resolver ve release metadata testlerini calistirir
# Tool - Shell
# Version: 1.4.0
# Aciklama: CI icin ag gerektirmeyen syntax, katman, release/snapshot, Docker image ve proje surum testleri
#
# Bagimli Oldugu Katman: Tool | Controller | Service | Repo | View | Language | Config

set -euo pipefail

readonly CI_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OFBIZ_ROOT_DIR="$(cd "${CI_TOOL_DIR}/../.." && pwd)"

fail() {
    printf '[ofbiz-ci] ERROR: %s\n' "$*" >&2
    exit 1
}

assert_equals() {
    local expected="${1:?expected required}"
    local actual="${2:?actual required}"
    local message="${3:?message required}"

    [[ "${expected}" == "${actual}" ]] || fail "${message}: expected=${expected}, actual=${actual}"
}

validate_directories() {
    local required_dirs=(
        "config"
        "controllers"
        "services"
        "repositories"
        "tools"
        "views"
        "language"
    )
    local item

    for item in "${required_dirs[@]}"; do
        [[ -d "${OFBIZ_ROOT_DIR}/${item}" ]] || fail "Missing directory: ${item}"
    done
}

validate_release_metadata() {
    local required_files=(
        "LICENSE"
        "VERSION"
        "CHANGELOG.md"
        "RELEASE_NOTES.md"
    )
    local item
    local project_version

    for item in "${required_files[@]}"; do
        [[ -f "${OFBIZ_ROOT_DIR}/${item}" ]] || fail "Missing release file: ${item}"
    done

    project_version="$(tr -d '[:space:]' < "${OFBIZ_ROOT_DIR}/VERSION")"

    [[ "${project_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]         || fail "Invalid VERSION format: ${project_version}"

    grep -Fq "## [${project_version}] - 2026-10-04" "${OFBIZ_ROOT_DIR}/CHANGELOG.md"         || fail "CHANGELOG.md does not contain VERSION ${project_version}"

    grep -Fq "# TurkuazOFBiz v${project_version}" "${OFBIZ_ROOT_DIR}/RELEASE_NOTES.md"         || fail "RELEASE_NOTES.md does not contain VERSION ${project_version}"

    grep -Fq "Apache License" "${OFBIZ_ROOT_DIR}/LICENSE"         || fail "LICENSE is not Apache License 2.0 text"
}

validate_bash_syntax() {
    local file

    while IFS= read -r file; do
        bash -n "${file}" || fail "Bash syntax failed: ${file}"
    done < <(find "${OFBIZ_ROOT_DIR}" -type f -name '*.sh' -not -path '*/legacy/*' | sort)
}

validate_headers() {
    local file
    local first_line
    local second_line

    while IFS= read -r file; do
        first_line="$(sed -n '1p' "${file}")"
        second_line="$(sed -n '2p' "${file}")"

        [[ "${first_line}" == "# Dosya Yolu:"* ]] || fail "Missing path header: ${file}"
        [[ "${second_line}" == "# Amac:"* ]] || fail "Missing purpose header: ${file}"
    done < <(
        find "${OFBIZ_ROOT_DIR}" -type f             \( -name '*.sh' -o -name '*.conf' -o -name '*.yml' -o -name 'Dockerfile.compat' \)             -not -path '*/legacy/*'             | sort
    )
}

validate_release_checksum_parser() {
    local work_dir
    local apache_checksum_file
    local gnu_checksum_file
    local expected

    # shellcheck source=/dev/null
    source "${OFBIZ_ROOT_DIR}/tools/release-tool.sh"

    work_dir="$(mktemp -d)"
    apache_checksum_file="${work_dir}/apache.sha512"
    gnu_checksum_file="${work_dir}/gnu.sha512"
    expected="6602fa1f9752629486e2e0490ef95728f75e998496ec014d3eaa87e779ee7fd71efdef1a5d76856fe7a8c238c094d5dd64580963a4a560e5b01415cdaf9e28c2"

    cat > "${apache_checksum_file}" <<'EOF'
apache-ofbiz-24.09.07.zip: 6602FA1F 97526294 86E2E049 0EF95728 F75E9984
                           96EC014D 3EAA87E7 79EE7FD7 1EFDEF1A 5D76856F
                           E7A8C238 C094D5DD 64580963 A4A560E5 B01415CD
                           AF9E28C2
EOF

    printf '%s  apache-ofbiz-24.09.07.zip\n' "${expected}" > "${gnu_checksum_file}"

    assert_equals "${expected}" "$(ofbiz_tool_read_sha512 "${apache_checksum_file}")" "Apache SHA-512 parser"
    assert_equals "${expected}" "$(ofbiz_tool_read_sha512 "${gnu_checksum_file}")" "GNU SHA-512 parser"

    rm -rf "${work_dir}"
}

validate_resolvers() {
    # shellcheck source=/dev/null
    source "${OFBIZ_ROOT_DIR}/services/version-resolver.sh"
    # shellcheck source=/dev/null
    source "${OFBIZ_ROOT_DIR}/services/snapshot-resolver.sh"
    # shellcheck source=/dev/null
    source "${OFBIZ_ROOT_DIR}/repositories/docker-repository.sh"

    assert_equals "24.09.07" "$(ofbiz_resolve_version latest)" "latest release"
    assert_equals "18.12.19" "$(ofbiz_resolve_version 18.12)" "18.12 release alias"
    assert_equals "17" "$(ofbiz_required_java 24.09.07)" "24.09 Java"

    assert_equals "trunk" "$(ofbiz_snapshot_resolve_branch trunk)" "trunk snapshot"
    assert_equals "release24.09" "$(ofbiz_snapshot_resolve_branch 24.09)" "24.09 snapshot"
    assert_equals "release22.01" "$(ofbiz_snapshot_resolve_branch 22.01)" "22.01 snapshot"
    assert_equals "17" "$(ofbiz_snapshot_required_java release22.01)" "22.01 Java"

    assert_equals         "ghcr.io/apache/ofbiz:24.09.07"         "$(ofbiz_docker_repository_release_official_image 24.09.07 runtime)"         "release runtime image"

    assert_equals         "ghcr.io/apache/ofbiz:24.09.07-preloaddemo"         "$(ofbiz_docker_repository_release_official_image 24.09.07 demo)"         "release demo image"

    assert_equals         "ghcr.io/apache/ofbiz:trunk-snapshot"         "$(ofbiz_docker_repository_snapshot_official_image trunk runtime)"         "trunk snapshot image"

    assert_equals         "ghcr.io/apache/ofbiz:release24.09-preloaddemo-snapshot"         "$(ofbiz_docker_repository_snapshot_official_image release24.09 demo)"         "24.09 snapshot demo image"

    if ofbiz_docker_repository_snapshot_official_image release22.01 runtime >/dev/null 2>&1; then
        fail "22.01 must use local Docker build"
    fi
}

validate_controller_readonly_commands() {
    bash "${OFBIZ_ROOT_DIR}/controllers/ofbiz.sh" release list >/dev/null
    bash "${OFBIZ_ROOT_DIR}/controllers/ofbiz.sh" snapshot list >/dev/null
    bash "${OFBIZ_ROOT_DIR}/controllers/ofbiz.sh" help >/dev/null
}

main() {
    validate_directories
    validate_release_metadata
    validate_release_checksum_parser
    validate_bash_syntax
    validate_headers
    validate_resolvers
    validate_controller_readonly_commands

    printf '[ofbiz-ci] Validation successful.\n'
}

main "$@"
