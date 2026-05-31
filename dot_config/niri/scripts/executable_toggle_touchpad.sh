#!/bin/bash

#Define the file and pattern
FILE="$HOME/.config/niri/input.kdl"

if grep -q "// off // toggletouchpad" "$FILE"; then
    sed -i 's/\/\/ off \/\/ toggletouchpad/off \/\/ toggletouchpad/' "$FILE"
    niri msg action load-config-file
    notify-send "Touchpad is Off"
else
    sed -i 's/off \/\/ toggletouchpad/\/\/ off \/\/ toggletouchpad/' "$FILE"
    niri msg action load-config-file
    notify-send "Touchpad is On"
fi
