#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="WakePilot"
APP_PATH="${DIST_DIR}/${APP_NAME}.app"
SIGNING_IDENTITY="${WAKE_PILOT_SIGNING_IDENTITY:--}"
BUILD_ARCHITECTURES="${WAKE_PILOT_ARCHS:-}"

typeset -a BUILD_ARGS
BUILD_ARGS=(-c release)

if [[ -n "${BUILD_ARCHITECTURES}" ]]; then
    for architecture in ${(s:,:)BUILD_ARCHITECTURES}; do
        [[ -n "${architecture}" ]] || continue
        BUILD_ARGS+=(--arch "${architecture}")
    done
fi

echo "Building Wake Pilot..."
cd "${ROOT_DIR}"
/usr/bin/xcrun swift build "${BUILD_ARGS[@]}"

BIN_DIR="$(/usr/bin/xcrun swift build "${BUILD_ARGS[@]}" --show-bin-path)"
BIN_PATH="${BIN_DIR}/${APP_NAME}"

if [[ ! -x "${BIN_PATH}" ]]; then
    echo "Build output not found: ${BIN_PATH}" >&2
    exit 1
fi

rm -rf "${APP_PATH}"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

cp "${BIN_PATH}" "${APP_PATH}/Contents/MacOS/${APP_NAME}"
cp "${ROOT_DIR}/Resources/Info.plist" "${APP_PATH}/Contents/Info.plist"

chmod +x "${APP_PATH}/Contents/MacOS/${APP_NAME}"
/usr/bin/plutil -lint "${APP_PATH}/Contents/Info.plist"

SIGNING_ARGS=(
    --force
    --options runtime
    --sign "${SIGNING_IDENTITY}"
)

if [[ "${SIGNING_IDENTITY}" != "-" ]]; then
    SIGNING_ARGS+=(--timestamp)
fi

/usr/bin/codesign "${SIGNING_ARGS[@]}" "${APP_PATH}"
/usr/bin/codesign --verify --strict --verbose=2 "${APP_PATH}"

echo
echo "Created: ${APP_PATH}"

if [[ "${SIGNING_IDENTITY}" == "-" ]]; then
    echo "Security note: this local build is ad-hoc signed and will not pass Gatekeeper on another Mac."
fi
