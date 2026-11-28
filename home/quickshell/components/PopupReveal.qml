import QtQuick
import "../theme"

Item {
    id: root

    default property alias content: contentHost.data

    property bool expanded: false
    property real originX: 0
    property real originY: 0
    property real contentWidth: 0
    property real contentHeight: 0

    property int openDuration: Animations.popup.openDuration
    property int closeDuration: Animations.popup.closeDuration
    property var expansionCurve: Animations.popup.expansionCurve
    property var opacityCurve: Animations.popup.opacityCurve
    property real initialScale: Animations.popup.initialScale
    property real initialOffset: Animations.popup.initialOffset

    property real progress: 0
    property real opacityProgress: 0

    signal closed

    x: originX - width / 2
    y: originY
    width: implicitWidth
    height: implicitHeight
    implicitWidth: contentWidth * progress
    implicitHeight: contentHeight * progress
    clip: true
    visible: expanded || progress > 0 || opacityProgress > 0

    onExpandedChanged: {
        transition.restart();
    }

    ParallelAnimation {
        id: transition

        NumberAnimation {
            target: root
            property: "progress"
            from: root.progress
            to: root.expanded ? 1 : 0
            duration: root.expanded ? root.openDuration : root.closeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.expansionCurve
        }

        NumberAnimation {
            target: root
            property: "opacityProgress"
            from: root.opacityProgress
            to: root.expanded ? 1 : 0
            duration: root.expanded ? root.openDuration : root.closeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.opacityCurve
        }

        onFinished: {
            if (!root.expanded)
                root.closed();
        }
    }

    Item {
        id: contentHost

        anchors.fill: parent
        opacity: root.opacityProgress
        scale: root.initialScale + (1 - root.initialScale) * root.progress
        transformOrigin: Item.Top

        transform: Translate {
            y: root.initialOffset * (1 - root.progress)
        }
    }
}
