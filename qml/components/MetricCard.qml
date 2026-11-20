import QtQuick
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root

    property string title: ""
    property string valueText: "0 W"
    property string subtitle: ""
    property color accentColor: Theme.accent
    property bool showProgress: false
    property real progressValue: 0.0 // 0..100

    radius: Theme.radiusLg
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1
    implicitHeight: 132

    // Subtle top accent bar
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        radius: 2
        color: root.accentColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: root.accentColor
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

        Text {
            text: root.valueText
            color: Theme.textPrimary
            font.pixelSize: 28
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }

        // Optional SOC progress bar
        Rectangle {
            visible: root.showProgress
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.bgElevated

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progressValue / 100.0))
                height: parent.height
                radius: 3
                color: root.accentColor

                Behavior on width {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            text: root.subtitle
            color: Theme.textSecondary
            font.pixelSize: 12
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
