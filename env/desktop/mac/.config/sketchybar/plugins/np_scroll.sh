#!/usr/bin/env bash
# Marquee daemon for the now-playing label. sketchybar's update_freq floors to
# whole seconds (too coarse) and its built-in scroll_texts doesn't animate here,
# so we rotate the label ourselves every DELAY seconds. Fed by nowplaying.sh
# via TEXT_F. Launched (and re-launched) from sketchybarrc; old copies killed.

TEXT_F=/tmp/sketchybar_np.text
WINDOW=25                 # visible chars (matches label.width=200 in rc)
STEP=1                    # chars advanced per frame
DELAY=0.2                 # seconds per frame
SEP="      •      "       # gap shown between loop end and start

offset=0
last=""

while true; do
  txt="$(cat "$TEXT_F" 2>/dev/null)"

  if [ -z "$txt" ] || [ "$txt" = "OFF" ]; then
    offset=0; last=""
    sleep 0.5
    continue
  fi

  # Reset scroll when the track changes.
  if [ "$txt" != "$last" ]; then offset=0; last="$txt"; fi

  if [ "${#txt}" -le "$WINDOW" ]; then
    label="$txt"
  else
    full="$txt$SEP"
    dbl="$full$full"
    label="${dbl:offset:WINDOW}"
    offset=$(( (offset + STEP) % ${#full} ))
  fi

  sketchybar --set media.title label="$label" >/dev/null 2>&1
  sleep "$DELAY"
done
