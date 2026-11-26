import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root

    property var items: []
    property int mode: 0 // 0=M, 1=Y, 2=T
    property string periodText: ""

    signal modeSelected(int newMode)
    signal previousPeriod()
    signal nextPeriod()

    // Legend toggles matching Deye Cloud Generation & Usage History
    property bool showProduction: true
    property bool showDischarge: true
    property bool showPurchased: true
    property bool showConsumption: true
    property bool showCharge: true
    property bool showGridFeedIn: true

    // Unified domain series colors matching Flow Graph & Power Profile
    readonly property color colProduction: Theme.solar
    readonly property color colDischarge: Theme.battery
    readonly property color colPurchased: Theme.grid
    readonly property color colConsumption: Theme.load
    readonly property color colCharge: Theme.isDark ? "#2DD4BF" : "#0D9488"
    readonly property color colGridFeedIn: Theme.isDark ? "#94A3B8" : "#64748B"

    property int hoverIndex: -1

    radius: Theme.radiusLg
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1
    implicitHeight: 336

    onItemsChanged: { hoverIndex = -1; barCanvas.requestPaint(); }
    onShowProductionChanged: barCanvas.requestPaint()
    onShowDischargeChanged: barCanvas.requestPaint()
    onShowPurchasedChanged: barCanvas.requestPaint()
    onShowConsumptionChanged: barCanvas.requestPaint()
    onShowChargeChanged: barCanvas.requestPaint()
    onShowGridFeedInChanged: barCanvas.requestPaint()
    onHoverIndexChanged: barCanvas.requestPaint()

    Connections {
        target: Theme
        function onIsDarkChanged() { barCanvas.requestPaint(); }
        function onTextPrimaryChanged() { barCanvas.requestPaint(); }
        function onBgPrimaryChanged() { barCanvas.requestPaint(); }
    }

    Connections {
        target: I18n
        function onLangChanged() { barCanvas.requestPaint(); }
    }

    component LegendItem: Item {
        property string label: ""
        property color dotColor: Theme.accent
        property bool active: true
        signal toggled()

        implicitWidth: legRow.implicitWidth + 8
        implicitHeight: 24

        RowLayout {
            id: legRow
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                width: 9
                height: 9
                radius: 2
                color: active ? dotColor : Theme.textMuted
            }

            Label {
                text: label
                font.pixelSize: 12
                color: active ? Theme.textPrimary : Theme.textMuted
                font.strikeout: !active
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggled()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.cardPadding
        spacing: Theme.spacingMd

        // Header Row: Title + M/Y/T Switcher + Period Navigator
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: I18n.t("Generation & Usage History")
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            // M | Y | T Switcher
            RowLayout {
                spacing: 2
                Repeater {
                    model: ["M", "Y", "T"]
                    delegate: Button {
                        implicitWidth: 34
                        implicitHeight: 28
                        text: modelData
                        highlighted: root.mode === index
                        onClicked: root.modeSelected(index)
                    }
                }
            }

            RowLayout {
                visible: root.mode < 2
                spacing: 4

                ToolButton {
                    text: "‹"
                    font.pixelSize: 16
                    onClicked: root.previousPeriod()
                }

                Label {
                    text: root.periodText
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Layout.preferredWidth: 72
                    horizontalAlignment: Text.AlignHCenter
                }

                ToolButton {
                    text: "›"
                    font.pixelSize: 16
                    onClicked: root.nextPeriod()
                }
            }
        }

        // Interactive Legend Row
        Flow {
            Layout.fillWidth: true
            spacing: 12

            LegendItem { label: I18n.t("Production"); dotColor: root.colProduction; active: root.showProduction; onToggled: root.showProduction = !root.showProduction }
            LegendItem { label: I18n.t("Discharge"); dotColor: root.colDischarge; active: root.showDischarge; onToggled: root.showDischarge = !root.showDischarge }
            LegendItem { label: I18n.t("Purchased"); dotColor: root.colPurchased; active: root.showPurchased; onToggled: root.showPurchased = !root.showPurchased }
            LegendItem { label: I18n.t("Consumption"); dotColor: root.colConsumption; active: root.showConsumption; onToggled: root.showConsumption = !root.showConsumption }
            LegendItem { label: I18n.t("Charge"); dotColor: root.colCharge; active: root.showCharge; onToggled: root.showCharge = !root.showCharge }
            LegendItem { label: I18n.t("Grid Feed-in"); dotColor: root.colGridFeedIn; active: root.showGridFeedIn; onToggled: root.showGridFeedIn = !root.showGridFeedIn }
        }

        // Bipolar Stacked Bar Chart Canvas
        Item {
            id: barContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real padL: 52
            readonly property real padR: 16
            readonly property real padT: 18
            readonly property real padB: 26

            Canvas {
                id: barCanvas
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var padL = barContainer.padL;
                    var padR = barContainer.padR;
                    var padT = barContainer.padT;
                    var padB = barContainer.padB;
                    var plotW = Math.max(10, width - padL - padR);
                    var plotH = Math.max(10, height - padT - padB);

                    var data = root.items || [];
                    var maxVal = 10.0;
                    for (var i = 0; i < data.length; ++i) {
                        var it = data[i];
                        var pos = (root.showPurchased ? it.purchasedKwh : 0)
                                + (root.showDischarge ? it.dischargeKwh : 0)
                                + (root.showProduction ? it.productionKwh : 0);
                        var neg = (root.showCharge ? it.chargeKwh : 0)
                                + (root.showConsumption ? it.consumptionKwh : 0)
                                + (root.showGridFeedIn ? it.gridFeedInKwh : 0);
                        maxVal = Math.max(maxVal, pos, neg);
                    }

                    // Nice symmetric ceiling
                    var step = 10.0;
                    if (maxVal > 1000) step = 500.0;
                    else if (maxVal > 200) step = 100.0;
                    else if (maxVal > 60) step = 50.0;
                    else if (maxVal > 20) step = 20.0;
                    var niceMax = Math.ceil(maxVal / step) * step;

                    var zeroY = padT + plotH * 0.5;
                    var halfH = plotH * 0.5;

                    // Horizontal grid lines + kWh axis labels
                    ctx.font = "11px monospace";
                    ctx.fillStyle = Theme.textMuted;
                    ctx.textAlign = "right";
                    ctx.textBaseline = "middle";
                    ctx.fillText("kWh", padL - 8, padT - 10);

                    var ticks = [niceMax, niceMax / 2.0, 0, -niceMax / 2.0, -niceMax];
                    for (var t = 0; t < ticks.length; ++t) {
                        var ty = zeroY - (ticks[t] / niceMax) * halfH;
                        ctx.beginPath();
                        ctx.moveTo(padL, ty);
                        ctx.lineTo(padL + plotW, ty);
                        ctx.lineWidth = (t === 2) ? 1.2 : 0.8;
                        ctx.strokeStyle = (t === 2) ? Theme.border : Theme.separator;
                        ctx.stroke();

                        ctx.fillText(ticks[t].toFixed(0), padL - 8, ty);
                    }

                    if (data.length === 0) {
                        ctx.textAlign = "center";
                        ctx.fillStyle = Theme.textMuted;
                        ctx.font = "12px sans-serif";
                        ctx.fillText(I18n.t("No history data for this period"), padL + plotW / 2, zeroY);
                        return;
                    }

                    var slotW = plotW / data.length;
                    var barW = Math.max(4, Math.min(26, slotW * 0.56));

                    for (var idx = 0; idx < data.length; ++idx) {
                        var row = data[idx];
                        var cx = padL + (idx + 0.5) * slotW;
                        var bx = cx - barW / 2;

                        // Hover column highlight
                        if (idx === root.hoverIndex) {
                            ctx.fillStyle = Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.06);
                            ctx.fillRect(padL + idx * slotW, padT, slotW, plotH);
                        }

                        // Positive stack (upward from zeroY): Purchased -> Discharge -> Production
                        var posCursor = zeroY;
                        function stackUp(val, color) {
                            if (val <= 0.001) return;
                            var h = (val / niceMax) * halfH;
                            ctx.fillStyle = color;
                            ctx.fillRect(bx, posCursor - h, barW, h);
                            posCursor -= h;
                        }
                        if (root.showPurchased) stackUp(row.purchasedKwh, root.colPurchased);
                        if (root.showDischarge) stackUp(row.dischargeKwh, root.colDischarge);
                        if (root.showProduction) stackUp(row.productionKwh, root.colProduction);

                        // Negative stack (downward from zeroY): Charge -> Consumption -> Grid Feed-in
                        var negCursor = zeroY;
                        function stackDown(val, color) {
                            if (val <= 0.001) return;
                            var h = (val / niceMax) * halfH;
                            ctx.fillStyle = color;
                            ctx.fillRect(bx, negCursor, barW, h);
                            negCursor += h;
                        }
                        if (root.showCharge) stackDown(row.chargeKwh, root.colCharge);
                        if (root.showConsumption) stackDown(row.consumptionKwh, root.colConsumption);
                        if (root.showGridFeedIn) stackDown(row.gridFeedInKwh, root.colGridFeedIn);

                        // X-axis label
                        ctx.textAlign = "center";
                        ctx.textBaseline = "top";
                        ctx.fillStyle = (idx === root.hoverIndex) ? Theme.textPrimary : Theme.textMuted;
                        ctx.fillText(row.label, cx, padT + plotH + 8);
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: function(mouse) {
                    var data = root.items || [];
                    if (data.length === 0) { root.hoverIndex = -1; return; }
                    var plotW = Math.max(10, width - barContainer.padL - barContainer.padR);
                    var relX = mouse.x - barContainer.padL;
                    if (relX < 0 || relX > plotW) { root.hoverIndex = -1; return; }
                    var idx = Math.floor((relX / plotW) * data.length);
                    root.hoverIndex = Math.max(0, Math.min(data.length - 1, idx));
                }
                onExited: root.hoverIndex = -1
            }

            // Floating Bar Tooltip
            Rectangle {
                id: barTip
                visible: root.hoverIndex >= 0 && root.items && root.hoverIndex < root.items.length
                readonly property var hi: visible ? root.items[root.hoverIndex] : null
                readonly property real anchorX: visible
                    ? barContainer.padL + ((root.hoverIndex + 0.5) / root.items.length) * Math.max(10, barContainer.width - barContainer.padL - barContainer.padR)
                    : 0

                x: (anchorX + width + 14 < barContainer.width - barContainer.padR) ? (anchorX + 12) : Math.max(barContainer.padL, anchorX - width - 12)
                y: barContainer.padT + 4
                width: barTipCol.implicitWidth + 20
                height: barTipCol.implicitHeight + 16
                radius: Theme.radiusMd
                color: Theme.bgElevated
                border.color: Theme.border
                border.width: 1
                z: 10

                ColumnLayout {
                    id: barTipCol
                    anchors.centerIn: parent
                    spacing: 3

                    Label {
                        text: barTip.hi ? barTip.hi.fullDate : ""
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                    }
                    Label {
                        visible: root.showProduction && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Production") + ": " + barTip.hi.productionKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colProduction
                    }
                    Label {
                        visible: root.showDischarge && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Discharge") + ": " + barTip.hi.dischargeKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colDischarge
                    }
                    Label {
                        visible: root.showPurchased && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Purchased") + ": " + barTip.hi.purchasedKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colPurchased
                    }
                    Label {
                        visible: root.showConsumption && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Consumption") + ": " + barTip.hi.consumptionKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colConsumption
                    }
                    Label {
                        visible: root.showCharge && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Charge") + ": " + barTip.hi.chargeKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colCharge
                    }
                    Label {
                        visible: root.showGridFeedIn && barTip.hi
                        text: barTip.hi ? ("■ " + I18n.t("Grid Feed-in") + ": " + barTip.hi.gridFeedInKwh.toFixed(1) + " kWh") : ""
                        font.pixelSize: 11
                        color: root.colGridFeedIn
                    }
                }
            }
        }
    }
}
