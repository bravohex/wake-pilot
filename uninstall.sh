#!/bin/zsh
set -euo pipefail

APP_NAME="BrHxWakePilot"
APP_PATH="${HOME}/Applications/${APP_NAME}.app"

echo "Before uninstalling, turn off 'Mở Wake Pilot khi đăng nhập' in Settings."
/usr/bin/pkill -x "${APP_NAME}" 2>/dev/null || true
rm -rf "${APP_PATH}"

echo "Removed: ${APP_PATH}"
