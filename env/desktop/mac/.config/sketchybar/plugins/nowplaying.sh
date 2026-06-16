#!/usr/bin/env bash
# Now-playing poller. Reads macOS Now Playing (MediaRemote) via nowplaying-cli,
# so it catches any source incl. browser tabs (YouTube Music in Arc/Chrome).
# Writes the marquee text to a temp file; np_scroll.sh animates it.

source "$HOME/.config/sketchybar/colors.sh"

CLI="$(command -v nowplaying-cli)"
[ -z "$CLI" ] && exit 0

TEXT_F=/tmp/sketchybar_np.text

PLAY=$(printf '\357\201\213')   # U+F04B play
PAUSE=$(printf '\357\201\214')  # U+F04C pause
NOTE=$(printf '\357\200\201')   # U+F001 music note

# Control clicks
if [ "$SENDER" = "mouse.clicked" ]; then
  case "$NAME" in
    media.prev) "$CLI" previous ;;
    media.next) "$CLI" next ;;
    media.title|media.play) "$CLI" togglePlayPause ;;
  esac
  sleep 0.3
fi

TITLE="$("$CLI" get title 2>/dev/null)"
ARTIST="$("$CLI" get artist 2>/dev/null)"
RATE="$("$CLI" get playbackRate 2>/dev/null)"

# Nothing playing -> hide island, tell scroller to idle.
if [ -z "$TITLE" ] || [ "$TITLE" = "null" ]; then
  echo "OFF" > "$TEXT_F"
  sketchybar --set media.prev  drawing=off \
             --set media.play  drawing=off \
             --set media.next  drawing=off \
             --set media.title drawing=off \
             --set center_island drawing=off
  exit 0
fi

LABEL="$TITLE"
if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
  LABEL="$TITLE — $ARTIST"
fi
printf '%s' "$LABEL" > "$TEXT_F"

# playbackRate 0 == paused
if [ "$RATE" = "0" ] || [ -z "$RATE" ]; then PP="$PLAY"; else PP="$PAUSE"; fi

sketchybar --set center_island drawing=on \
           --set media.title drawing=on icon="$NOTE" \
           --set media.prev  drawing=on \
           --set media.play  drawing=on icon="$PP" \
           --set media.next  drawing=on
