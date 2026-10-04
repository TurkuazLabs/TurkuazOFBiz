# Dosya Yolu: /tools/ci/validate-version-state.sh
# Amac: VERSION degerinin mevcut Git tag durumu ile tutarli oldugunu dogrular
# Tool - Shell
# Version: 1.0.0
# Aciklama: Ayni surum tag'i farkli bir committe yayinlandiysa yeni main commitini engeller
#
# Bagimli Oldugu Katman: Tool | Config

set -euo pipefail

readonly VERSION_STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION_STATE_ROOT="$(cd "${VERSION_STATE_DIR}/../.." && pwd)"

project_version="$(tr -d '[:space:]' < "${VERSION_STATE_ROOT}/VERSION")"
tag="v${project_version}"
head_sha="$(git -C "${VERSION_STATE_ROOT}" rev-parse HEAD)"

if ! [[ "${project_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '[version-state] ERROR: Invalid VERSION: %s\n' "${project_version}" >&2
    exit 1
fi

if git -C "${VERSION_STATE_ROOT}" show-ref --tags --verify --quiet "refs/tags/${tag}"; then
    tag_sha="$(git -C "${VERSION_STATE_ROOT}" rev-list -n 1 "${tag}")"

    if [[ "${tag_sha}" != "${head_sha}" ]]; then
        printf '[version-state] ERROR: %s already points to %s, current commit is %s. Bump VERSION before merging.\n'             "${tag}"             "${tag_sha}"             "${head_sha}" >&2
        exit 1
    fi

    printf '[version-state] Existing tag %s matches current commit.\n' "${tag}"
else
    printf '[version-state] %s is not released yet; current commit is eligible for release.\n' "${tag}"
fi
