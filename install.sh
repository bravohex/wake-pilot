#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="WakePilot"
APP_SOURCE="${ROOT_DIR}/dist/${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"
APP_DESTINATION="${INSTALL_DIR}/${APP_NAME}.app"
RENAMED_APP_PATH="${INSTALL_DIR}/BrHxWakePilot.app"

"${ROOT_DIR}/build-app.sh"

mkdir -p "${INSTALL_DIR}"
/usr/bin/pkill -x "${APP_NAME}" 2>/dev/null || true
rm -rf "${APP_DESTINATION}"

if [[ -d "${RENAMED_APP_PATH}" ]]; then
    /usr/bin/pkill -x BrHxWakePilot 2>/dev/null || true
    rm -rf "${RENAMED_APP_PATH}"
    echo "Replaced the previous Wake Pilot app bundle."
fi

cp -R "${APP_SOURCE}" "${APP_DESTINATION}"

open "${APP_DESTINATION}"

echo
echo "Installed: ${APP_DESTINATION}"
echo "Wake Pilot should now appear on the macOS menu bar."
