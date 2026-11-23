pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int barCount: 32

    // Current audio levels (0–7).
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property string scriptsDirectory: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts"

    Process {
        id: cavaProcess

        command: ["bash", root.scriptsDirectory + "/cava.sh"]

        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const line = data.trim();

                if (!line)
                    return;

                const values = line.split(";");
                const nextLevels = [];

                for (let i = 0; i < root.barCount; i++) {
                    const value = Number(values[i]);

                    nextLevels.push(Number.isFinite(value) ? Math.max(0, Math.min(7, value)) : 0);
                }

                // Replace the array to notify all consumers.
                root.levels = nextLevels;
            }
        }

        onExited: {
            restartTimer.start();
        }
    }

    // Recover automatically if Cava exits unexpectedly.
    Timer {
        id: restartTimer

        interval: 2000
        repeat: false

        onTriggered: {
            if (!cavaProcess.running)
                cavaProcess.running = true;
        }
    }
}
