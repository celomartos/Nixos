import QtQuick
import Quickshell.Services.Mpris
import QtQuick.Effects
import "../../../../theme"
import "../../../../services"

Item {
    id: root

    // ============================================================
    // PLAYER SELECTION
    // ============================================================

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;

        // Prioritize players currently playing.
        for (let i = 0; i < players.length; i++) {
            const player = players[i];

            if (player.playbackState === MprisPlaybackState.Playing)
                return player;
        }

        // Otherwise, use a controllable paused player.
        for (let i = 0; i < players.length; i++) {
            const player = players[i];

            if (player.playbackState === MprisPlaybackState.Paused && player.canControl) {
                return player;
            }
        }

        // Ignore stopped or stale sessions.
        return null;
    }

    readonly property bool hasPlayer: activePlayer !== null

    readonly property bool isPlaying: hasPlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    // ============================================================
    // PLAYER CAPABILITIES
    // ============================================================

    readonly property bool canToggle: hasPlayer && activePlayer.canTogglePlaying

    readonly property bool canGoPrevious: hasPlayer && activePlayer.canGoPrevious

    readonly property bool canGoNext: hasPlayer && activePlayer.canGoNext

    readonly property bool canSeek: hasPlayer && activePlayer.canSeek && activePlayer.positionSupported && activePlayer.lengthSupported

    // ============================================================
    // TRACK INFORMATION
    // ============================================================

    readonly property string playerName: hasPlayer ? (activePlayer.identity || "Media Player") : ""

    readonly property string trackTitle: hasPlayer ? (activePlayer.trackTitle || "Unknown Title") : ""

    readonly property string trackArtist: hasPlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""

    readonly property string trackAlbum: hasPlayer ? activePlayer.trackAlbum : ""

    readonly property string artworkUrl: hasPlayer ? activePlayer.trackArtUrl : ""

    // ============================================================
    // PLAYBACK POSITION
    // ============================================================

    readonly property bool hasProgress: hasPlayer && activePlayer.lengthSupported && activePlayer.positionSupported && activePlayer.length > 0

    readonly property real trackLength: hasProgress ? activePlayer.length : 0

    readonly property real currentPosition: hasProgress ? Math.max(0, Math.min(activePlayer.position, trackLength)) : 0

    readonly property real progress: trackLength > 0 ? currentPosition / trackLength : 0

    function formatTime(value) {
        const total = Math.max(0, Math.floor(Number(value) || 0));
        const minutes = Math.floor(total / 60);
        const seconds = total % 60;

        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function seekTo(mouseX, areaWidth) {
        if (!root.canSeek || areaWidth <= 0)
            return;

        const ratio = Math.max(0, Math.min(1, mouseX / areaWidth));

        const targetPosition = root.trackLength * ratio;
        const player = root.activePlayer;

        player.seek(targetPosition - root.currentPosition);
        player.positionChanged();
    }

    // ============================================================
    // POSITION REFRESH
    // ============================================================

    Timer {
        interval: 1000
        repeat: true

        running: root.visible && root.isPlaying && root.hasProgress

        onTriggered: {
            const player = root.activePlayer;

            if (player && player.playbackState === MprisPlaybackState.Playing && player.positionSupported) {
                player.positionChanged();
            }
        }
    }

    // ============================================================
    // MEDIA CONTENT
    // ============================================================

    Column {
        anchors.fill: parent
        anchors.margins: 8

        spacing: 18

        visible: root.hasPlayer

        // --------------------------------------------------------
        // ARTWORK AND TRACK INFORMATION
        // --------------------------------------------------------

        Row {
            id: trackInfo

            width: parent.width
            height: 178

            spacing: 20

            // Album artwork and circular visualizer
            Item {
                id: albumVisual

                width: 178
                height: 178

                // ------------------------------------------------
                // CAVA VISUALIZER
                // ------------------------------------------------

                Repeater {
                    model: CavaService.barCount

                    delegate: Rectangle {
                        required property int index

                        readonly property real angleDegrees: index * 360 / CavaService.barCount

                        readonly property real angleRadians: angleDegrees * Math.PI / 180

                        readonly property real level: Math.max(0, Math.min(7, CavaService.levels[index] || 0))

                        width: 3

                        height: 5 + level * 2

                        // Position each bar around the artwork.
                        x: albumVisual.width / 2 + Math.cos(angleRadians) * (artwork.width / 2 + 4 + height / 2) - width / 2

                        y: albumVisual.height / 2 + Math.sin(angleRadians) * (artwork.height / 2 + 4 + height / 2) - height / 2

                        // Rotate bars to follow the circular shape.
                        rotation: angleDegrees + 90

                        radius: width / 2

                        color: Theme.text

                        opacity: root.isPlaying ? 0.35 + (level / 7) * 0.65 : 0

                        antialiasing: true

                        Behavior on height {
                            NumberAnimation {
                                duration: 90
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                // ------------------------------------------------
                // CIRCULAR ALBUM ARTWORK
                // ------------------------------------------------

                Rectangle {
                    id: artwork

                    width: 140
                    height: 140

                    anchors.centerIn: parent

                    radius: width / 2
                    clip: true

                    color: Theme.hoverBackground

                    // Original image
                    Image {
                        id: coverArt

                        anchors.fill: parent

                        source: root.artworkUrl

                        asynchronous: true
                        cache: true

                        fillMode: Image.PreserveAspectCrop

                        visible: false
                    }

                    // Rounded image
                    MultiEffect {
                        anchors.fill: coverArt

                        source: coverArt

                        maskEnabled: true
                        maskSource: coverMask

                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0

                        visible: coverArt.status === Image.Ready
                    }

                    // Rounded mask
                    Item {
                        id: coverMask

                        width: coverArt.width
                        height: coverArt.height

                        layer.enabled: true
                        layer.samples: 16

                        visible: false

                        Rectangle {
                            anchors.fill: parent

                            radius: artwork.radius
                            color: "white"
                        }
                    }

                    // Fallback icon
                    Text {
                        anchors.centerIn: parent

                        visible: coverArt.status !== Image.Ready

                        text: "󰝚"

                        color: Theme.textMuted

                        font.family: Theme.fontFamily
                        font.pixelSize: 48
                    }
                }
            }

            // ----------------------------------------------------
            // TRACK METADATA
            // ----------------------------------------------------

            Column {
                anchors.verticalCenter: parent.verticalCenter

                width: parent.width - albumVisual.width - trackInfo.spacing

                spacing: 9

                Text {
                    width: parent.width

                    text: root.playerName

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text: root.trackTitle

                    color: Theme.text

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold

                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text: root.trackArtist

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    visible: root.trackAlbum.length > 0

                    text: root.trackAlbum

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    elide: Text.ElideRight
                }
            }
        }

        // --------------------------------------------------------
        // PLAYBACK PROGRESS
        // --------------------------------------------------------

        Column {
            width: parent.width

            spacing: 7

            visible: root.hasProgress

            Row {
                width: parent.width

                Text {
                    width: parent.width / 2

                    text: root.formatTime(root.currentPosition)

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Text {
                    width: parent.width / 2

                    text: root.formatTime(root.trackLength)

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle {
                id: progressTrack

                width: parent.width
                height: 6

                radius: 3

                color: Theme.hoverBackground

                Rectangle {
                    width: progressTrack.width * root.progress
                    height: parent.height

                    radius: 3

                    color: Theme.text

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: root.canSeek

                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: mouse => {
                        root.seekTo(mouse.x, width);
                    }
                }
            }
        }

        // --------------------------------------------------------
        // PLAYBACK CONTROLS
        // --------------------------------------------------------

        Item {
            width: parent.width
            height: 54

            Row {
                anchors.centerIn: parent

                spacing: 22

                // Previous
                Rectangle {
                    width: 46
                    height: 46

                    radius: 23

                    anchors.verticalCenter: parent.verticalCenter

                    color: previousMouse.containsMouse ? Theme.hoverBackground : "transparent"

                    opacity: root.canGoPrevious ? 1 : 0.35

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "󰒮"

                        color: Theme.text

                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        enabled: root.canGoPrevious

                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            if (root.canGoPrevious)
                                root.activePlayer.previous();
                        }
                    }
                }

                // Play / Pause
                Rectangle {
                    width: 54
                    height: 54

                    radius: 27

                    color: Theme.text

                    opacity: root.canToggle ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent

                        text: root.isPlaying ? "󰏤" : "󰐊"

                        color: Theme.background

                        font.family: Theme.fontFamily
                        font.pixelSize: 27
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: root.canToggle

                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            if (root.canToggle)
                                root.activePlayer.togglePlaying();
                        }
                    }
                }

                // Next
                Rectangle {
                    width: 46
                    height: 46

                    radius: 23

                    anchors.verticalCenter: parent.verticalCenter

                    color: nextMouse.containsMouse ? Theme.hoverBackground : "transparent"

                    opacity: root.canGoNext ? 1 : 0.35

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "󰒭"

                        color: Theme.text

                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        enabled: root.canGoNext

                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            if (root.canGoNext)
                                root.activePlayer.next();
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // EMPTY STATE
    // ============================================================

    Column {
        anchors.centerIn: parent

        spacing: 10

        visible: !root.hasPlayer

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: "󰝚"

            color: Theme.textMuted

            font.family: Theme.fontFamily
            font.pixelSize: 42
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: "No media player detected"

            color: Theme.text

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: "Start playback in a compatible application."

            color: Theme.textMuted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
