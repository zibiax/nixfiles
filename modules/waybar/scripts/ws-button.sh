#!/usr/bin/env bash
# One waybar button per workspace: ws-button.sh <id>
# Stand-in for the built-in hyprland/workspaces module, whose click sends the
# pre-Lua "dispatch workspace N" that Hyprland rejects when using hyprland.lua.
# Prints a JSON line on every relevant Hyprland event; empty text hides it.

id=$1
sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

print_state() {
    local active
    active=$(hyprctl -j activeworkspace | jq '.id')
    if [ "$active" = "$id" ]; then
        printf '{"text": "%s", "class": "active"}\n' "$id"
    elif hyprctl -j workspaces | jq -e --argjson id "$id" 'any(.[]; .id == $id)' >/dev/null; then
        printf '{"text": "%s", "class": "occupied"}\n' "$id"
    else
        echo '{"text": ""}'
    fi
}

print_state
socat -u UNIX-CONNECT:"$sock" - | while read -r event; do
    case $event in
        workspace*|createworkspace*|destroyworkspace*|focusedmon*|moveworkspace*) print_state ;;
    esac
done
