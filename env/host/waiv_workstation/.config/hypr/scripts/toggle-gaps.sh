#!/usr/bin/env bash
#
# Toggle gaps + borders + rounding off/on, for when you want the screen
# edge-to-edge. Mirrors aerospace's alt-g / toggle-gaps.sh.
#
# aerospace had to rewrite its TOML because it has no IPC for this; Hyprland
# does, so this just flips runtime keywords and leaves hyprland.conf alone.
# `hyprctl reload` restores whatever the config file says.
set -euo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/hypr-gaps-off"

if [[ -f "$state" ]]; then
    rm -f "$state"
    hyprctl reload >/dev/null
    hyprctl notify 5 1500 0 "gaps on" >/dev/null 2>&1 || true
else
    touch "$state"
    hyprctl --batch "\
        keyword general:gaps_in 0 ; \
        keyword general:gaps_out 0 ; \
        keyword general:border_size 0 ; \
        keyword decoration:rounding 0" >/dev/null
    hyprctl notify 5 1500 0 "gaps off" >/dev/null 2>&1 || true
fi
