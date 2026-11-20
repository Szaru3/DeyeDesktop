import QtQuick
import QtQuick.Controls
import DeyeDesktop

Rectangle {
    id: root

    property double generationPowerW: 0
    property double consumptionPowerW: 0
    property double batteryPowerW: 0    // >0 charging, <0 discharging
    property double batterySoc: 0
    property bool hasBatterySoc: false
    property double gridPowerW: 0       // >0 importing, <0 exporting
    property real flowPhase: 0.0

    radius: Theme.radiusLg
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1
    implicitHeight: 340

    NumberAnimation on flowPhase {
        from: 0.0
        to: 1.0
        duration: 4800
        loops: Animation.Infinite
        running: root.visible
    }

    onFlowPhaseChanged: canvas.requestPaint()
    onGenerationPowerWChanged: canvas.requestPaint()
    onConsumptionPowerWChanged: canvas.requestPaint()
    onBatteryPowerWChanged: canvas.requestPaint()
    onGridPowerWChanged: canvas.requestPaint()
    onBatterySocChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    // Card title ("Flow Graph")
    Label {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Theme.cardPadding
        anchors.leftMargin: Theme.cardPadding
        text: I18n.t("Flow Graph")
        font.pixelSize: 15
        font.weight: Font.DemiBold
        color: Theme.textPrimary
    }

    // Geometry helpers shared between Canvas tracks and node tiles
    readonly property real padX: Math.max(72, width * 0.12)
    readonly property real topNodeY: 88
    readonly property real bottomNodeY: height - 74
    readonly property real centerX: width / 2
    readonly property real centerY: (topNodeY + bottomNodeY) / 2
    readonly property real tileSize: 56

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = root.centerX;
            var cy = root.centerY;
            var leftX = root.padX;
            var rightX = width - root.padX;
            var topY = root.topNodeY;
            var botY = root.bottomNodeY;
            var halfTile = root.tileSize / 2;
            var invHalf = 30;
            var bendR = 14;
            var invOffsetY = 12;

            // Mid X bends (about halfway between outer tile and center inverter)
            var midLeftX = leftX + (cx - leftX) * 0.48;
            var midRightX = rightX - (rightX - cx) * 0.48;

            // Build a 4-point orthogonal polyline and evaluate point at progress t in [0,1]
            function drawOrthogonalFlow(pts, active, reverse, pulseColor, drawArrowAtEnd) {
                var p0 = pts[0], p1 = pts[1], p2 = pts[2], p3 = pts[3];

                // Dashed rounded orthogonal path
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(p0.x, p0.y);
                ctx.arcTo(p1.x, p1.y, p2.x, p2.y, bendR);
                ctx.arcTo(p2.x, p2.y, p3.x, p3.y, bendR);
                ctx.lineTo(p3.x, p3.y);
                ctx.lineWidth = 1.8;
                ctx.setLineDash([6, 5]);
                ctx.strokeStyle = active
                    ? Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.72)
                    : Qt.rgba(Theme.textMuted.r, Theme.textMuted.g, Theme.textMuted.b, 0.45);
                ctx.stroke();
                ctx.restore();

                // Directional arrowhead near destination
                if (active && drawArrowAtEnd) {
                    var tip = reverse ? p0 : p3;
                    var prev = reverse ? p1 : p2;
                    var dx = tip.x - prev.x;
                    var dy = tip.y - prev.y;
                    var len = Math.sqrt(dx * dx + dy * dy) || 1;
                    var ux = dx / len;
                    var uy = dy / len;
                    var ax = tip.x - ux * 2;
                    var ay = tip.y - uy * 2;

                    ctx.save();
                    ctx.beginPath();
                    ctx.moveTo(ax, ay);
                    ctx.lineTo(ax - ux * 8 - uy * 5, ay - uy * 8 + ux * 5);
                    ctx.lineTo(ax - ux * 8 + uy * 5, ay - uy * 8 - ux * 5);
                    ctx.closePath();
                    ctx.fillStyle = Theme.textSecondary;
                    ctx.fill();
                    ctx.restore();
                }

                if (!active) return;

                // Animated glowing dots traveling along exact polyline
                var ordered = reverse ? [p3, p2, p1, p0] : [p0, p1, p2, p3];
                var segLens = [];
                var totalLen = 0;
                for (var i = 0; i < ordered.length - 1; ++i) {
                    var d = Math.hypot(ordered[i + 1].x - ordered[i].x, ordered[i + 1].y - ordered[i].y);
                    segLens.push(d);
                    totalLen += d;
                }

                var dotCount = 3;
                for (var k = 0; k < dotCount; ++k) {
                    var phase = (root.flowPhase + k / dotCount) % 1.0;
                    var targetDist = phase * totalLen;
                    var acc = 0;
                    var px = ordered[0].x;
                    var py = ordered[0].y;
                    for (var j = 0; j < segLens.length; ++j) {
                        if (acc + segLens[j] >= targetDist) {
                            var localT = segLens[j] > 0 ? (targetDist - acc) / segLens[j] : 0;
                            px = ordered[j].x + (ordered[j + 1].x - ordered[j].x) * localT;
                            py = ordered[j].y + (ordered[j + 1].y - ordered[j].y) * localT;
                            break;
                        }
                        acc += segLens[j];
                    }

                    // Soft outer glow + accent ring + bright white core
                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(px, py, 8.5, 0, Math.PI * 2);
                    ctx.fillStyle = Qt.rgba(pulseColor.r, pulseColor.g, pulseColor.b, 0.26);
                    ctx.fill();

                    ctx.beginPath();
                    ctx.arc(px, py, 4.8, 0, Math.PI * 2);
                    ctx.fillStyle = pulseColor;
                    ctx.fill();

                    ctx.beginPath();
                    ctx.arc(px, py, 2.1, 0, Math.PI * 2);
                    ctx.fillStyle = "#FFFFFF";
                    ctx.fill();
                    ctx.restore();
                }
            }

            // 1) Solar (Top-Left) -> Inverter (Left-Upper)
            var solarPts = [
                {x: leftX + halfTile + 4, y: topY},
                {x: midLeftX, y: topY},
                {x: midLeftX, y: cy - invOffsetY},
                {x: cx - invHalf - 6, y: cy - invOffsetY}
            ];
            drawOrthogonalFlow(solarPts, root.generationPowerW > 10, false, Theme.solar, true);

            // 2) Grid (Top-Right) <-> Inverter (Right-Upper)
            // gridPowerW > 0 => importing (Grid -> Inverter), < 0 => exporting (Inverter -> Grid)
            var gridPts = [
                {x: rightX - halfTile - 4, y: topY},
                {x: midRightX, y: topY},
                {x: midRightX, y: cy - invOffsetY},
                {x: cx + invHalf + 6, y: cy - invOffsetY}
            ];
            drawOrthogonalFlow(gridPts, Math.abs(root.gridPowerW) > 10, root.gridPowerW < 0, Theme.accent, true);

            // Green "On grid" checkmark badge on the Grid vertical segment
            var badgeX = midRightX;
            var badgeY = (topY + (cy - invOffsetY)) / 2;
            ctx.save();
            ctx.beginPath();
            ctx.arc(badgeX, badgeY, 9.5, 0, Math.PI * 2);
            ctx.fillStyle = Theme.success;
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(badgeX - 4, badgeY + 0.2);
            ctx.lineTo(badgeX - 1.2, badgeY + 3.2);
            ctx.lineTo(badgeX + 4.5, badgeY - 3.0);
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.strokeStyle = "#FFFFFF";
            ctx.stroke();
            ctx.restore();

            // 3) Battery (Bottom-Left) <-> Inverter (Left-Lower)
            // batteryPowerW < 0 => discharging (Battery -> Inverter), > 0 => charging (Inverter -> Battery)
            var battPts = [
                {x: leftX + halfTile + 4, y: botY},
                {x: midLeftX, y: botY},
                {x: midLeftX, y: cy + invOffsetY},
                {x: cx - invHalf - 6, y: cy + invOffsetY}
            ];
            drawOrthogonalFlow(battPts, Math.abs(root.batteryPowerW) > 10, root.batteryPowerW > 0, Theme.accent, true);

            // 4) Inverter (Right-Lower) -> Home Load (Bottom-Right)
            var loadPts = [
                {x: cx + invHalf + 6, y: cy + invOffsetY},
                {x: midRightX, y: cy + invOffsetY},
                {x: midRightX, y: botY},
                {x: rightX - halfTile - 4, y: botY}
            ];
            drawOrthogonalFlow(loadPts, root.consumptionPowerW > 10, false, Theme.accent, true);
        }
    }

    // ===================== NODE 1: SOLAR PV (TOP-LEFT) =====================
    Item {
        x: root.padX - width / 2
        y: root.topNodeY - root.tileSize / 2
        width: 110
        height: 92

        Rectangle {
            id: solarTile
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.tileSize
            height: root.tileSize
            radius: 14
            color: Theme.bgElevated
            border.color: root.generationPowerW > 10 ? Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.7) : Theme.border
            border.width: 1.2

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.textPrimary;
                    ctx.lineWidth = 1.8;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    // Trapezoid solar panel
                    ctx.beginPath();
                    ctx.moveTo(18, 22);
                    ctx.lineTo(38, 22);
                    ctx.lineTo(43, 39);
                    ctx.lineTo(13, 39);
                    ctx.closePath();
                    ctx.stroke();

                    // Grid lines inside panel
                    ctx.beginPath();
                    ctx.moveTo(15.5, 30.5);
                    ctx.lineTo(40.5, 30.5);
                    ctx.moveTo(24.5, 22);
                    ctx.lineTo(22.5, 39);
                    ctx.moveTo(31.5, 22);
                    ctx.lineTo(33.5, 39);
                    ctx.stroke();

                    // Small sun arc above
                    ctx.strokeStyle = Theme.solar;
                    ctx.beginPath();
                    ctx.arc(28, 17, 3.2, Math.PI, 0);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(28, 10.5); ctx.lineTo(28, 12.2);
                    ctx.moveTo(22.5, 13); ctx.lineTo(23.8, 14.2);
                    ctx.moveTo(33.5, 13); ctx.lineTo(32.2, 14.2);
                    ctx.stroke();
                }
            }
        }

        Label {
            anchors.top: solarTile.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: appController.formatPower(root.generationPowerW)
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.textPrimary
        }
    }

    // ===================== NODE 2: GRID (TOP-RIGHT) =====================
    Item {
        x: (root.width - root.padX) - width / 2
        y: root.topNodeY - root.tileSize / 2
        width: 110
        height: 108

        Rectangle {
            id: gridTile
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.tileSize
            height: root.tileSize
            radius: 14
            color: Theme.bgElevated
            border.color: Math.abs(root.gridPowerW) > 10 ? Qt.rgba(Theme.grid.r, Theme.grid.g, Theme.grid.b, 0.7) : Theme.border
            border.width: 1.2

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.textPrimary;
                    ctx.lineWidth = 1.8;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    // Transmission tower
                    ctx.beginPath();
                    ctx.moveTo(28, 12);
                    ctx.lineTo(18, 42);
                    ctx.moveTo(28, 12);
                    ctx.lineTo(38, 42);
                    // Cross arms
                    ctx.moveTo(16, 20);
                    ctx.lineTo(40, 20);
                    ctx.moveTo(14, 28);
                    ctx.lineTo(42, 28);
                    // Inner braces
                    ctx.moveTo(22, 30);
                    ctx.lineTo(36, 40);
                    ctx.moveTo(34, 30);
                    ctx.lineTo(20, 40);
                    ctx.stroke();
                }
            }
        }

        Label {
            id: gridValLbl
            anchors.top: gridTile.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: appController.formatPower(root.gridPowerW)
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.textPrimary
        }

        Label {
            anchors.top: gridValLbl.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.gridPowerW < -10 ? I18n.t("Exporting") : I18n.t("On grid")
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Theme.success
        }
    }

    // ===================== NODE 3: INVERTER (CENTER) =====================
    Item {
        x: root.centerX - width / 2
        y: root.centerY - 30
        width: 96
        height: 86

        Rectangle {
            id: invTile
            anchors.horizontalCenter: parent.horizontalCenter
            width: 58
            height: 58
            radius: 14
            color: Theme.bgElevated
            border.color: Theme.accent
            border.width: 2

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.textPrimary;
                    ctx.lineWidth = 1.8;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    // Inverter chassis box
                    ctx.strokeRect(18, 13, 22, 32);
                    // Meter circle
                    ctx.beginPath();
                    ctx.arc(29, 23, 4.5, 0, Math.PI * 2);
                    ctx.stroke();
                    // Lower panel divider
                    ctx.beginPath();
                    ctx.moveTo(18, 33);
                    ctx.lineTo(40, 33);
                    ctx.stroke();
                }
            }
        }

        Label {
            anchors.top: invTile.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.t("Inverter")
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.textSecondary
        }
    }

    // ===================== NODE 4: BATTERY (BOTTOM-LEFT) =====================
    Item {
        x: root.padX - width / 2
        y: root.bottomNodeY - root.tileSize / 2
        width: 110
        height: 92

        Rectangle {
            id: battTile
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.tileSize
            height: root.tileSize
            radius: 14
            color: Theme.bgElevated
            border.color: Math.abs(root.batteryPowerW) > 10 ? Qt.rgba(Theme.battery.r, Theme.battery.g, Theme.battery.b, 0.7) : Theme.border
            border.width: 1.2

            Column {
                anchors.centerIn: parent
                spacing: 4

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.hasBatterySoc ? (Math.round(root.batterySoc) + "%") : "—"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.accent
                }

                // Battery icon with live SOC fill
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 1

                    Rectangle {
                        width: 28
                        height: 15
                        radius: 2.5
                        color: "transparent"
                        border.color: Theme.textPrimary
                        border.width: 1.8

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 3
                            width: Math.max(0, (parent.width - 6) * Math.max(0, Math.min(1, root.batterySoc / 100.0)))
                            radius: 1
                            color: root.batterySoc <= 15 ? Theme.errorText : Theme.accent
                        }
                    }

                    Rectangle {
                        width: 3
                        height: 7
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.textPrimary
                    }
                }
            }
        }

        Label {
            anchors.top: battTile.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: appController.formatPower(root.batteryPowerW)
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.textPrimary
        }
    }

    // ===================== NODE 5: HOME LOAD (BOTTOM-RIGHT) =====================
    Item {
        x: (root.width - root.padX) - width / 2
        y: root.bottomNodeY - root.tileSize / 2
        width: 110
        height: 92

        Rectangle {
            id: loadTile
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.tileSize
            height: root.tileSize
            radius: 14
            color: Theme.bgElevated
            border.color: root.consumptionPowerW > 10 ? Qt.rgba(Theme.load.r, Theme.load.g, Theme.load.b, 0.7) : Theme.border
            border.width: 1.2

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.textPrimary;
                    ctx.lineWidth = 1.8;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    // House roof & walls
                    ctx.beginPath();
                    ctx.moveTo(14, 27);
                    ctx.lineTo(28, 15);
                    ctx.lineTo(42, 27);
                    ctx.moveTo(18, 25);
                    ctx.lineTo(18, 41);
                    ctx.lineTo(38, 41);
                    ctx.lineTo(38, 25);
                    ctx.stroke();

                    // Small lightbulb / door accent inside house
                    ctx.beginPath();
                    ctx.arc(28, 31, 3.5, 0, Math.PI * 2);
                    ctx.moveTo(28, 34.5);
                    ctx.lineTo(28, 37.5);
                    ctx.stroke();
                }
            }
        }

        Label {
            anchors.top: loadTile.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: appController.formatPower(root.consumptionPowerW)
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.textPrimary
        }
    }
}
