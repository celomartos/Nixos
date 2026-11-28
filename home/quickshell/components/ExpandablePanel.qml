import QtQuick
import "../theme"

Item {
    id: root

    property Component contentComponent: null
    property real expandedHeight: 0
    property real maximumHeight: 420

    property real progress: 0

    property alias loadedItem: contentLoader.item

    height: maximumHeight * progress
    clip: true

    // ============================================================
    // SPATIAL ANIMATION
    // ============================================================

    function updateProgress() {
        progressAnimation.stop();
        progressAnimation.to = expandedHeight > 0 ? 1 : 0;
        progressAnimation.restart();
    }

    onExpandedHeightChanged: updateProgress()

    NumberAnimation {
        id: progressAnimation

        target: root
        property: "progress"

        duration: root.expandedHeight > 0 ? Animations.spatialOpenDuration : Animations.spatialCloseDuration

        easing.type: root.expandedHeight > 0 ? Animations.spatialOpenEasing : Animations.spatialCloseEasing
    }

    // ============================================================
    // CONTENT
    // ============================================================

    Loader {
        id: contentLoader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: root.maximumHeight

        active: root.contentComponent !== null && (root.expandedHeight > 0 || root.progress > 0)

        sourceComponent: root.contentComponent

        visible: root.progress > 0

        opacity: 1
    }
}
