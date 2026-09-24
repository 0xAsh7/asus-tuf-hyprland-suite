import qs.modules.ii.onScreenDisplay
import qs
import QtQuick

OsdValueIndicator {
    id: root

    readonly property string profile: GlobalStates.asusFanProfile.toLowerCase()

    name: "Fan"
    valueText: {
        if (root.profile === "quiet") return "Quiet"
        if (root.profile === "performance") return "Performance"
        return "Balanced"
    }

    value: {
        if (root.profile === "quiet") return 0.33
        if (root.profile === "performance") return 1.0
        return 0.66
    }

    icon: {
        if (root.profile === "quiet") return "routine"
        if (root.profile === "performance") return "bolt"
        return "mode_fan"
    }
}
