#!/usr/bin/env bash
# ==============================================================================
# toggle.sh - Toggle Live Screen Ambilight for ASUS TUF / ROG
# ==============================================================================

DAEMON_BIN="$HOME/.config/hypr/custom/scripts/ambilight/asus_ambilight"
RESTORE_SCRIPT="$HOME/.config/hypr/custom/scripts/apply_aura.sh"

stop_daemon() {
    # 1. Immediate visual feedback to user via native Quickshell OSD
    qs -c ii ipc call osdAmbilight trigger "OFF" >/dev/null 2>&1
    echo "OFF" > /tmp/asus_current_ambilight_state

    # 2. Terminate the daemon process cleanly
    pkill -TERM -x asus_ambilight 2>/dev/null
    
    # 3. Restore wallpaper theme color asynchronously
    (
        for i in {1..10}; do
            if ! pgrep -x asus_ambilight >/dev/null; then
                break
            fi
            sleep 0.05
        done
        "$RESTORE_SCRIPT" -f >/dev/null 2>&1
    ) &
}

start_daemon() {
    if ! pgrep -x asus_ambilight >/dev/null; then
        # 1. Immediate visual feedback
        qs -c ii ipc call osdAmbilight trigger "ON" >/dev/null 2>&1
        echo "ON" > /tmp/asus_current_ambilight_state

        # 2. Launch daemon detached from subshell
        nohup "$DAEMON_BIN" >/dev/null 2>&1 &
        disown
    fi
}

case "$1" in
    status)
        if pgrep -x asus_ambilight >/dev/null; then
            echo "active"
            exit 0
        else
            echo "inactive"
            exit 1
        fi
        ;;
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    *)
        if pgrep -x asus_ambilight >/dev/null; then
            stop_daemon
        else
            start_daemon
        fi
        ;;
esac
