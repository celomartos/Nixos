import QtQuick
import "../../../../theme"

Rectangle {
    id: root

    implicitHeight: 84

    property string icon: ""
    property string title: ""
    property string value: "--"
    property string detail: ""
    property real progress: 0

    // Disk I/O (optional)
    property string readRate: ""
    property string writeRate: ""

    readonly property bool hasIo: readRate.length > 0 || writeRate.length > 0

    radius: 12
    color: Qt.rgba(1, 1, 1, 0.035)
    border.color: Theme.borderColor
    border.width: 1

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        Row {
            id: heading

            width: parent.width
            spacing: 7

            Text {
                id: iconLabel

                text: root.icon
                color: Theme.textMuted

                font.family: Theme.fontFamily
                font.pixelSize: 16

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting
            }

            Text {
                id: titleLabel

                text: root.title
                color: Theme.textMuted

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting

                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Math.max(0, heading.width - iconLabel.width - titleLabel.implicitWidth - valueLabel.implicitWidth - heading.spacing * 3)

                height: 1
            }

            Text {
                id: valueLabel

                text: root.value
                color: Theme.text

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting
            }
        }

        // Detail and optional disk I/O
        Row {
            id: detailsRow

            width: parent.width
            spacing: 6

            Text {
                id: detailLabel

                width: root.hasIo ? Math.max(0, detailsRow.width - ioLabel.implicitWidth - detailsRow.spacing) : detailsRow.width

                text: root.detail
                color: Theme.textMuted

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting

                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: ioLabel

                visible: root.hasIo

                text: (root.readRate.length > 0 ? "R " + root.readRate : "") + (root.readRate.length > 0 && root.writeRate.length > 0 ? "  " : "") + (root.writeRate.length > 0 ? "W " + root.writeRate : "")

                color: Theme.textMuted

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting

                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: progressTrack

            width: parent.width
            height: 4

            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)

            Rectangle {
                width: progressTrack.width * Math.max(0, Math.min(100, root.progress)) / 100

                height: parent.height

                radius: 2
                color: Theme.text

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
