import qs.modules.ii.onScreenDisplay
import qs
import QtQuick

OsdValueIndicator {
    id: root

    readonly property string mode: GlobalStates.asusAuraMode

    name: "Aura"
    valueText: {
        const m = root.mode.toLowerCase()
        if (m === "static") return "Static"
        if (m === "breathe") return "Breathe"
        if (m === "rainbowcycle" || m === "rainbowwave") return "Rainbow"
        if (m === "pulse") return "Pulse"
        return root.mode || "Static"
    }

    value: {
        const m = root.mode.toLowerCase()
        if (m === "static") return 0.25
        if (m === "breathe") return 0.50
        if (m === "rainbowcycle" || m === "rainbowwave") return 0.75
        if (m === "pulse") return 1.0
        return 0.5
    }

    icon: "palette"
}
