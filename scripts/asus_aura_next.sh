#!/usr/bin/env bash
# Cycle ASUS keyboard Aura mode, skipping redundant RainbowWave, and trigger native Quickshell OSD

asusctl aura effect --next-mode >/dev/null 2>&1

MODE="Unknown"
if [ -f /etc/asusd/aura_tuf.ron ]; then
    MODE=$(grep "current_mode:" /etc/asusd/aura_tuf.ron | head -n 1 | awk '{print $2}' | tr -d ',\r\n')
fi

# RainbowWave and RainbowCycle are identical on 1-zone TUF keyboard, skip RainbowWave
if [ "$MODE" == "RainbowWave" ]; then
    asusctl aura effect --next-mode >/dev/null 2>&1
    if [ -f /etc/asusd/aura_tuf.ron ]; then
        MODE=$(grep "current_mode:" /etc/asusd/aura_tuf.ron | head -n 1 | awk '{print $2}' | tr -d ',\r\n')
    fi
fi

# When landing back on Static mode, restore the wallpaper theme color
if [ "$MODE" == "Static" ]; then
    "$HOME/.config/hypr/custom/scripts/apply_aura.sh" -f >/dev/null 2>&1
fi

echo "$MODE" > /tmp/asus_current_aura_mode

# Trigger native Quickshell OSD with the exact mode for smooth animation
qs -c ii ipc call osdAura trigger "$MODE" >/dev/null 2>&1
