#!/usr/bin/bash

MODE=$1
CURRENT_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
CURRENT_WALLPAPER=$(cat $HOME/.cache/current_wallpaper)

get_dark_mode() {
    if [[ ${CURRENT_SCHEME} == "'prefer-dark'" ]]; then
        echo '{"alt": "dark"}'
    else
        echo '{"alt": "light"}'
    fi
}

set_dark_mode() {
    matugen image "${CURRENT_WALLPAPER}" --source-color-index 0 -m dark 2>/dev/null
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
    # gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
}

set_light_mode() {
    matugen image "${CURRENT_WALLPAPER}" --source-color-index 0 -m light 2>/dev/null
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null
    # gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null
}

toggle_dark_mode() {
    if [[ ${CURRENT_SCHEME} == "'prefer-dark'" ]]; then
        set_light_mode
    else
        set_dark_mode
    fi
    sleep 0.5
    pkill -SIGUSR2 waybar
}

auto_set_dark_mode() {
    LIGHT_TIME=${2//:/}
    DARK_TIME=${3//:/}
    SILENT=$4 # Optional argument to suppress notifications
    echo $LIGHT_TIME
    echo $DARK_TIME

    if [[ -z ${SILENT} ]]; then
        SILENT=false
    fi

    if [[ -z ${LIGHT_TIME} || -z ${DARK_TIME} ]]; then
        echo "Usage: $0 auto <light_time> <dark_time> [silent]"
        exit 1
    fi

    CURRENT_TIME=$(date +%H%M)
    echo $CURRENT_TIME
    if [[ 10#${CURRENT_TIME} -ge 10#${DARK_TIME} || 10#${CURRENT_TIME} -lt 10#${LIGHT_TIME} ]]; then
        set_dark_mode
        if [[ ${SILENT} == false ]]; then
            notify-send "Dark mode enabled" --urgency=low -h int:transient:1
        fi
    else
        set_light_mode
        if [[ ${SILENT} == false ]]; then
            notify-send "Light mode enabled" --urgency=low -h int:transient:1
        fi
    fi
}

if [[ ${MODE} == "get" ]]; then
    get_dark_mode
elif [[ ${MODE} == "toggle" ]]; then
    toggle_dark_mode
elif [[ ${MODE} == "auto" ]]; then
    auto_set_dark_mode "$@"
else
    echo "Usage: $0 [get|toggle|auto]"
fi
