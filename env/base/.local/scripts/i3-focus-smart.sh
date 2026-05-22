#!/bin/bash

direction="$1"

# Get current focused window ID
old_window=$(i3-msg -t get_tree | jq '.. | select(.focused? == true).window')

# Try to move focus
i3-msg "focus $direction" >/dev/null

# Get new focused window ID
new_window=$(i3-msg -t get_tree | jq '.. | select(.focused? == true).window')

# If the window ID is unchanged, try moving to output
if [ "$old_window" == "$new_window" ]; then
  i3-msg "focus output $direction" >/dev/null
fi
