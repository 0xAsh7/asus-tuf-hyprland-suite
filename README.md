# ASUS ROG & TUF Linux Suite for Hyprland (CachyOS / Arch)

> **Complete open-source ASUS G-Helper functionality for Linux.**  
> Native Quickshell OSD overlays, official hardware hotkeys, dynamic micro-animations, wallpaper-reactive RGB, and real-time screen ambilight powered by direct kernel sysfs writes with 0% idle CPU and zero disk wear.

---

## Highlights & Features

- **Native Floating Capsule OSD Overlays:**  
  Zero desktop notifications (`notify-send` completely eliminated). Replaced with sleek, floating Material 3 pill overlays matching your system volume and screen brightness sliders with live `Behavior on value` animations.
- **Official ASUS Hardware Hotkeys:**  
  - `Fn + F4`: Cycle Keyboard Aura Modes (Static, Breathe, Rainbow, Pulse).
  - `Fn + F5`: Instant ACPI Power / Fan Profile switching (Quiet, Balanced, Performance).
  - `Fn + F2` / `Fn + F3`: Keyboard backlight brightness steps with live OSD feedback.
  - `SUPER + ALT + L`: Toggle Realtime Screen Ambilight with animated ON / OFF indicator.
  - `Dedicated ROG Key` (`XF86Launch3`): Instantly launches `rog-control-center`.
- **Sub-Millisecond Direct Kernel Sysfs Path:**  
  Direct `0 0 r g b 0` writes to `/sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode` bypassing D-Bus and subprocesses. Updates take **< 0.05ms** with zero SSD/NVMe wear.
- **Tier 1 — Theme-Reactive Static Backlight:**  
  Automatically synchronizes your keyboard backlight with your active Matugen wallpaper theme on boot and theme switch. Features delta-caching to eliminate redundant writes.
- **Tier 2 — Ultra-Lightweight Screencopy Ambilight:**  
  Compiled `-O3` native C Wayland screencopy daemon (`wlr-screencopy-v1`). Subsamples display buffers in microseconds with dynamic vibrancy enhancement and delta-threshold skipping (< 0.1% CPU).
- **3-Layer Persistence & Auto-Healing:**  
  Completely immune to system reboots, Arch/CachyOS updates, and `end-4/dots-hyprland` git pulls or re-installations.

---

## Keybindings Reference

| Hotkey | Action | OSD Indicator | Details |
| :--- | :--- | :---: | :--- |
| `Fn + F4` | **Cycle Aura Modes** | `palette` **Aura** | Cycles Static → Breathe → Rainbow → Pulse. Restores wallpaper color on Static. |
| `Fn + F5` | **Cycle Power / Fan** | `mode_fan` / `bolt` **Fan** | Instant ACPI switch: Quiet (33%), Balanced (66%), Performance (100%). |
| `Fn + F2 / F3` | **Backlight Brightness** | `keyboard` **Kbd Light** | Live steps: Off (0%), Low (33%), Med (66%), High (100%). |
| `SUPER + ALT + L` | **Toggle Ambilight** | `live_tv` **Ambilight** | Toggles realtime screen ambilight with smooth ON/OFF transition. |
| `ROG Key` | **ROG Control Center** | — | Opens official ASUS ROG GUI utility. |
| `SUPER + F5` | **Fan Profile (Fallback)** | `mode_fan` **Fan** | Software fallback if keyboard lacks Fn-lock. |

---

## Directory Structure

