#!/usr/bin/env bash
# Toggle AeroSpace gaps on/off by rewriting the [gaps] block between markers,
# then reloading the config. AeroSpace has no runtime gap command.
set -euo pipefail

CONFIG="$HOME/.config/aerospace/aerospace.toml"
STATE="/tmp/aerospace-gaps-state"

state=$(cat "$STATE" 2>/dev/null || echo on)

if [ "$state" = on ]; then
  next=off; g=0; top=0
else
  next=on; g=10; top='[{ monitor.built-in = 16 }, 52]'
fi

# BSD awk (macOS) forbids newlines in -v vars, so build the block line-by-line.
awk -v g="$g" -v top="$top" '
  /# GAPS_START/ {
    print
    print "[gaps]"
    print "    inner.horizontal = " g
    print "    inner.vertical =   " g
    print "    outer.left =       " g
    print "    outer.bottom =     " g
    print "    outer.top =        " top
    print "    outer.right =      " g
    skip=1; next
  }
  /# GAPS_END/ { skip=0 }
  !skip        { print }
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

echo "$next" > "$STATE"
aerospace reload-config
