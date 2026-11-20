import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root

    property var points: []
    property string dateText: ""

    signal previousDay()
    signal nextDay()

    // Series visibility toggles (clickable legend)
    property bool showPv: true
    property bool showGrid: true
    property bool showBattery: true
    property bool showConsumption: true
    property bool showSoc: true

    // Series colors matching Deye Cloud Power Profile in dark mode
    readonly property color colPv: "#E879F9"
    readonly property color colGrid: "#8B5CF6"
    readonly property color colBattery: "#3B82F6"
    readonly property color colConsumption: "#F59E0B"
    readonly property color colSoc: "#10B981"

    property int hoverIndex: -1

    radius: Theme.radiusLg
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1
    implicitHeight: 330

    onPointsChanged: { hoverIndex = -1; chartCanvas.requestPaint(); }
    onShowPvChanged: chartCanvas.requestPaint()
    onShowGridChanged: chartCanvas.requestPaint()
    onShowBatteryChanged: chartCanvas.requestPaint()
    onShowConsumptionChanged: chartCanvas.requestPaint()
    onShowSocChanged: chartCanvas.requestPaint()
    onHoverIndexChanged: chartCanvas.requestPaint()

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
                radius: 4.5
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

        // Header Row: Title + Date Navigator
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: I18n.t("Power Profile")
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 4

                ToolButton {
                    text: "‹"
                    font.pixelSize: 16
                    onClicked: root.previousDay()
                }

                Label {
                    text: root.dateText
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Layout.preferredWidth: 86
                    horizontalAlignment: Text.AlignHCenter
                }

                ToolButton {
                    text: "›"
                    font.pixelSize: 16
                    onClicked: root.nextDay()
                }
            }
        }

        // Interactive Legend Row
        Flow {
            Layout.fillWidth: true
            spacing: 12

            LegendItem { label: I18n.t("PV"); dotColor: root.colPv; active: root.showPv; onToggled: root.showPv = !root.showPv }
            LegendItem { label: I18n.t("Grid"); dotColor: root.colGrid; active: root.showGrid; onToggled: root.showGrid = !root.showGrid }
            LegendItem { label: I18n.t("Battery"); dotColor: root.colBattery; active: root.showBattery; onToggled: root.showBattery = !root.showBattery }
            LegendItem { label: I18n.t("Home Load"); dotColor: root.colConsumption; active: root.showConsumption; onToggled: root.showConsumption = !root.showConsumption }
            LegendItem { label: I18n.t("Battery SOC"); dotColor: root.colSoc; active: root.showSoc; onToggled: root.showSoc = !root.showSoc }
        }

        // Interactive Canvas Chart
        Item {
            id: plotContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real padL: 44
            readonly property real padR: 42
            readonly property real padT: 18
            readonly property real padB: 26

            Canvas {
                id: chartCanvas
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var padL = plotContainer.padL;
                    var padR = plotContainer.padR;
                    var padT = plotContainer.padT;
                    var padB = plotContainer.padB;
                    var plotW = Math.max(10, width - padL - padR);
                    var plotH = Math.max(10, height - padT - padB);

                    // Compute symmetric Y-axis bound in kW
                    var maxAbsKw = 2.0;
                    var pts = root.points || [];
                    for (var i = 0; i < pts.length; ++i) {
                        var pt = pts[i];
                        if (root.showPv) maxAbsKw = Math.max(maxAbsKw, Math.abs(pt.pvKw));
                        if (root.showGrid) maxAbsKw = Math.max(maxAbsKw, Math.abs(pt.gridKw));
                        if (root.showBattery) maxAbsKw = Math.max(maxAbsKw, Math.abs(pt.batteryKw));
                        if (root.showConsumption) maxAbsKw = Math.max(maxAbsKw, Math.abs(pt.consumptionKw));
                    }
                    // Nice rounded ceiling (2, 4, 6, 10, 15, 20, ...)
                    var niceMax = Math.ceil(maxAbsKw / 2.0) * 2.0;
                    if (niceMax > 10) niceMax = Math.ceil(maxAbsKw / 5.0) * 5.0;

                    function xForHour(h) { return padL + (h / 24.0) * plotW; }
                    function yForKw(kw) { return padT + plotH * (0.5 - (kw / (2.0 * niceMax))); }
                    function yForSoc(soc) { return padT + plotH * (1.0 - soc / 100.0); }

                    // Horizontal grid lines & dual Y labels (kW left, % right)
                    ctx.font = "11px sans-serif";
                    ctx.fillStyle = Theme.textMuted;
                    ctx.textBaseline = "middle";

                    // Axis unit headers
                    ctx.textAlign = "right";
                    ctx.fillText("kW", padL - 8, padT - 10);
                    ctx.textAlign = "left";
                    ctx.fillText("%", padL + plotW + 8, padT - 10);

                    var steps = 4; // -max, -max/2, 0, +max/2, +max  <->  0%, 25%, 50%, 75%, 100%
                    for (var s = 0; s <= steps; ++s) {
                        var frac = s / steps;
                        var gy = padT + plotH * frac;
                        var kwVal = niceMax * (1.0 - 2.0 * frac);
                        var socVal = Math.round(100.0 * (1.0 - frac));

                        ctx.beginPath();
                        ctx.moveTo(padL, gy);
                        ctx.lineTo(padL + plotW, gy);
                        ctx.lineWidth = (s === 2) ? 1.2 : 0.8;
                        ctx.strokeStyle = (s === 2) ? Theme.border : Theme.separator;
                        ctx.stroke();

                        ctx.textAlign = "right";
                        ctx.fillStyle = Theme.textMuted;
                        ctx.fillText(kwVal.toFixed(0), padL - 8, gy);

                        ctx.textAlign = "left";
                        ctx.fillText(String(socVal), padL + plotW + 8, gy);
                    }

                    // X-axis time labels (00:00, 03:00, ..., 21:00)
                    ctx.textAlign = "center";
                    ctx.textBaseline = "top";
                    for (var hr = 0; hr <= 21; hr += 3) {
                        var hx = xForHour(hr);
                        var hTxt = (hr < 10 ? "0" : "") + hr + ":00";
                        ctx.fillText(hTxt, hx, padT + plotH + 8);
                    }

                    if (pts.length === 0) {
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillStyle = Theme.textMuted;
                        ctx.font = "12px sans-serif";
                        ctx.fillText(I18n.t("No power profile data for this date"), padL + plotW / 2, padT + plotH / 2);
                        return;
                    }

                    function drawSeries(getter, yFn, color, dashed) {
                        ctx.save();
                        ctx.beginPath();
                        var started = false;
                        for (var k = 0; k < pts.length; ++k) {
                            var val = getter(pts[k]);
                            if (val === null || val === undefined) continue;
                            var px = xForHour(pts[k].hourOfDay);
                            var py = yFn(val);
                            if (!started) { ctx.moveTo(px, py); started = true; }
                            else ctx.lineTo(px, py);
                        }
                        ctx.lineWidth = 1.8;
                        ctx.lineJoin = "round";
                        ctx.strokeStyle = color;
                        if (dashed) ctx.setLineDash([4, 3]);
                        ctx.stroke();
                        ctx.restore();
                    }

                    if (root.showSoc) drawSeries(function(p) { return p.hasSoc ? p.soc : null; }, yForSoc, root.colSoc, true);
                    if (root.showGrid) drawSeries(function(p) { return p.gridKw; }, yForKw, root.colGrid, false);
                    if (root.showBattery) drawSeries(function(p) { return p.batteryKw; }, yForKw, root.colBattery, false);
                    if (root.showPv) drawSeries(function(p) { return p.pvKw; }, yForKw, root.colPv, false);
                    if (root.showConsumption) drawSeries(function(p) { return p.consumptionKw; }, yForKw, root.colConsumption, false);

                    // Hover crosshair + highlight dots
                    if (root.hoverIndex >= 0 && root.hoverIndex < pts.length) {
                        var hp = pts[root.hoverIndex];
                        var cx = xForHour(hp.hourOfDay);

                        ctx.save();
                        ctx.beginPath();
                        ctx.moveTo(cx, padT);
                        ctx.lineTo(cx, padT + plotH);
                        ctx.lineWidth = 1;
                        ctx.setLineDash([3, 3]);
                        ctx.strokeStyle = Theme.textSecondary;
                        ctx.stroke();
                        ctx.restore();

                        function drawDot(y, col) {
                            ctx.beginPath();
                            ctx.arc(cx, y, 4, 0, Math.PI * 2);
                            ctx.fillStyle = col;
                            ctx.fill();
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = Theme.bgSurface;
                            ctx.stroke();
                        }

                        if (root.showPv) drawDot(yForKw(hp.pvKw), root.colPv);
                        if (root.showGrid) drawDot(yForKw(hp.gridKw), root.colGrid);
                        if (root.showBattery) drawDot(yForKw(hp.batteryKw), root.colBattery);
                        if (root.showConsumption) drawDot(yForKw(hp.consumptionKw), root.colConsumption);
                        if (root.showSoc && hp.hasSoc) drawDot(yForSoc(hp.soc), root.colSoc);
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: function(mouse) {
                    var pts = root.points || [];
                    if (pts.length === 0) { root.hoverIndex = -1; return; }
                    var plotW = Math.max(10, width - plotContainer.padL - plotContainer.padR);
                    var relX = mouse.x - plotContainer.padL;
                    if (relX < 0 || relX > plotW) { root.hoverIndex = -1; return; }
                    var targetHour = (relX / plotW) * 24.0;
                    var best = 0;
                    var bestDist = 999;
                    for (var i = 0; i < pts.length; ++i) {
                        var d = Math.abs(pts[i].hourOfDay - targetHour);
                        if (d < bestDist) { bestDist = d; best = i; }
                    }
                    root.hoverIndex = best;
                }
                onExited: root.hoverIndex = -1
            }

            // Floating Hover Tooltip
            Rectangle {
                id: tooltip
                visible: root.hoverIndex >= 0 && root.points && root.hoverIndex < root.points.length
                readonly property var hp: visible ? root.points[root.hoverIndex] : null
                readonly property real anchorX: visible
                    ? plotContainer.padL + (hp.hourOfDay / 24.0) * Math.max(10, plotContainer.width - plotContainer.padL - plotContainer.padR)
                    : 0

                x: (anchorX + width + 14 < plotContainer.width - plotContainer.padR) ? (anchorX + 12) : Math.max(plotContainer.padL, anchorX - width - 12)
                y: plotContainer.padT + 4
                width: tipCol.implicitWidth + 20
                height: tipCol.implicitHeight + 16
                radius: Theme.radiusMd
                color: Theme.bgElevated
                border.color: Theme.border
                border.width: 1
                z: 10

                ColumnLayout {
                    id: tipCol
                    anchors.centerIn: parent
                    spacing: 3

                    Label {
                        text: tooltip.hp ? (root.dateText + "  " + tooltip.hp.timeLabel) : ""
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                    }
                    Label {
                        visible: root.showPv && tooltip.hp
                        text: tooltip.hp ? ("● " + I18n.t("PV") + ": " + tooltip.hp.pvKw.toFixed(2) + " kW") : ""
                        font.pixelSize: 11
                        color: root.colPv
                    }
                    Label {
                        visible: root.showGrid && tooltip.hp
                        text: tooltip.hp ? ("● " + I18n.t("Grid") + ": " + tooltip.hp.gridKw.toFixed(2) + " kW") : ""
                        font.pixelSize: 11
                        color: root.colGrid
                    }
                    Label {
                        visible: root.showBattery && tooltip.hp
                        text: tooltip.hp ? ("● " + I18n.t("Battery") + ": " + tooltip.hp.batteryKw.toFixed(2) + " kW") : ""
                        font.pixelSize: 11
                        color: root.colBattery
                    }
                    Label {
                        visible: root.showConsumption && tooltip.hp
                        text: tooltip.hp ? ("● " + I18n.t("Home Load") + ": " + tooltip.hp.consumptionKw.toFixed(2) + " kW") : ""
                        font.pixelSize: 11
                        color: root.colConsumption
                    }
                    Label {
                        visible: root.showSoc && tooltip.hp && tooltip.hp.hasSoc
                        text: tooltip.hp ? ("● SOC: " + Math.round(tooltip.hp.soc) + "%") : ""
                        font.pixelSize: 11
                        color: root.colSoc
                    }
                }
            }
        }
    }
}
