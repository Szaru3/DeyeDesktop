import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Header Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            color: Theme.bgSurface

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                // Brand
                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 7
                        color: Theme.solarSoft
                        border.color: Theme.solar
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "☀"
                            color: Theme.solar
                            font.pixelSize: 14
                        }
                    }
                    Text {
                        text: "DeyeDesktop"
                        color: Theme.textPrimary
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                }

                // Demo Badge
                Rectangle {
                    visible: appController.demoMode
                    implicitWidth: demoLbl.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: Theme.solarSoft
                    border.color: Theme.solar
                    Text {
                        id: demoLbl
                        anchors.centerIn: parent
                        text: "DEMO"
                        color: Theme.solar
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Station Selector
                ComboBox {
                    id: stationCombo
                    Layout.preferredWidth: 260
                    Layout.maximumWidth: 340
                    implicitHeight: 36
                    model: appController.stationModel
                    textRole: "name"
                    currentIndex: appController.selectedStationIndex
                    onActivated: function(idx) {
                        appController.selectStationByIndex(idx)
                    }

                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 28
                        text: stationCombo.displayText || "Select station..."
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: Theme.bgInput
                        border.color: stationCombo.activeFocus ? Theme.borderFocus : Theme.border
                    }

                    popup: Popup {
                        y: stationCombo.height + 4
                        width: stationCombo.width
                        implicitHeight: contentItem.implicitHeight + 8
                        padding: 4
                        background: Rectangle {
                            color: Theme.bgElevated
                            border.color: Theme.border
                            radius: Theme.radiusSm
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: stationCombo.popup.visible ? stationCombo.delegateModel : null
                        }
                    }

                    delegate: ItemDelegate {
                        width: stationCombo.width - 8
                        contentItem: Text {
                            text: model.name
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 4
                            color: highlighted ? Theme.bgSurface : "transparent"
                        }
                        highlighted: stationCombo.highlightedIndex === index
                    }
                }

                StatusBadge {
                    status: appController.connectionStatus
                }

                Item { Layout.fillWidth: true }

                // Auto-Refresh Toggle
                CheckBox {
                    id: autoRefreshBox
                    checked: appController.autoRefreshEnabled
                    text: "Auto (" + appController.refreshIntervalSec + "s)"
                    onToggled: appController.autoRefreshEnabled = checked

                    contentItem: Text {
                        leftPadding: autoRefreshBox.indicator.width + 6
                        text: autoRefreshBox.text
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        y: (parent.height - height) / 2
                        radius: 4
                        color: autoRefreshBox.checked ? Theme.accent : Theme.bgInput
                        border.color: autoRefreshBox.checked ? Theme.accent : Theme.border
                        Text {
                            anchors.centerIn: parent
                            visible: autoRefreshBox.checked
                            text: "✓"
                            color: Theme.bgPrimary
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }
                }

                // Refresh Button
                Button {
                    implicitHeight: 34
                    implicitWidth: 96
                    enabled: !appController.busy
                    onClicked: appController.refreshDashboard()

                    contentItem: Text {
                        text: appController.busy ? "Updating..." : "Refresh"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: parent.hovered ? Theme.bgElevated : Theme.bgInput
                        border.color: Theme.border
                    }
                }

                // Logout Button
                Button {
                    implicitHeight: 34
                    implicitWidth: 80
                    onClicked: appController.logout()

                    contentItem: Text {
                        text: "Sign Out"
                        color: "#FDA4AF"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: parent.hovered ? Theme.errorSoft : "transparent"
                        border.color: Theme.border
                    }
                }
            }
        }

        // Scrollable Dashboard Body
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight + 40
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 18

                // Error Banner (if polling fails)
                Rectangle {
                    visible: appController.errorMessage.length > 0
                    Layout.fillWidth: true
                    implicitHeight: dashErr.implicitHeight + 18
                    radius: Theme.radiusSm
                    color: Theme.errorSoft
                    border.color: Theme.error

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        Text {
                            id: dashErr
                            Layout.fillWidth: true
                            text: appController.errorMessage
                            color: "#FDA4AF"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Button {
                            text: "Dismiss"
                            implicitHeight: 24
                            onClicked: appController.clearError()
                            contentItem: Text {
                                text: parent.text
                                color: "#FDA4AF"
                                font.pixelSize: 11
                            }
                            background: Rectangle {
                                radius: 4
                                color: "transparent"
                                border.color: Theme.error
                            }
                        }
                    }
                }

                // Station Summary Strip
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: appController.selectedStationName || "No Station Selected"
                            color: Theme.textPrimary
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                        Text {
                            text: {
                                var parts = [];
                                if (appController.installedCapacityKw > 0)
                                    parts.push("Installed: " + appController.installedCapacityKw.toFixed(1) + " kWp");
                                if (appController.selectedStationLocation.length > 0)
                                    parts.push(appController.selectedStationLocation);
                                return parts.length > 0 ? parts.join("  •  ") : "Real-time station overview";
                            }
                            color: Theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Last updated: " + appController.lastUpdateText
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                // Live Power Flow Diagram
                PowerFlowDiagram {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 310
                    generationPowerW: appController.generationPowerW
                    consumptionPowerW: appController.consumptionPowerW
                    batteryPowerW: appController.batteryPowerW
                    batterySoc: appController.batterySoc
                    hasBatterySoc: appController.hasBatterySoc
                    gridPowerW: appController.gridPowerW
                }

                // 4 KPI Metric Cards
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 880 ? 4 : 2
                    columnSpacing: 14
                    rowSpacing: 14

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Solar Generation"
                        valueText: appController.formatPower(appController.generationPowerW)
                        subtitle: appController.generationPowerW > 10 ? "Producing solar power" : "Standby / Night"
                        accentColor: Theme.solar
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Battery"
                        valueText: appController.hasBatterySoc
                                   ? (Math.round(appController.batterySoc) + "%")
                                   : appController.formatPower(appController.batteryPowerW)
                        subtitle: {
                            var p = appController.formatPower(appController.batteryPowerW);
                            if (appController.batteryPowerW > 10) return "Charging at " + p;
                            if (appController.batteryPowerW < -10) return "Discharging at " + p;
                            return "Idle";
                        }
                        accentColor: Theme.battery
                        showProgress: appController.hasBatterySoc
                        progressValue: appController.batterySoc
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Grid"
                        valueText: appController.formatPower(appController.gridPowerW)
                        subtitle: appController.gridPowerW > 10 ? "Importing from grid"
                                : appController.gridPowerW < -10 ? "Exporting to grid"
                                : "Zero export / Balanced"
                        accentColor: Theme.grid
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Home Load"
                        valueText: appController.formatPower(appController.consumptionPowerW)
                        subtitle: "Current household consumption"
                        accentColor: Theme.load
                    }
                }
            }
        }
    }
}
