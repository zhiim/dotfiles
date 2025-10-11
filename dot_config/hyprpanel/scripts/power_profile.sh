#!/bin/sh

PROFILE=$(cat /sys/firmware/acpi/platform_profile)

case ${PROFILE} in
  performance)
    echo '{"text": "P", "alt": "performance", "tooltip": "Performance Mode"}'
    ;;
  balanced)
    echo '{"text": "B", "alt": "balanced", "tooltip": "Balanced Mode"}'
    ;;
  low-power)
    echo '{"text": "L", "alt": "low-power", "tooltip": "Low-power Mode"}'
    ;;
esac
