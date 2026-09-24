#!/usr/bin/env bash
# ==============================================================================
# restore_asus_quickshell.sh - Auto-heal ASUS OSD integration after dots updates
# ==============================================================================

BACKUP_DIR="$HOME/.config/hypr/custom/quickshell_backup"
QS_DIR="$HOME/.config/quickshell/ii"
INDICATORS_DIR="$QS_DIR/modules/ii/onScreenDisplay/indicators"

# Check if any ASUS indicators are missing or overwritten
NEEDS_RESTORE=false

if [ ! -f "$INDICATORS_DIR/FanIndicator.qml" ] || \
   [ ! -f "$INDICATORS_DIR/AmbilightIndicator.qml" ] || \
   ! grep -q "osdAmbilight" "$QS_DIR/modules/ii/onScreenDisplay/OnScreenDisplay.qml" 2>/dev/null; then
    NEEDS_RESTORE=true
fi

if [ "$NEEDS_RESTORE" = true ]; then
    mkdir -p "$INDICATORS_DIR"
    cp -p "$BACKUP_DIR/GlobalStates.qml" "$QS_DIR/GlobalStates.qml" 2>/dev/null
    cp -p "$BACKUP_DIR/Config.qml" "$QS_DIR/modules/common/Config.qml" 2>/dev/null
    cp -p "$BACKUP_DIR/OnScreenDisplay.qml" "$QS_DIR/modules/ii/onScreenDisplay/OnScreenDisplay.qml" 2>/dev/null
    cp -p "$BACKUP_DIR/OsdValueIndicator.qml" "$QS_DIR/modules/ii/onScreenDisplay/OsdValueIndicator.qml" 2>/dev/null
    cp -p "$BACKUP_DIR/indicators/"*.qml "$INDICATORS_DIR/" 2>/dev/null
    
    # Reload quickshell if running
    if pgrep -x qs >/dev/null; then
        killall qs quickshell 2>/dev/null
        hyprctl dispatch "hl.dsp.exec_cmd('killall qs quickshell; qs -c ii &')"
        disown
    fi
fi