```text
.
├── install.sh                              # Automated 1-command installer
├── uninstall.sh                            # Clean uninstaller / revert script
├── README.md                               # Comprehensive documentation
├── .gitignore                              # Git exclusion rules
│
├── scripts/                                # Custom shell scripts & daemons
│   ├── apply_aura.sh                       # Wallpaper theme sync with fast sysfs write
│   ├── asus_fan_profile.sh                 # Fan profile cycler & IPC dispatcher
│   ├── asus_aura_next.sh                   # Aura mode cycler (skips duplicate RainbowWave)
│   ├── restore_asus_quickshell.sh          # Self-healing auto-restore hook
│   └── ambilight/                          # Realtime screen ambilight daemon
│       ├── asus_ambilight.c                # C screencopy ambilight implementation
│       ├── Makefile                        # Compiler rules (-O3 optimization)
│       ├── toggle.sh                       # Instant detached toggle & IPC trigger
│       ├── wlr-screencopy-client-protocol.h
│       └── wlr-screencopy-protocol.c
│
├── hyprland/custom/                        # Hyprland custom configuration files
│   ├── keybinds.lua                        # Hotkey bindings for ASUS ROG/TUF hardware
│   └── execs.lua                           # Startup hooks (theme sync + self-healing)
│
├── quickshell/                             # Quickshell native OSD overlay components
│   ├── GlobalStates.qml                    # Reactive in-memory state engine
│   ├── modules/common/Config.qml           # System tray conflict suppression
│   ├── modules/ii/onScreenDisplay/
│   │   ├── OnScreenDisplay.qml             # OSD engine, hardware pollers & IPC targets
│   │   └── OsdValueIndicator.qml           # Bounded capsule layout with animated slider
│   └── indicators/                         # Custom ASUS OSD capsules
│       ├── FanIndicator.qml                # Fan profile capsule (Quiet/Balanced/Performance)
│       ├── AuraIndicator.qml               # Aura mode capsule (Static/Breathe/Rainbow/Pulse)
│       ├── KbdBrightnessIndicator.qml      # Keyboard light capsule (Off/Low/Med/High)
│       └── AmbilightIndicator.qml          # Ambilight capsule (ON/OFF)
│
├── systemd/                                # Persistent system configuration
│   └── asus-kbd.conf                       # /etc/tmpfiles.d rule for 0666 sysfs access
│
└── illogical-impulse/                      # Dots-hyprland update protection
    └── updateignore                        # Preserves custom Quickshell files from updates
```

---

## Installation & Setup

