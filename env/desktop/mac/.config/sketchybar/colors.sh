#!/usr/bin/env sh

# Catppuccin Macchiato palette
# https://github.com/catppuccin/catppuccin
ROSEWATER=0xfff4dbd6
FLAMINGO=0xfff0c6c6
PINK=0xfff5bde6
MAUVE=0xffc6a0f6
RED=0xffed8796
MAROON=0xffee99a0
PEACH=0xfff5a97f
YELLOW=0xffeed49f
GREEN=0xffa6da95
TEAL=0xff8bd5ca
SKY=0xff91d7e3
SAPPHIRE=0xff7dc4e4
BLUE=0xff8aadf4
LAVENDER=0xffb7bdf8

TEXT=0xffcad3f5
SUBTEXT1=0xffb8c0e0
SUBTEXT0=0xffa5adcb
OVERLAY2=0xff939ab7
OVERLAY1=0xff8087a2
OVERLAY0=0xff6e738d
SURFACE2=0xff5b6078
SURFACE1=0xff494d64
SURFACE0=0xff363a4f
BASE=0xff24273a
MANTLE=0xff1e2030
CRUST=0xff181926

# Aliases kept for backward compat with existing plugins
WHITE=$TEXT
MAGENTA=$MAUVE
ORANGE=$PEACH
GREY=$OVERLAY2
TRANSPARENT=0x00000000

# General bar colors
BAR_COLOR=0xf01e2030       # floating bar background (mantle, ~94% alpha)
ICON_COLOR=$TEXT           # color of all icons
LABEL_COLOR=$TEXT          # color of all labels
ITEM_BG=$SURFACE0          # chip / pill background
ACCENT=$PINK               # focused-workspace / highlight accent

POPUP_BACKGROUND_COLOR=$CRUST
POPUP_BORDER_COLOR=$TEXT
SHADOW_COLOR=$CRUST

# Item specific special colors
SPOTIFY_GREEN=0xff1DB954
