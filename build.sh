#!/usr/bin/env bash
# Build:    ./build.sh
# Sideload: ROKU_IP=192.168.1.20 ROKU_PASS=<developer password> ./build.sh install
# Remove:   ROKU_IP=... ROKU_PASS=... ./build.sh remove
# Package:  ROKU_IP=... ROKU_PASS=... ROKU_SIGN_PASS=<genkey password> ./build.sh package
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

install() {
    build
    post -F "mysubmit=Install" -F "archive=@$ZIP" \
        | grep -oE 'Install Success|Identical to previous version|Install Failure[^<]*' \
        || { echo "Install failed. Check ROKU_IP, ROKU_PASS and that developer mode is on." >&2; exit 1; }
}

manifest_value() {
    sed -n "s/^$1=//p" manifest
}

# Signs the sideloaded channel with the Roku's developer key (from genkey) and downloads the .pkg.
package() {
    : "${ROKU_SIGN_PASS:?Set ROKU_SIGN_PASS to the password genkey printed}"
    install
    version="$(manifest_value major_version).$(manifest_value minor_version).$(manifest_value build_version)"
    pkg_path=$(curl -sS --fail --digest --user "rokudev:$ROKU_PASS" \
        -F "mysubmit=Package" -F "app_name=$(manifest_value title)/$version" \
        -F "passwd=$ROKU_SIGN_PASS" -F "pkg_time=$(date +%s)000" \
        "http://$ROKU_IP/plugin_package" | grep -oE 'pkgs/+[^"<>]*\.pkg' | head -n 1) \
        || { echo "Packaging failed. Check ROKU_SIGN_PASS and that genkey was run on this Roku." >&2; exit 1; }
    out="out/hdhr-tv-$version.pkg"
    curl -sS --fail --digest --user "rokudev:$ROKU_PASS" -o "$out" "http://$ROKU_IP/$pkg_path"
    echo "→ $out"
}

case "${1:-build}" in
    build)
        build
        ;;
    install)
        require_target
        install
        ;;
    package)
        require_target
        package
        ;;
    remove)
        require_target
        post -F "mysubmit=Delete" -F "archive=" > /dev/null
        echo "Removed."
        ;;
    *)
        echo "Usage: $0 [build|install|package|remove]" >&2
        exit 1
        ;;
esac