### Prerequisites
- **Hardware:** ASUS TUF Gaming or ROG laptop (e.g., TUF F15 `FX507ZV4`).
- **OS:** CachyOS / Arch Linux (or any Arch-based distribution).
- **Desktop Environment:** Hyprland with [`end-4/dots-hyprland`](https://github.com/end-4/dots-hyprland) (`quickshell`).
- **System Packages:**
  ```bash
  sudo pacman -S --needed base-devel asusctl rog-control-center wayland brightnessctl
  ```

### 1-Command Installation
Clone this repository and run the installer:

```bash
git clone <your-repo-url> asus-suite
cd asus-suite
chmod +x install.sh
./install.sh
```

The installer will automatically:
1. Verify system dependencies.
2. Compile `asus_ambilight` with `-O3` optimizations.
3. Install `/etc/tmpfiles.d/asus-kbd.conf` and configure immediate `0666` permissions for direct kernel writes.
4. Deploy scripts and keybinds to `~/.config/hypr/custom/`.
5. Deploy native Quickshell OSD overlays to `~/.config/quickshell/ii/`.
6. Configure 3-tier persistence against `dots-hyprland` updates.
7. Reload Quickshell and Hyprland.

---

## Technical Deep-Dive

### 1. Direct Kernel Sysfs Path (`kbd_rgb_mode`)
On ASUS laptops driven by `asus-nb-wmi`, the keyboard LED controller exposes:
```
/sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode
```
Writing a space-separated ASCII string `0 0 <R> <G> <B> 0\n` directly commands the embedded controller (EC):
- **Bypasses D-Bus & asusd overhead:** Latency drops from ~50ms to **under 0.05ms**.
- **Zero Subprocesses:** The ambilight daemon holds an open file descriptor (`write()` system call only).
- **Automatic Fallback:** If sysfs permissions are not available, both `asus_ambilight` and `apply_aura.sh` fall back to `asusctl aura effect static -c <HEX>`.

### 2. Live Screencopy Ambilight Engine
`asus_ambilight.c` hooks into Wayland through `zwlr_screencopy_manager_v1`:
- Subsamples full-screen pixel buffers with a 32×32 stride, computing RGB averages in microseconds.
- Applies perceptual saturation vibrancy scaling so LED colors feel vivid rather than washed out.
- Implements a Manhattan distance delta threshold (`DELTA_THRESHOLD = 8`): if on-screen colors haven't changed meaningfully, it skips hardware writes entirely, maintaining 0% idle CPU and protecting your battery.

### 3. Native Quickshell OSD Integration
Instead of intrusive desktop notifications, the suite embeds seamlessly into the `end-4/dots-hyprland` Quickshell bar and OSD subsystem:
- Reactive properties (`asusFanProfile`, `asusAuraMode`, `asusKbdBrightness`, `asusAmbilightState`) live in `GlobalStates.qml`.
- The `OnScreenDisplay.qml` engine features:
  - 100ms lightweight ACPI sysfs poller on `/sys/firmware/acpi/platform_profile` to catch physical `Fn + F5` presses instantly.
  - 100ms poller on `/sys/class/leds/asus::kbd_backlight/brightness` to detect physical brightness keys.
  - Dual fallback listeners connected to `PowerProfiles` D-Bus.
  - IPC handlers (`osdFan`, `osdAura`, `osdKbdBrightness`, `osdAmbilight`) invoked by scripts via `qs -c ii ipc call`.
  - `Qt.callLater` microtask deferred updates ensuring `StyledProgressBar`'s `Behavior on value` animates the fill smoothly from the previous state to the new state on every press.

### 4. 3-Layer Update Persistence
When updating `end-4/dots-hyprland` via `setup exp-update` or `./setup install`:
1. **Layer 1 (Ignore File):** `~/.config/illogical-impulse/updateignore` excludes custom Quickshell OSD modules from being replaced by upstream templates.
2. **Layer 2 (Protected Directory):** `~/.config/hypr/custom/` is marked `--ignore-existing` in the dots installer and is never touched.
3. **Layer 3 (Self-Healing Fallback):** On every Hyprland startup, `execs.lua` invokes `restore_asus_quickshell.sh`. If a full dots reinstall ever overwrote `~/.config/quickshell/ii/`, it automatically detects missing indicators, restores them from `~/.config/hypr/custom/quickshell_backup/`, and restarts Quickshell within 10 milliseconds.

---

## Troubleshooting

### Physical `Fn + F5` does not show OSD or is delayed
1. Verify that `power-profiles-daemon` is running:
   ```bash
   systemctl status power-profiles-daemon
   ```
2. Verify that your kernel exposes the ACPI platform profile:
   ```bash
   cat /sys/firmware/acpi/platform_profile
   ```
3. Use the software fallback keybind `SUPER + F5` if your keyboard firmware blocks the ACPI event.

### Ambilight daemon not writing to sysfs
Run the daemon in foreground to verify permissions:
```bash
~/.config/hypr/custom/scripts/ambilight/asus_ambilight
```
If you see `Fast sysfs path: DISABLED`, verify permissions:
```bash
ls -la /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode
```
It must show `-rw-rw-rw-`. If not, reapply:
```bash
sudo chmod 0666 /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode
sudo systemd-tmpfiles --create /etc/tmpfiles.d/asus-kbd.conf
```

### Quickshell OSD not appearing
Verify that Quickshell IPC is active:
```bash
qs -c ii ipc show | grep osd
```
You should see `osdFan`, `osdAura`, `osdKbdBrightness`, and `osdAmbilight`. If not, restart Quickshell:
```bash
hyprctl dispatch "hl.dsp.exec_cmd('killall qs quickshell; qs -c ii &')"
```

---

## License

MIT License. Designed with precision for the ASUS Linux community.
