#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SOURCE="${ROOT_DIR}/dist/StayActive.app"
INSTALL_DIR="${HOME}/Applications"
APP_DESTINATION="${INSTALL_DIR}/StayActive.app"

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
/usr/bin/pkill -x StayActive 2>/dev/null || true
rm -rf "${APP_DESTINATION}"
cp -R "${APP_SOURCE}" "${APP_DESTINATION}"

open "${APP_DESTINATION}"

echo
echo "Installed: ${APP_DESTINATION}"
echo "StayActive should now appear on the macOS menu bar."
