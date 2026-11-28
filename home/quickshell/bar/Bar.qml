import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "left"
import "center"
import "right"
import "center/dashboard"

PanelWindow {
    id: root

    // ============================================================
    // EXPANSION
    // ============================================================

    readonly property int collapsedHeight: Theme.barHeight + Theme.borderBottomWidth

    readonly property int dashboardHeight: 420

    property real expandedHeight: 0
    property real expandedWidth: 620
    property real expandedOffsetX: 0

    property Component expandedContent: dashboardComponent

    readonly property real effectiveExpandedHeight: Math.max(0, expandedHeight)

    readonly property real effectiveExpandedWidth: Math.min(width, Math.max(0, expandedWidth))

    readonly property int maxExpandedHeight: dashboardHeight

    readonly property real borderLeftEnd: root.width / 2 + (expansionHost.x - root.width / 2) * expansionHost.progress

    readonly property real borderRightStart: root.width / 2 + (expansionHost.x + expansionHost.width - root.width / 2) * expansionHost.progress

    property alias contentHost: expansionHost

    // Animated border geometry

    readonly property real borderGapHalfWidth: effectiveExpandedWidth * expansionHost.progress / 2

    readonly property real borderGapCenter: width / 2 + expandedOffsetX

    readonly property real borderGapLeft: Math.max(0, Math.min(width, borderGapCenter - borderGapHalfWidth))

    readonly property real borderGapRight: Math.max(0, Math.min(width, borderGapCenter + borderGapHalfWidth))

    // ============================================================
    // PANEL CONTROLS
    // ============================================================

    function openDashboard() {
        expandedContent = dashboardComponent;
        expandedWidth = 620;
        expandedHeight = dashboardHeight;
    }

    function closeExpandedPanel() {
        expandedHeight = 0;
    }

    function toggleDashboard() {
        if (expandedHeight > 0)
            closeExpandedPanel();
        else
            openDashboard();
    }

    function changeDashboardTab(direction) {
        const dashboard = expansionHost.loadedItem;

        if (dashboard)
            dashboard.changeTab(direction);
    }

    // ============================================================
    // WINDOW
    // ============================================================

    anchors {
        top: true
        left: true
        right: true
    }

    // Keep the actual window size stable.
    implicitHeight: collapsedHeight + maxExpandedHeight

    // Never reserve the expanded area.
    exclusiveZone: collapsedHeight

    focusable: expansionHost.progress > 0

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    // ============================================================
    // WINDOW MASK
    // ============================================================

    mask: Region {
        Region {
            item: barBackground
        }

        Region {
            item: expansionHost
        }
    }

    // ============================================================
    // BAR BACKGROUND
    // ============================================================

    Rectangle {
        id: barBackground

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: root.collapsedHeight

        color: Theme.background

        // --------------------------------------------------------
        // ANIMATED BOTTOM BORDER
        // --------------------------------------------------------

        Item {

          Item {
    id: bottomBorder

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    height: Theme.borderBottomWidth

    // LEFT BORDER

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        width: root.borderLeftEnd
        height: parent.height

        color: Theme.borderColor
    }

    // RIGHT BORDER

    Rectangle {
        anchors.bottom: parent.bottom

        x: root.borderRightStart

        width: parent.width - x
        height: parent.height

        color: Theme.borderColor
    }
}

        // --------------------------------------------------------
        // BAR CONTENT
        // --------------------------------------------------------

        Item {
            id: contentArea

            anchors.top: parent.top
            anchors.bottom: bottomBorder.top
            anchors.left: parent.left
            anchors.right: parent.right

            // LEFT

            Row {
                id: leftSection

                anchors.left: parent.left
                anchors.leftMargin: Theme.itemPaddingHorizontal
                anchors.verticalCenter: parent.verticalCenter

                spacing: Theme.itemSpacing

                Workspaces {}
                Cava {}
                NetworkSpeed {}
            }

            // CENTER

            Row {
                id: centerSection

                anchors.centerIn: parent

                spacing: Theme.itemSpacing

                Clock {
                    onDashboardToggleRequested: root.toggleDashboard()

                    onDashboardTabStepRequested: direction => {
                        root.changeDashboardTab(direction);
                    }
                }
            }

            // RIGHT

            Row {
                id: rightSection

                anchors.right: parent.right
                anchors.rightMargin: Theme.itemPaddingHorizontal
                anchors.verticalCenter: parent.verticalCenter

                spacing: Theme.itemSpacing

                Tray {}
                Audio {}
                Memory {}
                Cpu {}
                Temp {}
                Power {}
            }
        }
    }

    // ============================================================
    // EXPANDED CONTENT
    // ============================================================

    ExpandablePanel {
        id: expansionHost

        x: (root.width - width) / 2 + root.expandedOffsetX

        // Overlap the bottom border to connect both surfaces.
        y: Theme.barHeight

        width: root.effectiveExpandedWidth

        maximumHeight: root.maxExpandedHeight
        expandedHeight: root.effectiveExpandedHeight

        contentComponent: root.expandedContent
    }

    // ============================================================
    // DASHBOARD COMPONENT
    // ============================================================

    Component {
        id: dashboardComponent

        DashboardWindow {
            active: expansionHost.progress > 0

            onCloseRequested: {
                root.closeExpandedPanel();
            }
        }
    }
}
