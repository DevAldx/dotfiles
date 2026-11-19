import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

// Cuatro indicadores con forma de "galleta" ondulada: el borde se ilumina
// según el valor. Disco, temperatura, RAM y CPU.
PlasmoidItem {
    id: main
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: root
        Layout.minimumWidth: 250
        Layout.minimumHeight: 250
        Layout.preferredWidth: 250
        Layout.preferredHeight: 250
        Layout.maximumWidth: 250
        Layout.maximumHeight: 250

        readonly property string mono: "CaskaydiaMono Nerd Font Mono"
        readonly property string icons: "CaskaydiaMono Nerd Font Propo"

        Sensors.Sensor { id: cpu;   sensorId: "cpu/all/usage";               updateRateLimit: 2000 }
        Sensors.Sensor { id: ramP;  sensorId: "memory/physical/usedPercent"; updateRateLimit: 3000 }
        Sensors.Sensor { id: ramU;  sensorId: "memory/physical/used";        updateRateLimit: 3000 }
        Sensors.Sensor { id: temp;  sensorId: "cpu/all/averageTemperature";  updateRateLimit: 3000 }
        Sensors.Sensor { id: diskP; sensorId: "disk/all/usedPercent";        updateRateLimit: 30000 }
        Sensors.Sensor { id: diskU; sensorId: "disk/all/used";               updateRateLimit: 30000 }

        function num(s) { const v = Number(s.value); return isNaN(v) ? 0 : v; }
        function g(cp) { return String.fromCodePoint(cp); }

        component Cookie: Item {
            id: c
            property real value: 0          // 0..1
            property string icon
            property string big
            property string label
            property real shown: Math.max(0, Math.min(1, value))
            Behavior on shown { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

            width: 116; height: 116
            readonly property real ctr: width / 2
            readonly property real rad: 47
            readonly property int lobes: 9
            readonly property real amp: 3.4

            function pts(t1) {
                const p = [];
                const steps = Math.max(2, Math.ceil(260 * t1));
                for (let i = 0; i <= steps; i++) {
                    const t = t1 * i / steps;
                    const th = t * 2 * Math.PI - Math.PI / 2;
                    const r = rad + amp * Math.cos(lobes * (th + Math.PI / 2));
                    p.push(Qt.point(ctr + r * Math.cos(th), ctr + r * Math.sin(th)));
                }
                return p;
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.16)
                    strokeWidth: 5
                    fillColor: Qt.rgba(0.03, 0.04, 0.09, 0.38)
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: c.pts(1) }
                }
                ShapePath {
                    strokeColor: "#dfe5f8"
                    strokeWidth: 5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: c.pts(Math.max(0.01, c.shown)) }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: c.icon; color: "#dfe5f8"; opacity: 0.8
                    font.family: root.icons; font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: c.big; color: "white"
                    font.family: root.mono; font.pixelSize: 21; font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: c.label; color: "white"; opacity: 0.6
                    font.family: root.mono; font.pixelSize: 10
                }
            }
        }

        Cookie {
            x: 0; y: 18
            icon: root.g(0xf02ca)
            value: root.num(diskP) / 100
            big: Math.round(root.num(diskP)) + "%"
            label: (root.num(diskU) / 1073741824).toFixed(0) + "G"
        }
        Cookie {
            x: 128; y: 0
            icon: root.g(0xf050f)
            value: root.num(temp) / 100
            big: Math.round(root.num(temp)) + "°"
            label: "Temp"
        }
        Cookie {
            x: 0; y: 134
            icon: root.g(0xf035b)
            value: root.num(ramP) / 100
            big: (root.num(ramU) / 1073741824).toFixed(1) + "G"
            label: "RAM"
        }
        Cookie {
            x: 128; y: 116
            icon: root.g(0xf0ee0)
            value: root.num(cpu) / 100
            big: Math.round(root.num(cpu)) + "%"
            label: "CPU"
        }
    }
}
