#!/usr/bin/env bash

export TRANSPARENT_WHITE=0xFFF8C8DC
export ACCENT_COLOR=0xFFFC81B4
export ACCENT_COLOR=0xffE0A3AD


args=()
if [ "$NAME" != "space_template" ]; then
  sid=${NAME#space.}
  napps=$(yabai -m query --windows --space $sid | jq '. | length')
  if [ $napps -gt 0 ]; then
    icon_=
    fontsize=18
    yoffset=1.5
  else
    icon_=◯
    fontsize=25
    yoffset=3.5
  fi
  args+=(--set $NAME label=$NAME \
                     icon=$icon_ \
                     icon.font="Hack Nerd Font:Regular:$fontsize.0" \
                     icon.color=$TRANSPARENT_WHITE
                     icon.y_offset=$yoffset
                     )
fi

if [ "$SELECTED" = "true" ]; then
  sid=$(($DID + 1))
  args+=(--set space.$sid label=${NAME#"space.$sid"})
  args+=(--set $NAME icon=  icon.color=$ACCENT_COLOR icon.font="Hack Nerd Font:Regular:20.0" icon.y_offset=-0.5)
else
  args+=(--set $NAME)
fi

sketchybar -m --animate tanh 5 "${args[@]}"
