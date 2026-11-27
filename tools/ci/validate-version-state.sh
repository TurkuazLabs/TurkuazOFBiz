# Dosya Yolu: REPO_ROOT/tools/ci/validate-version-state.sh
# Amac: VERSION degerini ve release etiketi butunlugunu dogrular
# Modul - Tool Shell
# Version: 1.0.0
# Aciklama: Kaynak CI ile release uygunlugunu ayirir; mevcut tag farkli commit'e tasinmaz
# Bagimli Oldugu Katman: Tool | Config

set -euo pipefail

readonly VERSION_STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION_STATE_ROOT="$(cd "${VERSION_STATE_DIR}/../.." && pwd)"

mode="${1:-release}"
if [[ "$#" -gt 1 || ( "$mode" != 'release' && "$mode" != '--source-ci' ) ]]; then
    printf '[version-state] ERROR: Invalid mode\n' >&2
    exit 1
fi

project_version="$(tr -d '[:space:]' < "${VERSION_STATE_ROOT}/VERSION")"
tag="v${project_version}"
head_sha="$(git -C "${VERSION_STATE_ROOT}" rev-parse HEAD)"

if ! [[ "${project_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '[version-state] ERROR: Invalid VERSION: %s\n' "${project_version}" >&2
    exit 1
fi

# for-each-ref fails on repository errors; an absent tag is an empty result.
tag_ref="$(git -C "${VERSION_STATE_ROOT}" for-each-ref --format='%(refname)' "refs/tags/${tag}")"
if [[ -n "$tag_ref" ]]; then
    if [[ "$tag_ref" != "refs/tags/${tag}" ]]; then
        printf '[version-state] ERROR: Unexpected tag reference\n' >&2
        exit 1
    fi
    tag_sha="$(git -C "${VERSION_STATE_ROOT}" rev-list -n 1 "refs/tags/${tag}")"
    if [[ "${tag_sha}" != "${head_sha}" ]]; then
        if [[ "$mode" == '--source-ci' ]]; then
            printf '[version-state] Source CI only: %s belongs to %s; release blocked for %s.\n' "$tag" "$tag_sha" "$head_sha"
            exit 0
        fi
        printf '[version-state] RELEASE BLOCKED: %s already points to %s, current commit is %s.\n' "$tag" "$tag_sha" "$head_sha" >&2
        exit 2
    fi
    printf '[version-state] Existing tag %s matches current commit.\n' "${tag}"
else
    printf '[version-state] %s is not released yet; version state permits release.\n' "${tag}"
fi
