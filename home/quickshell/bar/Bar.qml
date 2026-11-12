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
    implicitHeight: Theme.barHeight + Theme.borderBottomWidth
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-bar"
    exclusionMode: ExclusionMode.Auto

    Rectangle {
        id: barBackground
        anchors.fill: parent
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

                Clock {}
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
    }
}
