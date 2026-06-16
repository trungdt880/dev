#!/usr/bin/env sh

BATT=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT" | grep -Eo "\d+%" | head -1 | cut -d% -f1)
CHARGING=$(echo "$BATT" | grep -c 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

if [ "$CHARGING" -ne 0 ]; then
  ICON="󰂄"
else
  case ${PERCENTAGE} in
    100|9[0-9]) ICON="󰁹" ;;
    8[0-9])     ICON="󰂂" ;;
    7[0-9])     ICON="󰂁" ;;
    6[0-9])     ICON="󰂀" ;;
    5[0-9])     ICON="󰁿" ;;
    4[0-9])     ICON="󰁾" ;;
    3[0-9])     ICON="󰁽" ;;
    2[0-9])     ICON="󰁼" ;;
    1[0-9])     ICON="󰁻" ;;
    [0-9])      ICON="󰁺" ;;
    *)          ICON="󰂎" ;;
  esac
fi

sketchybar --set power_logo icon="$ICON" --set battery label="${PERCENTAGE}%"
