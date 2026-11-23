import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../theme"

Item {
    id: root

    // ------------------------------------------------------------
    // State
    // ------------------------------------------------------------

    property bool pageActive: false

    // monitorWanted: usuário quer o monitor rodando (com debounce na saída
    // para evitar flash ao alternar abas).
    // monitorEnabled: backoff — desligado enquanto o script falha em loop.
    property bool monitorWanted: false
    property bool monitorEnabled: true
    property int consecutiveFailures: 0

    property var stats: ({
            cpu_usage: null,
            cpu_temp: null,
            memory_used: null,
            memory_total: null,
            memory_percent: null,
            gpu_usage: null,
            gpu_temp: null,
            storage_used: null,
            storage_total: null,
            storage_percent: null,
            disk_read: 0,
            disk_write: 0,
            network_down: 0,
            network_up: 0,
            network_connected: false
        })

    readonly property string scriptsDirectory: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts"

    // ------------------------------------------------------------
    // Page lifecycle
    // ------------------------------------------------------------

    onPageActiveChanged: {
        if (pageActive) {
            killTimer.stop();
            monitorWanted = true;
            consecutiveFailures = 0;
            monitorEnabled = true;
        } else {
            // Espera um pouco antes de matar: se o usuário voltar
            // rápido (navegação com setas), o script continua vivo
            // e o card não pisca.
            killTimer.restart();
        }
    }

    Timer {
        id: killTimer
        interval: 800
        repeat: false
        onTriggered: if (!root.pageActive)
            root.monitorWanted = false
    }

    // ------------------------------------------------------------
    // Formatting
    // ------------------------------------------------------------

    function formatPercent(value) {
        if (value === null || value === undefined)
            return "--";

        const n = Number(value);
        if (!Number.isFinite(n))
            return "--";

        return Math.round(n) + "%";
    }

    function formatTemperature(value) {
        if (value === null || value === undefined)
            return "--";

        const n = Number(value);
        if (!Number.isFinite(n))
            return "--";

        return Math.round(n) + "°C";
    }

    function formatBytes(value) {
        if (value === null || value === undefined)
            return "--";

        const n = Number(value);
        if (!Number.isFinite(n))
            return "--";

        return (n / 1073741824).toFixed(1) + " GB";
    }

    function formatRate(value) {
        const n = Number(value);
        if (!Number.isFinite(n) || n < 0)
            return "0 B/s";

        if (n >= 1048576)
            return (n / 1048576).toFixed(1) + " MB/s";

        if (n >= 1024)
            return (n / 1024).toFixed(0) + " KB/s";

        return Math.round(n) + " B/s";
    }

    // ------------------------------------------------------------
    // System monitor process
    // ------------------------------------------------------------

    Process {
        id: monitor

        command: ["bash", root.scriptsDirectory + "/system-monitor.sh"]
        running: root.monitorWanted && root.monitorEnabled

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const line = data.trim();
                if (!line.length)
                    return;

                try {
                    root.stats = JSON.parse(line);
                    root.consecutiveFailures = 0;
                } catch (error) {
                    console.warn("[System] Invalid monitor data:", error);
                }
            }
        }

        onExited: {
            if (!root.monitorWanted)
                return;

            // Saída inesperada: backoff exponencial até 30s.
            root.consecutiveFailures++;
            root.monitorEnabled = false;

            const delay = Math.min(30000, 1500 * Math.pow(2, root.consecutiveFailures - 1));
            restartTimer.interval = delay;
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        repeat: false

        onTriggered: {
            if (root.monitorWanted)
                root.monitorEnabled = true;
        }
    }

    // ------------------------------------------------------------
    // Dashboard layout
    // ------------------------------------------------------------

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 10

        // CPU and RAM
        Row {
            id: topRow
            width: parent.width
            height: 84
            spacing: 10

            SystemMetric {
                width: (topRow.width - topRow.spacing) / 2
                height: topRow.height
                icon: ""
                title: "CPU"
                value: root.formatPercent(root.stats.cpu_usage)
                detail: "Temperature · " + root.formatTemperature(root.stats.cpu_temp)
                progress: Number(root.stats.cpu_usage) || 0
            }

            SystemMetric {
                width: (topRow.width - topRow.spacing) / 2
                height: topRow.height
                icon: ""
                title: "Memory"
                value: root.formatBytes(root.stats.memory_used) + " / " + root.formatBytes(root.stats.memory_total)
                detail: root.formatPercent(root.stats.memory_percent) + " used"
                progress: Number(root.stats.memory_percent) || 0
            }
        }

        // GPU and storage
        Row {
            id: middleRow
            width: parent.width
            height: 84
            spacing: 10

            SystemMetric {
                width: (middleRow.width - middleRow.spacing) / 2
                height: middleRow.height
                icon: "󰢮"
                title: "GPU"
                value: root.formatPercent(root.stats.gpu_usage)
                detail: "Temperature · " + root.formatTemperature(root.stats.gpu_temp)
                progress: Number(root.stats.gpu_usage) || 0
            }

            SystemMetric {
                width: (middleRow.width - middleRow.spacing) / 2
                height: middleRow.height
                icon: "󰋊"
                title: "Storage"
                value: root.formatBytes(root.stats.storage_used) + " / " + root.formatBytes(root.stats.storage_total)
                detail: root.formatPercent(root.stats.storage_percent) + " used"
                readRate: root.formatRate(root.stats.disk_read)
                writeRate: root.formatRate(root.stats.disk_write)
                progress: Number(root.stats.storage_percent) || 0
            }
        }

        // Network
        Rectangle {
            id: networkCard

            width: parent.width
            implicitHeight: networkContent.implicitHeight + 24

            radius: 12
            color: Theme.cardBackground
            border.color: Theme.borderColor
            border.width: 1

            Column {
                id: networkContent

                anchors.fill: parent
                anchors.margins: 12

                spacing: 5

                // Header
                Row {
                    id: networkHeader
                    width: parent.width
                    spacing: 7

                    Text {
                        id: networkIcon
                        text: "󰖩"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    Text {
                        id: networkTitle
                        text: "Network"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    Item {
                        width: Math.max(0, networkHeader.width - networkIcon.implicitWidth - networkTitle.implicitWidth - networkStatus.implicitWidth - networkHeader.spacing * 3)
                        height: 1
                    }

                    Text {
                        id: networkStatus
                        text: root.stats.network_connected ? "Connected" : "Offline"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        renderType: Theme.textRenderType
                        renderTypeQuality: Theme.textRenderQuality
                        font.hintingPreference: Theme.fontHinting
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Download and upload
                Row {
                    width: parent.width
                    spacing: 16

                    // Download
                    Column {
                        width: (parent.width - parent.spacing) / 2
                        spacing: 1

                        Row {
                            spacing: 5

                            Text {
                                text: "↓"
                                color: Theme.text
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                text: "Download"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        Text {
                            text: root.stats.network_connected ? root.formatRate(root.stats.network_down) : "--"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.DemiBold
                            renderType: Theme.textRenderType
                            renderTypeQuality: Theme.textRenderQuality
                            font.hintingPreference: Theme.fontHinting
                        }
                    }

                    // Upload
                    Column {
                        width: (parent.width - parent.spacing) / 2
                        spacing: 1

                        Row {
                            spacing: 5

                            Text {
                                text: "↑"
                                color: Theme.text
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                text: "Upload"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        Text {
                            text: root.stats.network_connected ? root.formatRate(root.stats.network_up) : "--"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.DemiBold
                            renderType: Theme.textRenderType
                            renderTypeQuality: Theme.textRenderQuality
                            font.hintingPreference: Theme.fontHinting
                        }
                    }
                }
            }
        }
    }
}
