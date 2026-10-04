# Dosya Yolu: /tools/git-tool.sh
# Amac: Apache OFBiz branch kaynak kodunu clone veya update eder
# Tool - Shell
# Version: 1.0.0
# Aciklama: Snapshot kurulumlari icin Git clone, fetch ve hard reset adaptorudur
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

ofbiz_tool_git_clone_branch() {
    local repository_url="${1:?repository url required}"
    local branch="${2:?branch required}"
    local destination="${3:?destination required}"

    git clone         --depth 1         --single-branch         --branch "${branch}"         "${repository_url}"         "${destination}"
}

ofbiz_tool_git_update_branch() {
    local branch="${1:?branch required}"
    local destination="${2:?destination required}"

    git -C "${destination}" fetch --depth 1 origin "${branch}"
    git -C "${destination}" checkout -B "${branch}" "origin/${branch}"
    git -C "${destination}" reset --hard "origin/${branch}"
}

ofbiz_tool_git_revision() {
    local destination="${1:?destination required}"
    git -C "${destination}" rev-parse HEAD
}
