import QtQuick
import "../theme"

Item {
    id: root

    // ============================================================
    // PROPERTIES
    // ============================================================

    property Component contentComponent: null
    property real expandedHeight: 0
    property alias loadedItem: contentLoader.item

    implicitHeight: height

    height: Math.max(0, expandedHeight)

    clip: true

    // ============================================================
    // ANIMATIONS
    // ============================================================

    Behavior on height {
        NumberAnimation {
            duration: Theme.animDurationSlow
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: Theme.animDurationNormal
            easing.type: Easing.OutCubic
        }
    }

    // ============================================================
    // CONTENT
    // ============================================================

    Loader {
        id: contentLoader

        anchors.fill: parent

        active: root.contentComponent !== null
        sourceComponent: root.contentComponent

        visible: root.height > 0

        opacity: root.expandedHeight > 0 ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDurationNormal
                easing.type: Easing.OutQuad
            }
        }

        transform: Translate {
            y: root.expandedHeight > 0 ? 0 : -12

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animDurationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
