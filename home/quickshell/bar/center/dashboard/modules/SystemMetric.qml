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

        Text {
            width: parent.width

            text: root.detail

            color: Theme.textMuted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall

            renderType: Theme.textRenderType
            renderTypeQuality: Theme.textRenderQuality
            font.hintingPreference: Theme.fontHinting

            elide: Text.ElideRight
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
