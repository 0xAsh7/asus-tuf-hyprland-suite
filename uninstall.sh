#!/usr/bin/env bash
# ==============================================================================
# ASUS ROG & TUF Linux Suite - Uninstaller
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Uninstalling ASUS ROG & TUF custom suite...${NC}"

# Stop ambilight daemon if running
pkill -TERM -x asus_ambilight 2>/dev/null || true

# Remove scripts
rm -rf "$HOME/.config/hypr/custom/scripts/ambilight"
rm -f "$HOME/.config/hypr/custom/scripts/apply_aura.sh"
rm -f "$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"
rm -f "$HOME/.config/hypr/custom/scripts/asus_aura_next.sh"
rm -f "$HOME/.config/hypr/custom/scripts/restore_asus_quickshell.sh"
rm -rf "$HOME/.config/hypr/custom/quickshell_backup"

# Remove systemd tmpfiles rule
if [ -f "/etc/tmpfiles.d/asus-kbd.conf" ]; then
    echo "Removing /etc/tmpfiles.d/asus-kbd.conf (requires sudo)..."
    sudo rm -f /etc/tmpfiles.d/asus-kbd.conf
fi

# Remove indicators from quickshell
rm -f "$HOME/.config/quickshell/ii/modules/ii/onScreenDisplay/indicators/FanIndicator.qml"
rm -f "$HOME/.config/quickshell/ii/modules/ii/onScreenDisplay/indicators/AuraIndicator.qml"
rm -f "$HOME/.config/quickshell/ii/modules/ii/onScreenDisplay/indicators/KbdBrightnessIndicator.qml"
rm -f "$HOME/.config/quickshell/ii/modules/ii/onScreenDisplay/indicators/AmbilightIndicator.qml"

echo -e "${GREEN}✓ ASUS ROG & TUF custom components removed.${NC}"
echo -e "${BLUE}Tip: You can now re-run your dotfiles installer to restore default Quickshell files:${NC}"
echo "  ~/.cache/dots-hyprland/setup install-files"
