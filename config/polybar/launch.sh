#!/usr/bin/env bash
set -u

dir="$HOME/.config/polybar"

stop_bars() {
    killall -q polybar 2>/dev/null || true
    while pgrep -u "$UID" -x polybar >/dev/null 2>&1; do
        sleep 1
    done
}

launch_bar() {
    local bar="$1"
    local config="$2"

    [ -f "$config" ] || {
        printf 'Config Polybar tidak ditemukan: %s\n' "$config" >&2
        return 1
    }

    stop_bars
    polybar -q "$bar" -c "$config" &
}

case "${1:-}" in
    --hutao)
        launch_bar hutao-main "$dir/config.ini"
        ;;
    --gruvbox)
        launch_bar gruvbox-main "$dir/gruvbox/config.ini"
        ;;
    *)
        printf 'Usage: %s --hutao|--gruvbox\n' "$0"
        exit 1
        ;;
esac
