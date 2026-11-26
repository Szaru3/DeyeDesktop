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
        spacing: Theme.spacingSm

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.accentColor
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.title
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.Medium
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
                font.pixelSize: 28
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignBaseline
            }

            Text {
                visible: root.inlineSubtitle.length > 0
                text: root.inlineSubtitle
                color: Theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.Normal
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
            }
        }

        Item { Layout.fillHeight: true }

        // Shared footer slot keeping the battery bar's bottom padding and aligning labels to it
        Item {
            Layout.fillWidth: true
            implicitHeight: 16

            // Level bar for Battery SOC
            Rectangle {
                visible: root.showProgress
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 4
                radius: 2
                color: Theme.separator

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.progressValue / 100.0))
                    height: parent.height
                    radius: 2
                    color: root.accentColor

                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                visible: !root.showProgress && root.subtitle.length > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: root.subtitle
                color: Theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
