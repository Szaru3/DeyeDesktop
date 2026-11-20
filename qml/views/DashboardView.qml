import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    component AdwSwitch: Switch {
        id: sw
        implicitWidth: 40
        implicitHeight: 22
        indicator: Rectangle {
            implicitWidth: 40
            implicitHeight: 22
            radius: 11
            color: sw.checked ? Theme.accent : "#4D4D4D"
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                x: sw.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: 8
                color: "#FFFFFF"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // AdwHeaderBar-style Top Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            color: Theme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.separator
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                // Brand
                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 7
                        color: Theme.solarSoft
                        border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.5)
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "☀"
                            color: Theme.solar
                            font.pixelSize: 13
                        }
                    }
                    Text {
                        text: "DeyeDesktop"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                }

                // Demo Pill
                Rectangle {
                    visible: appController.demoMode
                    implicitWidth: demoLbl.implicitWidth + 12
                    implicitHeight: 20
                    radius: Theme.radiusPill
                    color: Theme.solarSoft
                    border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.5)
                    Text {
                        id: demoLbl
                        anchors.centerIn: parent
                        text: "DEMO"
                        color: Theme.solar
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Plant / Station Selector (shows plant name + address in menu)
                ComboBox {
                    id: stationCombo
                    Layout.preferredWidth: 280
                    Layout.maximumWidth: 360
                    implicitHeight: 36
                    model: appController.stationModel
                    textRole: "name"
                    currentIndex: appController.selectedStationIndex
                    onActivated: function(idx) {
                        appController.selectStationByIndex(idx)
                    }

                    contentItem: Column {
                        leftPadding: 10
                        rightPadding: 26
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: stationCombo.width - 36
                            text: stationCombo.displayText || "Select plant..."
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: appController.selectedStationLocation.length > 0
                            width: stationCombo.width - 36
                            text: appController.selectedStationLocation
                            color: Theme.textMuted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: stationCombo.hovered ? Theme.bgButtonHover : Theme.bgButton
                        border.color: stationCombo.activeFocus ? Theme.borderFocus : "transparent"
                        border.width: 1
                    }

                    popup: Popup {
                        y: stationCombo.height + 6
                        width: Math.max(stationCombo.width, 340)
                        implicitHeight: Math.min(360, contentItem.implicitHeight + 12)
                        padding: 6
                        background: Rectangle {
                            color: Theme.bgElevated
                            border.color: Theme.border
                            border.width: 1
                            radius: Theme.radiusLg
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            spacing: 2
                            model: stationCombo.popup.visible ? stationCombo.delegateModel : null
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        }
                    }

                    delegate: ItemDelegate {
                        id: plantDelegate
                        width: ListView.view ? ListView.view.width : 328
                        implicitHeight: model.location && model.location.length > 0 ? 52 : 38
                        highlighted: stationCombo.highlightedIndex === index

                        readonly property color dotColor: (model.connectionStatus === "NORMAL" || model.connectionStatus === "ONLINE")
                                                          ? Theme.success
                                                          : (model.connectionStatus === "PARTIAL_OFFLINE")
                                                            ? Theme.warning
                                                            : (model.connectionStatus === "ALL_OFFLINE" || model.connectionStatus === "OFFLINE")
                                                              ? Theme.errorText
                                                              : Theme.textMuted

                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: plantDelegate.highlighted ? Theme.bgButtonHover
                                 : (stationCombo.currentIndex === index ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent")
                        }

                        contentItem: RowLayout {
                            spacing: 10

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: plantDelegate.dotColor
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: model.name
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    font.weight: stationCombo.currentIndex === index ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: model.location && model.location.length > 0
                                    text: model.location
                                    color: Theme.textSecondary
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: model.installedCapacityKw > 0
                                text: model.installedCapacityKw.toFixed(1) + " kWp"
                                color: Theme.textMuted
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                StatusBadge {
                    status: appController.connectionStatus
                }

                Item { Layout.fillWidth: true }

                // Auto-Refresh Switch
                RowLayout {
                    spacing: 8
                    Text {
                        text: "Auto (" + appController.refreshIntervalSec + "s)"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                    AdwSwitch {
                        checked: appController.autoRefreshEnabled
                        onToggled: appController.autoRefreshEnabled = checked
                    }
                }

                // Flat Adwaita Header Button: Refresh
                Button {
                    implicitHeight: 34
                    implicitWidth: 88
                    enabled: !appController.busy
                    onClicked: appController.refreshDashboard()

                    contentItem: Text {
                        text: appController.busy ? "Updating…" : "Refresh"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: parent.hovered ? Theme.bgButtonHover : Theme.bgButton
                    }
                }

                // Flat Adwaita Header Button: Sign Out
                Button {
                    implicitHeight: 34
                    implicitWidth: 78
                    onClicked: appController.logout()

                    contentItem: Text {
                        text: "Sign Out"
                        color: Theme.errorText
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: parent.hovered ? Theme.errorSoft : "transparent"
                    }
                }
            }
        }

        // Scrollable AdwClamp Dashboard Body
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight + 48
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyColumn
                width: Math.min(980, parent.width - 40)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                spacing: 16

                // Error Banner
                Rectangle {
                    visible: appController.errorMessage.length > 0
                    Layout.fillWidth: true
                    implicitHeight: dashErr.implicitHeight + 18
                    radius: Theme.radiusMd
                    color: Theme.errorSoft
                    border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.6)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        Text {
                            id: dashErr
                            Layout.fillWidth: true
                            text: appController.errorMessage
                            color: Theme.errorText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Button {
                            text: "Dismiss"
                            implicitHeight: 26
                            onClicked: appController.clearError()
                            contentItem: Text {
                                text: parent.text
                                color: Theme.errorText
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: parent.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25) : "transparent"
                            }
                        }
                    }
                }

                // Station Summary Strip
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: appController.selectedStationName || "No Plant Selected"
                            color: Theme.textPrimary
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                        Text {
                            text: {
                                var parts = [];
                                if (appController.installedCapacityKw > 0)
                                    parts.push(appController.installedCapacityKw.toFixed(1) + " kWp");
                                if (appController.selectedStationLocation.length > 0)
                                    parts.push(appController.selectedStationLocation);
                                return parts.length > 0 ? parts.join("  •  ") : "Real-time plant overview";
                            }
                            color: Theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Updated " + appController.lastUpdateText
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                // Live Power Flow Card
                PowerFlowDiagram {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    generationPowerW: appController.generationPowerW
                    consumptionPowerW: appController.consumptionPowerW
                    batteryPowerW: appController.batteryPowerW
                    batterySoc: appController.batterySoc
                    hasBatterySoc: appController.hasBatterySoc
                    gridPowerW: appController.gridPowerW
                }

                // 4 KPI Cards
                GridLayout {
                    Layout.fillWidth: true
                    columns: width >= 800 ? 4 : 2
                    columnSpacing: 12
                    rowSpacing: 12

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Solar Generation"
                        valueText: appController.formatPower(appController.generationPowerW)
                        subtitle: appController.generationPowerW > 10 ? "Producing power" : "Standby / Night"
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
                            if (appController.batteryPowerW > 10) return "Charging • " + p;
                            if (appController.batteryPowerW < -10) return "Discharging • " + p;
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
                                : "Balanced"
                        accentColor: Theme.grid
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        title: "Home Load"
                        valueText: appController.formatPower(appController.consumptionPowerW)
                        subtitle: "Current consumption"
                        accentColor: Theme.load
                    }
                }
            }
        }
    }
}
