#!/bin/sh

num_monitors=$(${HOME}/.config/yabai/count_monitors.py)
# DESIRED_SPACES_PER_DISPLAY=$((num_monitors*4))
if [[ $num_monitors -eq 2 ]];
then
  DESIRED_SPACES_PER_DISPLAY=5
  unlink /Users/termanteus/.config/skhd/skhdrc
  ln -s /Users/termanteus/.config/skhd/skhdrc_1monitor /Users/termanteus/.config/skhd/skhdrc
  skhd --stop-service
  skhd --start-service
elif [[ $num_monitors -eq 3 ]];
then
  DESIRED_SPACES_PER_DISPLAY=3
  unlink /Users/termanteus/.config/skhd/skhdrc
  ln -s /Users/termanteus/.config/skhd/skhdrc_3monitors /Users/termanteus/.config/skhd/skhdrc
  skhd --stop-service
  skhd --start-service
else
  DESIRED_SPACES_PER_DISPLAY=10
  unlink /Users/termanteus/.config/skhd/skhdrc
  ln -s /Users/termanteus/.config/skhd/skhdrc_1monitor /Users/termanteus/.config/skhd/skhdrc
  skhd --stop-service
  skhd --start-service
fi
  
# DESIRED_SPACES_PER_DISPLAY=4
CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh' | sort -u)"
echo "Current spaces: ${CURRENT_SPACES}" >> log.log

DELTA=0
while read -r line
do
  LAST_SPACE="$(echo "${line##* }")"
  echo "last space Original: ${LAST_SPACE}" >> log.log
  LAST_SPACE=$(($LAST_SPACE+$DELTA))
  echo "last space Updated with delta: ${LAST_SPACE}" >> log.log
  EXISTING_SPACE_COUNT="$(echo "$line" | wc -w)"
  echo "EXISTING_SPACE_COUNT: ${EXISTING_SPACE_COUNT}" >> log.log
  MISSING_SPACES=$(($DESIRED_SPACES_PER_DISPLAY - $EXISTING_SPACE_COUNT))
  echo "MISSING_SPACES: ${MISSING_SPACES}" >> log.log
  if [ "$MISSING_SPACES" -gt 0 ]; then
    for i in $(seq 1 $MISSING_SPACES)
    do
      MONITOR_ID=$((LAST_SPACE/DESIRED_SPACES_PER_DISPLAY+1))
      yabai -m space --create $MONITOR_ID
      echo "Create space: yabai -m space --create ${MONITOR_ID}" >> log.log
      LAST_SPACE=$(($LAST_SPACE+1))
    done
  elif [ "$MISSING_SPACES" -lt 0 ]; then
    for i in $(seq 1 $((-$MISSING_SPACES)))
    do
      yabai -m space --destroy "$LAST_SPACE"
      echo "Delete space: yabai -m space --destroy ${LAST_SPACE}" >> log.log
      LAST_SPACE=$(($LAST_SPACE-1))
    done
  fi
  DELTA=$(($DELTA+$MISSING_SPACES))
  echo "Delta: ${DELTA}" >> log.log
done <<< "$CURRENT_SPACES"

osascript -e 'display notification "Finished create_spaces"'
