import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.ksysguard.sensors as Sensors

// Estado del sistema: anillos de CPU y RAM, disco, temperatura y red.
GlassCard {
    id: root

    width: 300
    height: col.implicitHeight + padding * 2
    tint: Fx.accent3

    Sensors.Sensor { id: cpu;  sensorId: "cpu/all/usage";               updateRateLimit: 2000 }
    Sensors.Sensor { id: ram;  sensorId: "memory/physical/usedPercent"; updateRateLimit: 3000 }
    Sensors.Sensor { id: ramU; sensorId: "memory/physical/used";        updateRateLimit: 3000 }
    Sensors.Sensor { id: ramT; sensorId: "memory/physical/total";       updateRateLimit: 60000 }
    Sensors.Sensor { id: swap; sensorId: "memory/swap/usedPercent";     updateRateLimit: 3000 }
    Sensors.Sensor { id: freq; sensorId: "cpu/all/averageFrequency";    updateRateLimit: 2000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/averageTemperature";  updateRateLimit: 3000 }
    Sensors.Sensor { id: down; sensorId: "network/all/download";        updateRateLimit: 2000 }
    Sensors.Sensor { id: up;   sensorId: "network/all/upload";          updateRateLimit: 2000 }
    Sensors.Sensor { id: host; sensorId: "os/system/hostname";          updateRateLimit: 600000 }

    function num(s) { const v = Number(s.value); return isNaN(v) ? 0 : v; }
    function speed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s";
        if (bps >= 1024) return Math.round(bps / 1024) + " KB/s";
        return Math.round(bps) + " B/s";
    }
    function gb(b) { return (b / 1073741824).toFixed(1); }
    function heat(p) { return p < 50 ? Fx.accent3 : (p < 80 ? Fx.warm : Fx.danger); }

    component Ring: Item {
        id: ring
        property real value: 0          // 0..100
        property color color: Fx.accent
        property string label
        property string icon
        property string sub
        property real shown: value
        Behavior on shown { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        implicitWidth: 112
        implicitHeight: 112 + 34

        Item {
            id: dial
            width: 112; height: 112
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.09); strokeWidth: 9; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 56; centerY: 56; radiusX: 48; radiusY: 48; startAngle: 135; sweepAngle: 270 }
                }
                ShapePath {
                    strokeWidth: 9; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    strokeColor: ring.color
                    PathAngleArc { centerX: 56; centerY: 56; radiusX: 48; radiusY: 48; startAngle: 135; sweepAngle: Math.max(0.5, 270 * Math.min(100, ring.shown) / 100) }
                }
            }
            // punto brillante en la punta
            Rectangle {
                readonly property real a: (135 + 270 * Math.min(100, ring.shown) / 100) * Math.PI / 180
                x: 56 + 48 * Math.cos(a) - width / 2
                y: 56 + 48 * Math.sin(a) - height / 2
                width: 13; height: 13; radius: 6.5
                color: "white"
                border.width: 3; border.color: ring.color
            }
            Column {
                anchors.centerIn: parent
                spacing: -2
                Glyph { anchors.horizontalCenter: parent.horizontalCenter; size: 16; text: ring.icon; color: ring.color }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(ring.shown) + "%"
                    color: "white"
                    font.family: FontConfig.family; font.pixelSize: 22; font.weight: Font.DemiBold
                }
            }
        }
        Column {
            anchors.top: dial.bottom
            anchors.topMargin: -4
            anchors.horizontalCenter: dial.horizontalCenter
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ring.label; color: "white"; opacity: 0.85; font.family: FontConfig.family; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ring.sub; color: "white"; opacity: 0.5; font.family: FontConfig.family; font.pixelSize: 10 }
        }
    }

    component Bar: RowLayout {
        id: bar
        property string icon
        property string label
        property string valueText
        property real value: 0
        property color color: Fx.accent
        Layout.fillWidth: true
        spacing: 8
        Glyph { size: 15; text: bar.icon; color: bar.color; Layout.preferredWidth: 18 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Text { text: bar.label; color: "white"; opacity: 0.75; font.family: FontConfig.family; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: bar.valueText; color: "white"; font.family: FontConfig.family; font.pixelSize: 11; font.weight: Font.DemiBold }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.09)
                visible: bar.value >= 0
                Rectangle {
                    height: parent.height; radius: 2
                    width: parent.width * Math.min(1, Math.max(0, bar.value) / 100)
                    color: bar.color
                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Glyph { size: 18; text: Fx.g(0xf0322); color: Fx.accent3 }
            Text { text: "Sistema"; color: "white"; font.family: FontConfig.family; font.pixelSize: 15; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Text { text: host.value || ""; color: "white"; opacity: 0.45; font.family: FontConfig.family; font.pixelSize: 10; elide: Text.ElideLeft; Layout.maximumWidth: 140 }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            Ring {
                label: "CPU"; icon: Fx.g(0xf0ee0)
                value: root.num(cpu)
                color: root.heat(value)
                sub: root.num(temp) > 0 ? Math.round(root.num(temp)) + " °C" : ""
            }
            Ring {
                label: "RAM"; icon: Fx.g(0xf035b)
                value: root.num(ram)
                color: value < 70 ? Fx.accent2 : (value < 88 ? Fx.warm : Fx.danger)
                sub: root.gb(root.num(ramU)) + " / " + root.gb(root.num(ramT)) + " GB"
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.10) }

        Bar { icon: Fx.g(0xf02ca); label: "Swap (zram)"; value: root.num(swap); valueText: Math.round(root.num(swap)) + "%"; color: root.num(swap) < 60 ? Fx.accent : Fx.danger }
        Bar { icon: Fx.g(0xf04c5); label: "Frecuencia CPU"; value: -1; valueText: (root.num(freq) / 1000).toFixed(2) + " GHz"; color: Fx.warm }
        Bar { icon: Fx.g(0xf01da); label: "Bajada"; value: -1; valueText: root.speed(root.num(down)); color: Fx.accent3 }
        Bar { icon: Fx.g(0xf0552); label: "Subida"; value: -1; valueText: root.speed(root.num(up)); color: Fx.accent2 }
    }
}
