#!/usr/bin/env bash
# ==============================================================================
# apply_aura.sh - Ultra-efficient ASUS Aura Keyboard Sync for end-4 Hyprland dots
# ==============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
CACHE_FILE="$CACHE_DIR/asus_aura_last_color"
COLOR_FILE="$STATE_DIR/asus_aura.txt"
FALLBACK_FILE="$STATE_DIR/color.txt"

FORCE=false
COLOR=""

for arg in "$@"; do
    case "$arg" in
        -f|--force)
            FORCE=true
            ;;
        *)
            if [ -z "$COLOR" ]; then
                COLOR="$arg"
            fi
            ;;
    esac
done

# If no color argument provided, read from the generated template file
if [ -z "$COLOR" ]; then
    if [ -f "$COLOR_FILE" ]; then
        COLOR=$(head -n 1 "$COLOR_FILE" 2>/dev/null)
    elif [ -f "$FALLBACK_FILE" ]; then
        COLOR=$(head -n 1 "$FALLBACK_FILE" 2>/dev/null)
    fi
fi

# Sanitize color string: remove leading '#', spaces, newlines, and lowercase it
COLOR=$(echo "$COLOR" | tr -d '#[:space:]' | tr '[:upper:]' '[:lower:]')

# Validate: must be exactly 6 hex characters (0-9, a-f)
if [[ ! "$COLOR" =~ ^[0-9a-f]{6}$ ]]; then
    exit 0
fi

# Optimization: Deduplication / Delta check
# Avoid redundant D-Bus calls and SSD NVMe writes if color is identical
if [ "$FORCE" = false ] && [ -f "$CACHE_FILE" ]; then
    LAST_COLOR=$(cat "$CACHE_FILE" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$COLOR" == "$LAST_COLOR" ]; then
        # Already set to this exact color, exit cleanly with zero overhead
        exit 0
    fi
fi

SYSFS_NODE="/sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode"
if [ -w "$SYSFS_NODE" ]; then
    r=$((16#${COLOR:0:2}))
    g=$((16#${COLOR:2:2}))
    b=$((16#${COLOR:4:2}))
    echo "0 0 $r $g $b 0" > "$SYSFS_NODE"
    mkdir -p "$CACHE_DIR"
    echo "$COLOR" > "$CACHE_FILE"
elif command -v asusctl &>/dev/null; then
    asusctl aura effect static -c "$COLOR" >/dev/null 2>&1
    mkdir -p "$CACHE_DIR"
    echo "$COLOR" > "$CACHE_FILE"
fi
