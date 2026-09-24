import qs.modules.ii.onScreenDisplay
import qs
import QtQuick

OsdValueIndicator {
    id: root

    readonly property int level: GlobalStates.asusKbdBrightness

    name: "Kbd Light"
    valueText: {
        switch (root.level) {
            case 0: return "Off"
            case 1: return "Low"
            case 2: return "Med"
            case 3: return "High"
            default: return root.level + "/3"
        }
    }

    value: Math.max(0, Math.min(1, root.level / 3.0))

    icon: root.level === 0 ? "keyboard_off" : "keyboard"
}
