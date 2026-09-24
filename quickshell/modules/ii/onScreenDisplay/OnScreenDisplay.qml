import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    property string currentIndicator: "volume"
    property var indicators: [
        {
            id: "volume",
            sourceUrl: "indicators/VolumeIndicator.qml"
        },
        {
            id: "brightness",
            sourceUrl: "indicators/BrightnessIndicator.qml"
        },
        {
            id: "gamma",
            sourceUrl: "indicators/GammaIndicator.qml"
        },
        {
            id: "fan",
            sourceUrl: "indicators/FanIndicator.qml"
        },
        {
            id: "aura",
            sourceUrl: "indicators/AuraIndicator.qml"
        },
        {
            id: "kbdBrightness",
            sourceUrl: "indicators/KbdBrightnessIndicator.qml"
        },
        {
            id: "ambilight",
            sourceUrl: "indicators/AmbilightIndicator.qml"
        }
    ]

    function triggerOsd() {
        GlobalStates.osdVolumeOpen = true;
        osdTimeout.restart();
    }

    Timer {
        id: osdTimeout
        interval: Config.options.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            GlobalStates.osdVolumeOpen = false;
            root.protectionMessage = "";
        }
    }

    // Initialize states on startup
    Component.onCompleted: {
        fanProfileFile.reload();
        kbdBrightnessFile.reload();
    }

    // Instant auto-detection for hardware Fn+F5 key via direct ACPI sysfs polling (100ms, 0% CPU)
    FileView {
        id: fanProfileFile
        path: "/sys/firmware/acpi/platform_profile"
        onLoaded: {
            const raw = (fanProfileFile.text() || "").trim().toLowerCase();
            if (raw.length > 0) {
                if (fanProfilePoller.initialized && raw !== GlobalStates.asusFanProfile) {
                    root.protectionMessage = "";
                    root.currentIndicator = "fan";
                    root.triggerOsd();
                    Qt.callLater(() => {
                        GlobalStates.asusFanProfile = raw;
                    });
                } else if (!fanProfilePoller.initialized) {
                    GlobalStates.asusFanProfile = raw;
                    fanProfilePoller.initialized = true;
                }
            }
        }
    }

    Timer {
        id: fanProfilePoller
        interval: 100
        repeat: true
        running: true
        property bool initialized: false
        onTriggered: fanProfileFile.reload()
    }

    // Auto-detect keyboard backlight brightness changes from hardware keys
    FileView {
        id: kbdBrightnessFile
        path: "/sys/class/leds/asus::kbd_backlight/brightness"
        onLoaded: {
            const raw = (kbdBrightnessFile.text() || "").trim();
            if (raw.length > 0) {
                const b = parseInt(raw);
                if (!isNaN(b)) {
                    if (kbdBrightnessPoller.initialized && b !== GlobalStates.asusKbdBrightness) {
                        root.protectionMessage = "";
                        root.currentIndicator = "kbdBrightness";
                        root.triggerOsd();
                        Qt.callLater(() => {
                            GlobalStates.asusKbdBrightness = b;
                        });
                    } else if (!kbdBrightnessPoller.initialized) {
                        GlobalStates.asusKbdBrightness = b;
                        kbdBrightnessPoller.initialized = true;
                    }
                }
            }
        }
    }

    Timer {
        id: kbdBrightnessPoller
        interval: 100
        repeat: true
        running: true
        property bool initialized: false
        onTriggered: kbdBrightnessFile.reload()
    }

    // Auto-detect power profile changes from D-Bus as secondary fallback
    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            let p = "balanced";
            switch (PowerProfiles.profile) {
                case PowerProfile.PowerSaver: p = "quiet"; break;
                case PowerProfile.Performance: p = "performance"; break;
            }
            if (p !== GlobalStates.asusFanProfile) {
                root.protectionMessage = "";
                root.currentIndicator = "fan";
                root.triggerOsd();
                Qt.callLater(() => {
                    GlobalStates.asusFanProfile = p;
                });
            }
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            root.protectionMessage = "";
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        target: Hyprsunset
        function onGammaChangeAttempt() {
            root.protectionMessage = "";
            root.currentIndicator = "gamma";
            root.triggerOsd();
        }
    }

    Connections {
        // Listen to volume changes
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
        function onMutedChanged() {
            if (!Audio.ready)
                return;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }

    Connections {
        // Listen to protection triggers
        target: Audio
        function onSinkProtectionTriggered(reason) {
            root.protectionMessage = reason;
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }

    Loader {
        id: osdLoader
        active: GlobalStates.osdVolumeOpen

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen;
                }
            }

            WlrLayershell.namespace: "quickshell:onScreenDisplay"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
            }
            mask: Region {
                item: osdValuesWrapper
            }

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            margins {
                top: Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight
            visible: osdLoader.active

            ColumnLayout {
                id: columnLayout
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    id: osdValuesWrapper
                    // Extra space for shadow
                    implicitHeight: contentColumnLayout.implicitHeight
                    implicitWidth: contentColumnLayout.implicitWidth
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: GlobalStates.osdVolumeOpen = false
                    }

                    Column {
                        id: contentColumnLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        spacing: 0

                        Loader {
                            id: osdIndicatorLoader
                            source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl
                        }

                        Item {
                            id: protectionMessageWrapper
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitHeight: protectionMessageBackground.implicitHeight
                            implicitWidth: protectionMessageBackground.implicitWidth
                            opacity: root.protectionMessage !== "" ? 1 : 0

                            StyledRectangularShadow {
                                target: protectionMessageBackground
                            }
                            Rectangle {
                                id: protectionMessageBackground
                                anchors.centerIn: parent
                                color: Appearance.m3colors.m3error
                                property real padding: 10
                                implicitHeight: protectionMessageRowLayout.implicitHeight + padding * 2
                                implicitWidth: protectionMessageRowLayout.implicitWidth + padding * 2
                                radius: Appearance.rounding.normal

                                RowLayout {
                                    id: protectionMessageRowLayout
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        id: protectionMessageIcon
                                        text: "dangerous"
                                        iconSize: Appearance.font.pixelSize.hugeass
                                        color: Appearance.m3colors.m3onError
                                    }
                                    StyledText {
                                        id: protectionMessageTextWidget
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Appearance.m3colors.m3onError
                                        wrapMode: Text.Wrap
                                        text: root.protectionMessage
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osdVolume"

        function trigger() {
            root.triggerOsd();
        }

        function hide() {
            GlobalStates.osdVolumeOpen = false;
        }

        function toggle() {
            GlobalStates.osdVolumeOpen = !GlobalStates.osdVolumeOpen;
        }
    }
    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers volume OSD on press"

        onPressed: {
            root.triggerOsd();
        }
    }
    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides volume OSD on press"

        onPressed: {
            GlobalStates.osdVolumeOpen = false;
        }
    }
    IpcHandler {
        target: "osdFan"

        function trigger(profile: string) {
            root.protectionMessage = "";
            root.currentIndicator = "fan";
            root.triggerOsd();
            if (profile && profile.length > 0) {
                Qt.callLater(() => {
                    GlobalStates.asusFanProfile = profile.toLowerCase();
                });
            } else {
                fanProfileFile.reload();
            }
        }
    }

    IpcHandler {
        target: "osdAura"

        function trigger(mode: string) {
            root.protectionMessage = "";
            root.currentIndicator = "aura";
            root.triggerOsd();
            if (mode && mode.length > 0) {
                Qt.callLater(() => {
                    GlobalStates.asusAuraMode = mode;
                });
            }
        }
    }

    IpcHandler {
        target: "osdKbdBrightness"

        function trigger(level: int) {
            root.protectionMessage = "";
            root.currentIndicator = "kbdBrightness";
            root.triggerOsd();
            if (level !== undefined && level >= 0) {
                Qt.callLater(() => {
                    GlobalStates.asusKbdBrightness = level;
                });
            } else {
                kbdBrightnessFile.reload();
            }
        }
    }

    IpcHandler {
        target: "osdAmbilight"

        function trigger(state: string) {
            let targetState = "OFF";
            if (state && state.length > 0) {
                targetState = state.toUpperCase();
            } else {
                targetState = (GlobalStates.asusAmbilightState === "ON") ? "OFF" : "ON";
            }
            root.protectionMessage = "";
            root.currentIndicator = "ambilight";
            root.triggerOsd();
            Qt.callLater(() => {
                GlobalStates.asusAmbilightState = targetState;
            });
        }
    }
}
