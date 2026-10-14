#!/usr/bin/env bash
# Build:    ./build.sh
# Sideload: ROKU_IP=192.168.1.20 ROKU_PASS=<developer password> ./build.sh install
# Remove:   ROKU_IP=... ROKU_PASS=... ./build.sh remove
set -euo pipefail
cd "$(dirname "$0")"

ZIP=out/hdhr-tv.zip

build() {
    mkdir -p out
    rm -f "$ZIP"
    zip -qr -9 "$ZIP" manifest source components images -x '*.DS_Store'
    echo "→ $ZIP"
}

require_target() {
    : "${ROKU_IP:?Set ROKU_IP to the Roku IP address}"
    : "${ROKU_PASS:?Set ROKU_PASS to the developer mode password}"
}

post() {
    curl -sS --fail --digest --user "rokudev:$ROKU_PASS" "$@" "http://$ROKU_IP/plugin_install"
}

case "${1:-build}" in
    build)
        build
        ;;
    install)
        require_target
        build
        post -F "mysubmit=Install" -F "archive=@$ZIP" \
            | grep -oE 'Install Success|Identical to previous version|Install Failure[^<]*' \
            || { echo "Install failed. Check ROKU_IP, ROKU_PASS and that developer mode is on." >&2; exit 1; }
        ;;
    remove)
        require_target
        post -F "mysubmit=Delete" -F "archive=" > /dev/null
        echo "Removed."
        ;;
    *)
        echo "Usage: $0 [build|install|remove]" >&2
        exit 1
        ;;
esac
