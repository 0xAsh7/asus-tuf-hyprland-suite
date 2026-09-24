-- Custom user keybinds
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/ambilight/toggle.sh"), { description = "Toggle Live Screen Ambilight" })

-- ASUS TUF / ROG Official Hardware Controls
-- 1. Fn + F4: Cycle Keyboard Aura Mode (skipping duplicate RainbowWave)
hl.bind("XF86Launch4", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_aura_next.sh"), { locked = true, description = "ASUS: Cycle Keyboard Aura Mode (Fn+F4)" })

-- 2. Fn + F5: Cycle Fan / Power Profile
hl.bind("XF86Fn_F5", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"), { locked = true, description = "ASUS: Cycle Fan Profile (Fn+F5)" })
hl.bind("XF86Phone", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"), { locked = true, description = "ASUS: Cycle Fan Profile (ASUS Fan Key)" })
hl.bind("XF86Launch1", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"), { locked = true, description = "ASUS: Cycle Fan Profile (Fn+F5 Alt 1)" })
hl.bind("XF86Launch2", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"), { locked = true, description = "ASUS: Cycle Fan Profile (Fn+F5 Alt 2)" })
hl.bind("SUPER + F5", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/asus_fan_profile.sh"), { locked = true, description = "ASUS: Cycle Fan Profile (Super+F5 fallback)" })

-- 3. Dedicated ROG / ASUS Key: Open ROG Control Center
hl.bind("XF86Launch3", hl.dsp.exec_cmd("rog-control-center"), { locked = true, description = "ASUS: Open ROG Control Center" })

-- 4. Keyboard Backlight Brightness
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("qs -c ii ipc call osdKbdBrightness trigger"), { locked = true, description = "ASUS: Keyboard Brightness Down" })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("qs -c ii ipc call osdKbdBrightness trigger"), { locked = true, description = "ASUS: Keyboard Brightness Up" })
