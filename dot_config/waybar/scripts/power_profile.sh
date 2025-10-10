#!/bin/sh

PROFILE=$(cat /sys/firmware/acpi/platform_profile)

case ${PROFILE} in
  performance)
    echo '{"text": "", "tooltip": "Performance Mode"}'
    ;;
  balanced)
    echo '{"text": "", "tooltip": "Balanced Mode"}'
    ;;
  low-power)
    ICON=""
    echo '{"text": "", "tooltip": "Low-power Mode"}'
    ;;
esac
