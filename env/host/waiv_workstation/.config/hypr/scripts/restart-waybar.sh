#!/usr/bin/env bash
# Restart waybar in place (SUPER+SHIFT+R). Handy after editing style.css.
set -euo pipefail
pkill -x waybar || true
# Give the old layer-shell surface time to go away before claiming a new one.
sleep 0.3
setsid waybar >/dev/null 2>&1 &
