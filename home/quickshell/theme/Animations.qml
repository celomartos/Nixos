pragma Singleton

import QtQuick

QtObject {
    // Spatial motion
    readonly property int spatialOpenDuration: 340
    readonly property int spatialCloseDuration: 260

    readonly property int spatialOpenEasing: Easing.OutCubic
    readonly property int spatialCloseEasing: Easing.InCubic

    // Visual effects
    readonly property int effectsEnterDuration: 180
    readonly property int effectsExitDuration: 140
    readonly property int effectsEasing: Easing.OutQuad

    // Panel motion
    readonly property real panelEnterOffset: 8
}
