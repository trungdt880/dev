#!/usr/bin/env bash

# Make executable: chmod +x ~/.config/sketchybar/plugins/aerospace.sh

source "$HOME/.config/sketchybar/colors.sh"

# Same-size geometric glyphs => identical baseline => perfect alignment.
FILLED=$(printf '\342\227\217')  # U+25CF ●  black circle
HOLLOW=$(printf '\342\227\213')  # U+25CB ○  white circle

# Uniform font/offset for every state; only glyph + color change.
FONT="Hack Nerd Font:Regular:16.0"

sid=${NAME#space.}
napps=$(aerospace list-windows --workspace "$sid" --count)

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  icon=$FILLED                 # focused: filled accent
  color=$ACCENT
elif [ "$napps" -gt 0 ]; then
  icon=$FILLED                 # occupied: filled muted
  color=$OVERLAY0
else
  icon=$HOLLOW                 # empty: hollow ring
  color=$OVERLAY0
fi

sketchybar -m --animate tanh 5 --set "$NAME" \
  icon="$icon" \
  icon.color="$color" \
  icon.font="$FONT" \
  icon.y_offset=0
