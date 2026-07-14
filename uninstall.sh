#!/bin/zsh
set -euo pipefail

APP_NAME="WakePilot"
APP_PATH="${HOME}/Applications/${APP_NAME}.app"
RENAMED_APP_PATH="${HOME}/Applications/BrHxWakePilot.app"

echo "Before uninstalling, turn off 'Mở Wake Pilot khi đăng nhập' in Settings."
/usr/bin/pkill -x "${APP_NAME}" 2>/dev/null || true
rm -rf "${APP_PATH}"

if [[ -d "${RENAMED_APP_PATH}" ]]; then
    /usr/bin/pkill -x BrHxWakePilot 2>/dev/null || true
    rm -rf "${RENAMED_APP_PATH}"
fi

echo "Removed: ${APP_PATH}"
