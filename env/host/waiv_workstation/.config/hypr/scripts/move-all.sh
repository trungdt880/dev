#!/usr/bin/env bash
#
# Move EVERY window on the focused workspace to workspace $1.
# Mirrors aerospace's [mode.move-all.binding] (alt-m then a number).
set -euo pipefail

target="${1:?usage: move-all.sh <workspace>}"

# Collect first, then move: moving mutates the list we would be iterating.
mapfile -t addrs < <(
    hyprctl -j clients |
        jq -r --arg ws "$(hyprctl -j activeworkspace | jq -r '.id')" \
            '.[] | select(.workspace.id == ($ws | tonumber)) | .address'
)

for a in "${addrs[@]}"; do
    hyprctl dispatch movetoworkspacesilent "$target,address:$a" >/dev/null
done

hyprctl dispatch workspace "$target" >/dev/null
