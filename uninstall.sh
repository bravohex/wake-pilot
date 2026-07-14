#!/bin/zsh
set -euo pipefail

APP_PATH="${HOME}/Applications/StayActive.app"

echo "Before uninstalling, turn off 'Mở StayActive khi đăng nhập' in Settings."
/usr/bin/pkill -x StayActive 2>/dev/null || true
rm -rf "${APP_PATH}"

echo "Removed: ${APP_PATH}"
