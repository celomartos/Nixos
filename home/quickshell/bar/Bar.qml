import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "left"
import "center"
import "right"

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: screen ? screen.height : 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    exclusiveZone: Theme.barHeight + Theme.borderBottomWidth

    mask: Region {
        item: barBackground

        Region {
            item: dashboard.interactiveArea
        }
    }

    Rectangle {
        id: barBackground
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.barHeight + Theme.borderBottomWidth
        color: Theme.background

        // Borda inferior (2px solid rgba(255, 255, 255, 0.2))
        Rectangle {
            id: bottomBorder
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.borderBottomWidth
            color: Theme.borderColor
        }

        // Área útil dos módulos
        Item {
            id: contentArea
            anchors.top: parent.top
            anchors.bottom: bottomBorder.top
            anchors.left: parent.left
            anchors.right: parent.right

            // Seção Esquerda
            Row {
                id: leftSection
                anchors.left: parent.left
                // Margem externa para não colar na borda da tela
                anchors.leftMargin: Theme.itemPaddingHorizontal
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.itemSpacing // Espaçamento entre os módulos (6)

                Workspaces {}
                Cava {}
                NetworkSpeed {}
            }

            // Seção Centro
            Row {
                id: centerSection
                anchors.centerIn: parent
                spacing: Theme.itemSpacing

                Clock {
                    id: clock

                    onDashboardToggleRequested: dashboard.toggle()
                    onDashboardScrollRequested: direction => dashboard.changeTab(direction)
                }
            }

            // Seção Direita
            Row {
                id: rightSection
                anchors.right: parent.right
                // Margem externa para não colar na borda da tela
                anchors.rightMargin: Theme.itemPaddingHorizontal
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.itemSpacing // Espaçamento entre os módulos (6)

                Tray {}
                Audio {}
                Memory {}
                Cpu {}
                Temp {}
                Power {}
            }
        }

        // The bar and dashboard share a window, so the focus grab treats
        // other bar controls as part of its allowed surface. Observe bar taps
        // without taking their pointer events to dismiss the dashboard there.
        TapHandler {
            enabled: dashboard.isInteractive
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onTapped: eventPoint => {
                const clockPos = clock.clockItem.mapToItem(barBackground, 0, 0);
                const point = eventPoint.position;
                const inClock = point.x >= clockPos.x && point.x <= clockPos.x + clock.clockItem.width && point.y >= clockPos.y && point.y <= clockPos.y + clock.clockItem.height;
                if (!inClock)
                    dashboard.closePopup();
            }
        }
    }

    DashboardWindow {
        id: dashboard

        anchors.fill: parent
        originX: centerSection.x + clock.x + clock.clockItem.x + clock.clockItem.width / 2
        originY: centerSection.y + clock.y + clock.clockItem.y + clock.clockItem.height + Theme.borderBottomWidth
    }

    WlrLayershell.keyboardFocus: dashboard.isInteractive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
}
