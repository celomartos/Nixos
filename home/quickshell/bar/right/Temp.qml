import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property string temperature: "--°C"
    
    // Extrai o número da string (ex: "51°C" -> 51)
    readonly property int tempValue: parseInt(root.temperature) || 0

    // Função que decide a cor baseada na temperatura
    function getTempColor() {
        if (root.tempValue === 0) return Theme.textMuted; // Carregando/Erro
        if (root.tempValue >= 80) return Theme.textDanger; // Vermelho (Perigo)
        if (root.tempValue >= 65) return "#f9e2af";        // Amarelo (Alerta)
        return Theme.text;                                 // Branco (Normal)
    }

    Process {
        id: proc
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/tempinfo.sh"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.temperature = text.trim();
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }

    Component.onCompleted: {
        proc.running = true;
    }

    Component.onDestruction: {
        proc.running = false;
    }

    BarItem {
        id: barItem
        anchors.centerIn: parent
        clickable: false
        text: " " + root.temperature
        
        // Aplica a cor calculada pela função
        textColor: root.getTempColor() 
    }
}
