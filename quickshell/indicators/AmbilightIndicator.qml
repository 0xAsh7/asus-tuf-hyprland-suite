import qs.modules.ii.onScreenDisplay
import qs
import QtQuick

OsdValueIndicator {
    id: root

    readonly property bool active: GlobalStates.asusAmbilightState === "ON"

    name: "Ambilight"
    valueText: root.active ? "ON" : "OFF"
    value: root.active ? 1.0 : 0.0
    icon: root.active ? "live_tv" : "tv"
}
