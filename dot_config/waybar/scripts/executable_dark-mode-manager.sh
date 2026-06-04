#!/usr/bin/bash

LIGHT_TIME="08:00"
DARK_TIME="18:00"

MODE=$1
CURRENT_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
CURRENT_WALLPAPER=$(pgrep -a swaybg | grep -oP '(?<=-i )[^ ]+' | head -n 1)

get_dark_mode() {
    if [[ ${CURRENT_SCHEME} == "'prefer-dark'" ]]; then
        echo '{"alt": "dark"}'
    else
        echo '{"alt": "light"}'
    fi
}

set_dark_mode() {
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null
    matugen image "${CURRENT_WALLPAPER}" --source-color-index 0 -m dark
}

set_light_mode() {
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null
    matugen image "${CURRENT_WALLPAPER}" --source-color-index 0 -m light
}

toggle_dark_mode() {
    if [[ "${CURRENT_SCHEME}" == "'prefer-dark'" ]]; then
        set_light_mode
    else
        set_dark_mode
    fi

    pkill -RTMIN+8 waybar
}

auto_set_dark_mode() {
    CURRENT_TIME=$(date +%H:%M)
    if [[ "${CURRENT_TIME}" > "${DARK_TIME}" || "${CURRENT_TIME}" < "${LIGHT_TIME}" ]]; then
        set_dark_mode
        notify-send "Dark mode enabled" --urgency=low
    else
        set_light_mode
        notify-send "Light mode enabled" --urgency=low
    fi
}

if [[ ${MODE} == "get" ]]; then
    get_dark_mode
elif [[ ${MODE} == "toggle" ]]; then
    toggle_dark_mode
elif [[ ${MODE} == "auto" ]]; then
    auto_set_dark_mode
else
    echo "Usage: $0 [get|toggle|auto]"
fi
