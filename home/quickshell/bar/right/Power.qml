import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: powerItem.implicitWidth

    BarItem {
        id: powerItem
        anchors.centerIn: parent
        clickable: true

        text: "󰐥"

        // --- AQUI ESTÁ O SEGREDO ---
        // Aumenta o ícone de energia em 4 pixels em relação ao resto da barra
        fontSize: Theme.fontSize + 2

        // (Se quiser um tamanho fixo, use apenas: fontSize: 20)

        onClicked: {
            powerMenu.toggle();
        }
    }

    PowerMenu {
        id: powerMenu
        anchorItem: powerItem
    }
}
