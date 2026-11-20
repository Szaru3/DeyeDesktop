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
    implicitHeight: 300

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
            var topY = 56;
            var bottomY = height - 56;
            var leftX = Math.max(105, width * 0.22);
            var rightX = Math.min(width - 105, width * 0.78);

            function drawFlowLine(x1, y1, x2, y2, active, reverse, strokeColor) {
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.lineWidth = 3;
                ctx.lineCap = "round";
                ctx.strokeStyle = active ? strokeColor : Theme.border;
                ctx.globalAlpha = active ? 0.35 : 0.7;
                ctx.stroke();
                ctx.globalAlpha = 1.0;

                if (!active) return;

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
                    ctx.arc(px, py, 4, 0, Math.PI * 2);
                    ctx.fillStyle = strokeColor;
                    ctx.fill();
                }
            }

            // Solar (Top) -> Inverter (Center)
            drawFlowLine(cx, topY + 32, cx, cy - 32,
                         root.generationPowerW > 10, false, Theme.solar);

            // Inverter (Center) <-> Battery (Left)
            drawFlowLine(cx - 44, cy, leftX + 64, cy,
                         Math.abs(root.batteryPowerW) > 10,
                         root.batteryPowerW < 0,
                         Theme.battery);

            // Grid (Right) <-> Inverter (Center)
            drawFlowLine(rightX - 64, cy, cx + 44, cy,
                         Math.abs(root.gridPowerW) > 10,
                         root.gridPowerW < 0,
                         Theme.grid);

            // Inverter (Center) -> Home Load (Bottom)
            drawFlowLine(cx, cy + 32, cx, bottomY - 32,
                         root.consumptionPowerW > 10, false, Theme.load);
        }
    }

    // Center Inverter Hub
    Rectangle {
        width: 88
        height: 64
        radius: Theme.radiusLg
        anchors.centerIn: parent
        color: Theme.bgElevated
        border.color: Theme.border
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "DEYE"
                color: Theme.accentText
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
        width: 136
        height: 60
        radius: Theme.radiusLg
        x: (parent.width - width) / 2
        y: 22
        color: Theme.solarSoft
        border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.55)
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "Solar PV"
                color: Theme.solar
                font.pixelSize: 11
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.generationPowerW)
                color: Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Left Node: Battery
    Rectangle {
        width: 138
        height: 74
        radius: Theme.radiusLg
        x: Math.max(105, parent.width * 0.22) - width / 2
        y: (parent.height - height) / 2
        color: Theme.batterySoft
        border.color: Qt.rgba(Theme.battery.r, Theme.battery.g, Theme.battery.b, 0.55)
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: root.hasBatterySoc
                      ? ("Battery • " + Math.round(root.batterySoc) + "%")
                      : "Battery"
                color: Theme.battery
                font.pixelSize: 11
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.batteryPowerW)
                color: Theme.textPrimary
                font.pixelSize: 15
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
        width: 138
        height: 74
        radius: Theme.radiusLg
        x: Math.min(parent.width - 105, parent.width * 0.78) - width / 2
        y: (parent.height - height) / 2
        color: Theme.gridSoft
        border.color: Qt.rgba(Theme.grid.r, Theme.grid.g, Theme.grid.b, 0.55)
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "Grid"
                color: Theme.grid
                font.pixelSize: 11
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.gridPowerW)
                color: Theme.textPrimary
                font.pixelSize: 15
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
        width: 136
        height: 60
        radius: Theme.radiusLg
        x: (parent.width - width) / 2
        y: parent.height - height - 22
        color: Theme.loadSoft
        border.color: Qt.rgba(Theme.load.r, Theme.load.g, Theme.load.b, 0.55)
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: "Home Load"
                color: Theme.load
                font.pixelSize: 11
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: appController.formatPower(root.consumptionPowerW)
                color: Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
