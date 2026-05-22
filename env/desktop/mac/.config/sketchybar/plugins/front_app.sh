#!/usr/bin/env sh

AUX_DIR="$HOME/.config/sketchybar/aux"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

sketchybar --add       event        window_focus                  \
           --add       item         system.yabai left             \
           --set       system.yabai script="$AUX_DIR/yabai.sh" \
                                    icon.font="Hack Nerd Font:Bold:16.0"   \
                                    label.drawing=off             \
                                    icon.width=25                 \
                                    icon=$YABAI_GRID              \
                                    icon.color=$GREEN             \
                                    updates=on                    \
                                    associated_display=active     \
           --subscribe system.yabai window_focus                  \
                                    mouse.clicked                 \
                                                                  \
           --add       item         front_app left                \
           --subscribe front_app    front_app_switched

