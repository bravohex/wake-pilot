#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="WakePilot"
APP_SOURCE="${ROOT_DIR}/dist/${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"
APP_DESTINATION="${INSTALL_DIR}/${APP_NAME}.app"
RENAMED_APP_PATH="${INSTALL_DIR}/BrHxWakePilot.app"
LEGACY_APP_PATH="${INSTALL_DIR}/StayActive.app"

# Remove the earlier shell/LaunchAgent version when present.
OLD_PLIST="${HOME}/Library/LaunchAgents/com.bravohex.stayactive.plist"
if [[ -f "${OLD_PLIST}" ]]; then
    /bin/launchctl bootout "gui/$(id -u)" "${OLD_PLIST}" 2>/dev/null || true
    rm -f "${OLD_PLIST}"
    rm -rf "${HOME}/Library/Application Support/StayActive"
    echo "Removed the legacy StayActive LaunchAgent."
fi

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

if [[ -d "${LEGACY_APP_PATH}" ]]; then
    /usr/bin/pkill -x StayActive 2>/dev/null || true
    echo "Legacy StayActive.app was preserved. Disable its Launch at Login setting before removing it."
fi

open "${APP_DESTINATION}"

echo
echo "Installed: ${APP_DESTINATION}"
echo "Wake Pilot should now appear on the macOS menu bar."
