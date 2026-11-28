pragma Singleton
import QtQuick

QtObject {
    id: root

    // Durations are in milliseconds. `base` preserves the existing 100 ms
    // Theme.animDuration value while the named scale follows the Caelestia idea.
    readonly property QtObject durations: QtObject {
        readonly property int fast: 120
        readonly property int base: 100
        readonly property int normal: 180
        readonly property int slow: 280

        readonly property int expressiveFastSpatial: fast
        readonly property int expressiveDefaultSpatial: normal
        readonly property int expressiveSlowSpatial: slow
        readonly property int expressiveFastEffects: base
        readonly property int expressiveDefaultEffects: normal
        readonly property int expressiveSlowEffects: slow
    }

    // Cubic Bezier control points inspired by Caelestia's animation tokens.
    // Keep these as plain lists for compatibility with the Qt version shipped
    // by Quickshell; consumers can pass a list to easing.bezierCurve later.
    readonly property QtObject curves: QtObject {
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property var emphasized: [0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1]

        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]

        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
    }

    // Generic starting values for popup expansion, fade, scale and offset.
    // Components may use only the properties they need.
    readonly property QtObject popup: QtObject {
        readonly property int openDuration: root.durations.expressiveDefaultSpatial
        readonly property int closeDuration: root.durations.expressiveFastEffects
        readonly property var expansionCurve: root.curves.expressiveDefaultSpatial
        readonly property var opacityCurve: root.curves.expressiveFastEffects
        readonly property real initialScale: 0.96
        readonly property real initialOffset: 8
    }
}
