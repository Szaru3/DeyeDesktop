import QtQuick
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
    implicitHeight: 310

    NumberAnimation on flowPhase {
        from: 0.0
        to: 1.0
        duration: 1800
        loops: Animation.Infinite
        running: root.visible
    }

    onFlowPhaseChanged: canvas.requestPaint()
    onGenerationPowerWChanged: canvas.requestPaint()
    onConsumptionPowerWChanged: canvas.requestPaint()
    onBatteryPowerWChanged: canvas.requestPaint()
    onGridPowerWChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;
            var topY = 58;
            var bottomY = height - 58;
            var leftX = Math.max(105, width * 0.22);
            var rightX = Math.min(width - 105, width * 0.78);

            function drawFlowLine(x1, y1, x2, y2, active, reverse, strokeColor) {
                // Base track
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.lineWidth = 3;
                ctx.strokeStyle = active ? strokeColor : "#26334D";
                ctx.globalAlpha = active ? 0.45 : 0.6;
                ctx.stroke();
                ctx.globalAlpha = 1.0;

                if (!active) return;

                // Animated energy pulses along line
                var sx = reverse ? x2 : x1;
                var sy = reverse ? y2 : y1;
                var ex = reverse ? x1 : x2;
                var ey = reverse ? y1 : y2;

                var dots = 3;
                for (var i = 0; i < dots; ++i) {
                    var t = (root.flowPhase + i / dots) % 1.0;
                    var px = sx + (ex - sx) * t;
                    var py = sy + (ey - sy) * t;

                    ctx.beginPath();
                    ctx.arc(px, py, 4.5, 0, Math.PI * 2);
                    ctx.fillStyle = strokeColor;
                    ctx.fill();
                }
            }

            // Solar (Top) -> Inverter (Center)
            drawFlowLine(cx, topY + 34, cx, cy - 34,
                         root.generationPowerW > 10, false, Theme.solar);

            // Inverter (Center) <-> Battery (Left)
            // batteryPowerW > 0 => charging (Center -> Left), < 0 => discharging (Left -> Center)
            drawFlowLine(cx - 42, cy, leftX + 54, cy,
                         Math.abs(root.batteryPowerW) > 10,
                         root.batteryPowerW < 0,
                         Theme.battery);

            // Grid (Right) <-> Inverter (Center)
            // gridPowerW > 0 => importing (Right -> Center), < 0 => exporting (Center -> Right)
            drawFlowLine(rightX - 54, cy, cx + 42, cy,
                         Math.abs(root.gridPowerW) > 10,
                         root.gridPowerW < 0,
                         Theme.grid);

            // Inverter (Center) -> Home Load (Bottom)
            drawFlowLine(cx, cy + 34, cx, bottomY - 34,
                         root.consumptionPowerW > 10, false, Theme.load);
        }
    }

    // Center Inverter Hub
    Rectangle {
        width: 84
        height: 68
        radius: 14
        anchors.centerIn: parent
        color: Theme.bgElevated
        border.color: Theme.accent
        border.width: 1.5

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "DEYE"
                color: Theme.accent
                font.pixelSize: 13
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "Inverter"
                color: Theme.textSecondary
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Top Node: Solar PV
    Rectangle {
        width: 132
        height: 64
        radius: 12
        x: (parent.width - width) / 2
        y: 24
        color: Theme.solarSoft
        border.color: Theme.solar
        border.width: 1.2

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "SOLAR PV"
                color: Theme.solar
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.generationPowerW)
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Left Node: Battery
    Rectangle {
        width: 136
        height: 76
        radius: 12
        x: Math.max(105, parent.width * 0.22) - width / 2
        y: (parent.height - height) / 2
        color: Theme.batterySoft
        border.color: Theme.battery
        border.width: 1.2

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: root.hasBatterySoc
                      ? ("BATTERY • " + Math.round(root.batterySoc) + "%")
                      : "BATTERY"
                color: Theme.battery
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.batteryPowerW)
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.batteryPowerW > 10 ? "Charging"
                    : root.batteryPowerW < -10 ? "Discharging"
                    : "Idle"
                color: Theme.textSecondary
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Right Node: Grid
    Rectangle {
        width: 136
        height: 76
        radius: 12
        x: Math.min(parent.width - 105, parent.width * 0.78) - width / 2
        y: (parent.height - height) / 2
        color: Theme.gridSoft
        border.color: Theme.grid
        border.width: 1.2

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "GRID"
                color: Theme.grid
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.gridPowerW)
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.gridPowerW > 10 ? "Importing"
                    : root.gridPowerW < -10 ? "Exporting"
                    : "Balanced"
                color: Theme.textSecondary
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Bottom Node: Home Load
    Rectangle {
        width: 132
        height: 64
        radius: 12
        x: (parent.width - width) / 2
        y: parent.height - height - 24
        color: Theme.loadSoft
        border.color: Theme.load
        border.width: 1.2

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "HOME LOAD"
                color: Theme.load
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.consumptionPowerW)
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
