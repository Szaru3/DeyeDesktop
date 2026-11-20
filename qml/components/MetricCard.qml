import QtQuick
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root

    property string title: ""
    property string valueText: "0 W"
    property string inlineSubtitle: ""
    property string subtitle: ""
    property color accentColor: Theme.accent
    property bool showProgress: false
    property real progressValue: 0.0 // 0..100

    radius: Theme.radiusLg
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1
    implicitHeight: 128

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: root.accentColor
                }
            }

            Text {
                text: root.title
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.valueText
                color: Theme.textPrimary
                font.pixelSize: 26
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignBaseline
            }

            Text {
                visible: root.inlineSubtitle.length > 0
                text: root.inlineSubtitle
                color: Theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
            }
        }

        Item { Layout.fillHeight: true }

        // Level bar for Battery SOC
        Rectangle {
            visible: root.showProgress
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.bgInput

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progressValue / 100.0))
                height: parent.height
                radius: 3
                color: root.accentColor

                Behavior on width {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.textMuted
            font.pixelSize: 12
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
