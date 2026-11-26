import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Dialog {
    id: dialog
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(820, Overlay.overlay ? Overlay.overlay.width - 48 : 800)
    height: Math.min(660, Overlay.overlay ? Overlay.overlay.height - 48 : 640)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property var ctrl: appController.inverterSettings

    readonly property var workModeValues: ["SELLING_FIRST", "ZERO_EXPORT_TO_LOAD", "ZERO_EXPORT_TO_CT"]
    readonly property var workModeLabels: ["Selling First", "Zero Export to Load", "Zero Export to CT"]

    readonly property var energyPatternValues: ["BATTERY_FIRST", "LOAD_FIRST"]
    readonly property var energyPatternLabels: ["Battery First", "Load First"]

    readonly property var limitControlValues: ["SELL_FIRST", "ZERO_EXPORT_TO_UPS_LOAD", "ZERO_EXPORT_TO_CT", "ZERO_EXPORT_TO_WIRELESS_CT"]
    readonly property var limitControlLabels: ["Sell First", "Zero Export to UPS Load", "Zero Export to CT", "Zero Export to Wireless CT"]

    readonly property var batteryTypeValues: ["LITHIUM", "LEAD_BATTERY", "NO_BATTERY"]
    readonly property var batteryTypeLabels: ["Lithium (BMS)", "Lead-Acid / AGM", "No Battery"]

    function indexOfOrZero(arr, val) {
        var i = arr.indexOf(val);
        return i >= 0 ? i : 0;
    }

    component SectionCard: Rectangle {
        Layout.fillWidth: true
        radius: Theme.radiusLg
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
    }

    component SettingRow: ColumnLayout {
        property string label: ""
        property string description: ""
        property bool showSeparator: true
        default property alias controlContent: controlSlot.data

        Layout.fillWidth: true
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: I18n.t(label)
                    font.weight: Font.Medium
                }
                Label {
                    visible: description.length > 0
                    text: description
                    color: Theme.textMuted
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                id: controlSlot
                spacing: 8
            }
        }

        Rectangle {
            visible: showSeparator
            Layout.fillWidth: true
            height: 1
            color: Theme.separator
        }
    }

    contentItem: Rectangle {
        color: Theme.bgPrimary
        radius: Theme.radiusLg
        border.color: Theme.border
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Dialog Header
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 58
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
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label {
                            text: (ctrl.deviceName || I18n.t("Inverter")) + " — " + I18n.t("Settings")
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: "SN: " + ctrl.deviceSn + (ctrl.loading ? ("  •  " + I18n.t("Loading current config…")) : "")
                            color: Theme.textSecondary
                            font.pixelSize: 11
                        }
                    }

                    Button {
                        text: I18n.t("Reload")
                        enabled: !ctrl.loading && !ctrl.saving
                        onClicked: ctrl.reload()
                    }

                    Button {
                        text: I18n.t("Close")
                        onClicked: dialog.close()
                    }
                }
            }

            // Native TabBar
            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton { text: I18n.t("System") }
                TabButton { text: I18n.t("Battery") }
                TabButton { text: I18n.t("Time of Use") }
                TabButton { text: I18n.t("Advanced") }
            }

            // Status / Order Feedback Banner
            Rectangle {
                visible: ctrl.statusMessage.length > 0
                Layout.fillWidth: true
                Layout.margins: 12
                Layout.bottomMargin: 0
                implicitHeight: statusRow.implicitHeight + 14
                radius: Theme.radiusMd
                color: ctrl.statusIsError ? Theme.errorSoft : Theme.batterySoft
                border.color: ctrl.statusIsError
                              ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)
                              : Qt.rgba(Theme.battery.r, Theme.battery.g, Theme.battery.b, 0.55)

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: ctrl.statusMessage
                        color: ctrl.statusIsError ? Theme.errorText : Theme.battery
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Button {
                        flat: true
                        text: I18n.t("Dismiss")
                        onClicked: ctrl.clearStatus()
                    }
                }
            }

            // Tab Body
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // ===================== TAB 0: SYSTEM =====================
                Flickable {
                    contentWidth: width
                    contentHeight: sysCol.implicitHeight + 32
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: sysCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            visible: ctrl.systemReadNote.length > 0
                            Layout.fillWidth: true
                            implicitHeight: sysNoteLbl.implicitHeight + 16
                            radius: Theme.radiusMd
                            color: Theme.solarSoft
                            border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.45)

                            Label {
                                id: sysNoteLbl
                                anchors.fill: parent
                                anchors.margins: 8
                                text: ctrl.systemReadNote
                                color: Theme.solar
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        SectionCard {
                            implicitHeight: sysCardCol.implicitHeight
                            ColumnLayout {
                                id: sysCardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0

                                SettingRow {
                                    label: "System Work Mode"
                                    description: "Primary export and load strategy (/order/sys/workMode/update)"
                                    ComboBox {
                                        id: workModeCombo
                                        implicitWidth: 200
                                        model: dialog.workModeLabels
                                        currentIndex: dialog.indexOfOrZero(dialog.workModeValues, ctrl.workMode)
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updateWorkMode(dialog.workModeValues[workModeCombo.currentIndex])
                                    }
                                }

                                SettingRow {
                                    label: "Energy Pattern"
                                    description: "Prioritize charging battery or supplying load (/order/sys/energyPattern/update)"
                                    ComboBox {
                                        id: energyPatternCombo
                                        implicitWidth: 200
                                        model: dialog.energyPatternLabels
                                        currentIndex: dialog.indexOfOrZero(dialog.energyPatternValues, ctrl.energyPattern)
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updateEnergyPattern(dialog.energyPatternValues[energyPatternCombo.currentIndex])
                                    }
                                }

                                SettingRow {
                                    label: "Solar Sell"
                                    description: "Allow exporting surplus PV energy to the grid (/order/sys/solarSell/control)"
                                    CheckBox {
                                        id: solarSellCheck
                                        checked: ctrl.solarSell
                                        text: checked ? "Enabled" : "Disabled"
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.setSolarSell(solarSellCheck.checked)
                                    }
                                }

                                SettingRow {
                                    label: "Export Limit Control"
                                    description: "Zero-export CT / UPS load behavior (/order/sys/limitControl)"
                                    ComboBox {
                                        id: limitControlCombo
                                        implicitWidth: 200
                                        model: dialog.limitControlLabels
                                        currentIndex: dialog.indexOfOrZero(dialog.limitControlValues, ctrl.limitControl)
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updateLimitControl(dialog.limitControlValues[limitControlCombo.currentIndex])
                                    }
                                }

                                SettingRow {
                                    label: "Max Sell Power (W)"
                                    description: "Maximum power exported to the grid (/order/sys/power/update)"
                                    SpinBox {
                                        id: maxSellSpin
                                        from: 0; to: 50000; stepSize: 100
                                        editable: true
                                        value: ctrl.maxSellPower
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updatePowerLimit("MAX_SELL_POWER", maxSellSpin.value)
                                    }
                                }

                                SettingRow {
                                    label: "Max Solar Power (W)"
                                    description: "Upper PV generation limit (/order/sys/power/update)"
                                    SpinBox {
                                        id: maxSolarSpin
                                        from: 0; to: 50000; stepSize: 100
                                        editable: true
                                        value: ctrl.maxSolarPower
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updatePowerLimit("MAX_SOLAR_POWER", maxSolarSpin.value)
                                    }
                                }

                                SettingRow {
                                    label: "Grid Peak Shaving"
                                    description: "Cap grid import power using battery (/order/gridPeakShaving/control)"
                                    showSeparator: false
                                    CheckBox {
                                        id: peakShavingCheck
                                        checked: ctrl.gridPeakShavingEnabled
                                        text: "Enable"
                                    }
                                    SpinBox {
                                        id: peakShavingSpin
                                        from: 0; to: 30000; stepSize: 100
                                        editable: true
                                        value: ctrl.gridPeakShavingPower
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updateGridPeakShaving(peakShavingCheck.checked, peakShavingSpin.value)
                                    }
                                }
                            }
                        }
                    }
                }

                // ===================== TAB 1: BATTERY =====================
                Flickable {
                    contentWidth: width
                    contentHeight: battCol.implicitHeight + 32
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: battCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            visible: ctrl.batteryReadNote.length > 0
                            Layout.fillWidth: true
                            implicitHeight: battNoteLbl.implicitHeight + 16
                            radius: Theme.radiusMd
                            color: Theme.solarSoft
                            border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.45)

                            Label {
                                id: battNoteLbl
                                anchors.fill: parent
                                anchors.margins: 8
                                text: ctrl.batteryReadNote
                                color: Theme.solar
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Battery Type & Charge Modes
                        SectionCard {
                            implicitHeight: battModeCol.implicitHeight
                            ColumnLayout {
                                id: battModeCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0

                                SettingRow {
                                    label: "Battery Type"
                                    description: "Chemistry & BMS mode (/order/battery/type/update)"
                                    ComboBox {
                                        id: battTypeCombo
                                        implicitWidth: 180
                                        model: dialog.batteryTypeLabels
                                        currentIndex: dialog.indexOfOrZero(dialog.batteryTypeValues, ctrl.batteryType)
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.updateBatteryType(dialog.batteryTypeValues[battTypeCombo.currentIndex])
                                    }
                                }

                                SettingRow {
                                    label: "Grid Charge Mode"
                                    description: "Allow charging battery from grid (/order/battery/modeControl)"
                                    CheckBox {
                                        id: gridChargeCheck
                                        checked: ctrl.gridChargeEnabled
                                        text: checked ? "Enabled" : "Disabled"
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.setBatteryModeControl("GRID_CHARGE", gridChargeCheck.checked)
                                    }
                                }

                                SettingRow {
                                    label: "Generator Charge Mode"
                                    description: "Allow charging battery from generator (/order/battery/modeControl)"
                                    showSeparator: false
                                    CheckBox {
                                        id: genChargeCheck
                                        checked: ctrl.genChargeEnabled
                                        text: checked ? "Enabled" : "Disabled"
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.setBatteryModeControl("GEN_CHARGE", genChargeCheck.checked)
                                    }
                                }
                            }
                        }

                        // Current, Capacity & SOC Limits
                        SectionCard {
                            implicitHeight: battParamCol.implicitHeight
                            ColumnLayout {
                                id: battParamCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0

                                SettingRow {
                                    label: "Max Charge Current (A)"
                                    SpinBox { id: maxChgA; from: 0; to: 300; editable: true; value: ctrl.maxChargeCurrent }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("MAX_CHARGE_CURRENT", maxChgA.value) }
                                }
                                SettingRow {
                                    label: "Max Discharge Current (A)"
                                    SpinBox { id: maxDisA; from: 0; to: 300; editable: true; value: ctrl.maxDischargeCurrent }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("MAX_DISCHARGE_CURRENT", maxDisA.value) }
                                }
                                SettingRow {
                                    label: "Grid Charge Current (A)"
                                    SpinBox { id: gridChgA; from: 0; to: 300; editable: true; value: ctrl.gridChargeAmpere }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("GRID_CHARGE_AMPERE", gridChgA.value) }
                                }
                                SettingRow {
                                    label: "Generator Charge Current (A)"
                                    SpinBox { id: genChgA; from: 0; to: 300; editable: true; value: ctrl.genChargeAmpere }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("GEN_CHARGE_AMPERE", genChgA.value) }
                                }
                                SettingRow {
                                    label: "Battery Capacity (Ah)"
                                    SpinBox { id: battCapAh; from: 10; to: 2000; stepSize: 10; editable: true; value: ctrl.batteryCapacityAh }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("BATT_CAPACITY", battCapAh.value) }
                                }
                                SettingRow {
                                    label: "Shutdown SOC (%)"
                                    SpinBox { id: shutSoc; from: 0; to: 100; editable: true; value: ctrl.shutdownSoc }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("SHUTDOWN_SOC", shutSoc.value) }
                                }
                                SettingRow {
                                    label: "Low Battery SOC (%)"
                                    SpinBox { id: lowSoc; from: 0; to: 100; editable: true; value: ctrl.lowBattSoc }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("LOW_BATT_SOC", lowSoc.value) }
                                }
                                SettingRow {
                                    label: "Restart SOC (%)"
                                    SpinBox { id: restartSocSpin; from: 0; to: 100; editable: true; value: ctrl.restartSoc }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("RESTART_SOC", restartSocSpin.value) }
                                }
                                SettingRow {
                                    label: "Grid Charge Start SOC (%)"
                                    SpinBox { id: gridStartSoc; from: 0; to: 100; editable: true; value: ctrl.gridChargeStartSoc }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("GRID_CHARGE_START_SOC", gridStartSoc.value) }
                                }
                                SettingRow {
                                    label: "Generator Charge Start SOC (%)"
                                    SpinBox { id: genStartSoc; from: 0; to: 100; editable: true; value: ctrl.genChargeStartSoc }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("GEN_CHARGE_START_SOC", genStartSoc.value) }
                                }
                                SettingRow {
                                    label: "Equalization Voltage (V)"
                                    TextField { id: eqVField; implicitWidth: 88; text: ctrl.equalizationV.toFixed(1) }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("EQUALIZATION_V", parseFloat(eqVField.text) || 0) }
                                }
                                SettingRow {
                                    label: "Absorption Voltage (V)"
                                    TextField { id: absVField; implicitWidth: 88; text: ctrl.absorptionV.toFixed(1) }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("ABSORPTION_V", parseFloat(absVField.text) || 0) }
                                }
                                SettingRow {
                                    label: "Float Voltage (V)"
                                    showSeparator: false
                                    TextField { id: fltVField; implicitWidth: 88; text: ctrl.floatV.toFixed(1) }
                                    Button { text: I18n.t("Apply"); enabled: !ctrl.saving; onClicked: ctrl.updateBatteryParameter("FLOAT_V", parseFloat(fltVField.text) || 0) }
                                }
                            }
                        }
                    }
                }

                // ===================== TAB 2: TIME OF USE =====================
                Flickable {
                    contentWidth: width
                    contentHeight: touCol.implicitHeight + 32
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: touCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            visible: ctrl.touReadNote.length > 0
                            Layout.fillWidth: true
                            implicitHeight: touNoteLbl.implicitHeight + 16
                            radius: Theme.radiusMd
                            color: Theme.solarSoft
                            border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.45)

                            Label {
                                id: touNoteLbl
                                anchors.fill: parent
                                anchors.margins: 8
                                text: ctrl.touReadNote
                                color: Theme.solar
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        SectionCard {
                            implicitHeight: touSwitchCol.implicitHeight
                            ColumnLayout {
                                id: touSwitchCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0

                                SettingRow {
                                    label: "Time of Use Schedule"
                                    description: "Enable or disable scheduled SOC & grid charging (/order/sys/tou/switch)"
                                    showSeparator: false
                                    CheckBox {
                                        id: touEnableCheck
                                        checked: ctrl.touEnabled
                                        text: checked ? "Enabled" : "Disabled"
                                    }
                                    Button {
                                        text: I18n.t("Apply")
                                        enabled: !ctrl.saving
                                        onClicked: ctrl.setTouEnabled(touEnableCheck.checked)
                                    }
                                }
                            }
                        }

                        SectionCard {
                            implicitHeight: slotsCol.implicitHeight
                            ColumnLayout {
                                id: slotsCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0

                                // Header Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.margins: 12
                                    spacing: 8
                                    Label { text: "Slot"; Layout.preferredWidth: 36; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                    Label { text: "Start Time"; Layout.preferredWidth: 78; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                    Label { text: "SOC (%)"; Layout.preferredWidth: 116; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                    Label { text: "Power (W)"; Layout.preferredWidth: 116; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                    Label { text: "Grid"; Layout.preferredWidth: 52; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                    Label { text: "Gen"; Layout.fillWidth: true; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.Bold }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.separator }

                                Repeater {
                                    model: ctrl.touSlots

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 12
                                            Layout.rightMargin: 12
                                            Layout.topMargin: 8
                                            Layout.bottomMargin: 8
                                            spacing: 8

                                            Label {
                                                text: "#" + (index + 1)
                                                Layout.preferredWidth: 36
                                                color: Theme.textSecondary
                                                font.weight: Font.Bold
                                            }
                                            TextField {
                                                id: slotTime
                                                Layout.preferredWidth: 78
                                                text: modelData.time
                                                placeholderText: "HH:MM"
                                                inputMask: "99:99"
                                                horizontalAlignment: Text.AlignHCenter
                                                onEditingFinished: ctrl.updateTouSlot(index, slotTime.text, slotSoc.value, slotPower.value, modelData.voltage, slotGrid.checked, slotGen.checked)
                                            }
                                            SpinBox {
                                                id: slotSoc
                                                Layout.preferredWidth: 116
                                                from: 0; to: 100; editable: true
                                                value: modelData.soc
                                                onValueModified: ctrl.updateTouSlot(index, slotTime.text, slotSoc.value, slotPower.value, modelData.voltage, slotGrid.checked, slotGen.checked)
                                            }
                                            SpinBox {
                                                id: slotPower
                                                Layout.preferredWidth: 116
                                                from: 0; to: 30000; stepSize: 100; editable: true
                                                value: modelData.power
                                                onValueModified: ctrl.updateTouSlot(index, slotTime.text, slotSoc.value, slotPower.value, modelData.voltage, slotGrid.checked, slotGen.checked)
                                            }
                                            CheckBox {
                                                id: slotGrid
                                                Layout.preferredWidth: 52
                                                checked: modelData.enableGridCharge
                                                onToggled: ctrl.updateTouSlot(index, slotTime.text, slotSoc.value, slotPower.value, modelData.voltage, slotGrid.checked, slotGen.checked)
                                            }
                                            CheckBox {
                                                id: slotGen
                                                Layout.fillWidth: true
                                                checked: modelData.enableGeneration
                                                onToggled: ctrl.updateTouSlot(index, slotTime.text, slotSoc.value, slotPower.value, modelData.voltage, slotGrid.checked, slotGen.checked)
                                            }
                                        }

                                        Rectangle {
                                            visible: index < 5
                                            Layout.fillWidth: true
                                            height: 1
                                            color: Theme.separator
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            Button {
                                id: applyTouBtn
                                implicitHeight: 36
                                leftPadding: 18
                                rightPadding: 18
                                text: I18n.t("Apply Time of Use Schedule")
                                enabled: !ctrl.saving
                                onClicked: ctrl.applyTouSchedule()
                                contentItem: Label {
                                    text: applyTouBtn.text
                                    color: applyTouBtn.enabled ? Theme.accentText : Theme.textMuted
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: Theme.radiusSm
                                    color: !applyTouBtn.enabled ? Theme.bgElevated
                                         : applyTouBtn.down ? Qt.darker(Theme.accent, 1.15)
                                         : applyTouBtn.hovered ? Qt.lighter(Theme.accent, 1.12)
                                         : Theme.accent
                                }
                            }
                        }
                    }
                }

                // ===================== TAB 3: ADVANCED =====================
                Flickable {
                    contentWidth: width
                    contentHeight: advCol.implicitHeight + 32
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: advCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 14

                        SectionCard {
                            implicitHeight: advInner.implicitHeight + 28
                            ColumnLayout {
                                id: advInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14
                                spacing: 10

                                Label {
                                    text: I18n.t("Custom Modbus / Control Command")
                                    font.weight: Font.Bold
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: "Send a raw hexadecimal Modbus RTU command frame via POST /v1.0/order/customControl. Use with caution — incorrect register writes can affect inverter operation."
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                                TextField {
                                    id: customHexField
                                    Layout.fillWidth: true
                                    placeholderText: "e.g. 011000F80001020001..."
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: I18n.t("Send Custom Command")
                                        enabled: !ctrl.saving && customHexField.text.trim().length > 0
                                        onClicked: ctrl.sendCustomControl(customHexField.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
