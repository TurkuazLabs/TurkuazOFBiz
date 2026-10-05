# Dosya Yolu: /tools/ofbiz-run.sh
# Amac: Verilen OFBiz kurulum dizinini verilen JDK ile calistirir
# Tool - Shell
# Version: 2.1.0
# Aciklama: Runtime Service tarafindan cagrilan baslatma, arka plan, durum, durdurma ve Java adaptorudur
#
# Bagimli Oldugu Katman: Tool

set -euo pipefail

readonly RUNTIME_PATH="${1:?runtime path required}"
readonly JAVA_HOME_PATH="${2:?java home required}"
readonly RUNTIME_ACTION="${3:?action required}"

[[ -d "${RUNTIME_PATH}" ]] || {
    printf '[ofbiz-run] ERROR: Runtime path not found: %s\n' "${RUNTIME_PATH}" >&2
    exit 1
}

[[ -x "${JAVA_HOME_PATH}/bin/java" ]] || {
    printf '[ofbiz-run] ERROR: Java not found: %s\n' "${JAVA_HOME_PATH}" >&2
    exit 1
}

export JAVA_HOME="${JAVA_HOME_PATH}"
export PATH="${JAVA_HOME}/bin:${PATH}"

cd "${RUNTIME_PATH}"

case "${RUNTIME_ACTION}" in
    start)
        ./gradlew ofbiz
        ;;
    background)
        ./gradlew "ofbizBackground --start"
        ;;
    status)
        ./gradlew "ofbiz --status"
        ;;
    stop)
        ./gradlew "ofbiz --shutdown"
        ;;
    java)
        "${JAVA_HOME}/bin/java" -version
        ;;
    *)
        printf '[ofbiz-run] ERROR: Unknown action: %s\n' "${RUNTIME_ACTION}" >&2
        exit 1
        ;;
esac
