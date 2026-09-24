-- Auto-heal ASUS Quickshell OSD integration if overwritten by dots update
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/restore_asus_quickshell.sh")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/apply_aura.sh -f")
end)
