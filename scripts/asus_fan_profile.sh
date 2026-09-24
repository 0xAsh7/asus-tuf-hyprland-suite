#!/usr/bin/env bash
# Cycle ASUS fan / power profile and trigger native Quickshell OSD overlay

asusctl profile next >/dev/null 2>&1

PROFILE="Balanced"
if [ -f /sys/firmware/acpi/platform_profile ]; then
    PROFILE=$(cat /sys/firmware/acpi/platform_profile | tr -d ' \r\n')
fi

# Send the profile directly to Quickshell IPC for instant response and smooth animation
qs -c ii ipc call osdFan trigger "$PROFILE" >/dev/null 2>&1
