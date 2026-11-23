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
    property bool monitorEnabled: true

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
        restartTimer.stop();

        if (pageActive)
            monitorEnabled = true;
    }

    // ------------------------------------------------------------
    // Formatting
    // ------------------------------------------------------------

    function formatPercent(value) {
        if (value === null || value === undefined)
            return "--";

        return Math.round(value) + "%";
    }

    function formatTemperature(value) {
        if (value === null || value === undefined)
            return "--";

        return Math.round(value) + "°C";
    }

    function formatBytes(value) {
        if (value === null || value === undefined)
            return "--";

        return (Number(value) / 1073741824).toFixed(1) + " GB";
    }

    function formatRate(value) {
        const bytes = Number(value) || 0;

        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(1) + " MB/s";

        if (bytes >= 1024)
            return (bytes / 1024).toFixed(0) + " KB/s";

        return Math.round(bytes) + " B/s";
    }

    // ------------------------------------------------------------
    // System monitor process
    // ------------------------------------------------------------

    Process {
        id: monitor

        command: ["bash", root.scriptsDirectory + "/system-monitor.sh"]

        running: root.pageActive && root.monitorEnabled

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const line = data.trim();

                if (!line.length)
                    return;
                try {
                    root.stats = JSON.parse(line);
                } catch (error) {
                    console.warn("[System] Invalid monitor data:", error);
                }
            }
        }

        onExited: {
            if (root.pageActive) {
                root.monitorEnabled = false;
                restartTimer.start();
            }
        }
    }

    // ------------------------------------------------------------
    // Process recovery
    // ------------------------------------------------------------

    Timer {
        id: restartTimer

        interval: 1500
        repeat: false

        onTriggered: {
            if (root.pageActive)
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

                icon: ""
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
            height: 82

            radius: 12
            color: Qt.rgba(1, 1, 1, 0.035)
            border.color: Theme.borderColor
            border.width: 1

            Column {
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
