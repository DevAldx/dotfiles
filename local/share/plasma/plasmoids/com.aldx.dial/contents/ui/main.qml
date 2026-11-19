import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// Reloj analógico: anillo de minutos con aguja de cristal, punto de segundos
// y una subesfera inferior con las horas.
PlasmoidItem {
    id: main
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: root
        readonly property real size: 240
        Layout.minimumWidth: size
        Layout.minimumHeight: size
        Layout.preferredWidth: size
        Layout.preferredHeight: size
        Layout.maximumWidth: size
        Layout.maximumHeight: size

        readonly property string mono: "CaskaydiaMono Nerd Font Mono"
        readonly property color ink: "#e6ebff"
        readonly property color glow: "#a9bfff"

        property date now: new Date()
        Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

        readonly property real sec: now.getSeconds()
        readonly property real min: now.getMinutes() + sec / 60
        readonly property real hr: (now.getHours() % 12) + now.getMinutes() / 60

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        readonly property real rr: Math.min(width, height) / 2 - 4
        // subesfera de horas
        readonly property real scx: cx
        readonly property real scy: cy + rr * 0.38
        readonly property real sr: rr * 0.29

        // disco de cristal
        Rectangle {
            x: root.cx - root.rr; y: root.cy - root.rr
            width: root.rr * 2; height: width; radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.13) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(0.6, 0.7, 1, 0.08) }
            }
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.20)
        }
        // subesfera
        Rectangle {
            x: root.scx - root.sr; y: root.scy - root.sr
            width: root.sr * 2; height: width; radius: width / 2
            color: Qt.rgba(0.02, 0.03, 0.08, 0.30)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)
        }

        Canvas {
            id: face
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                c.lineCap = "round";
                const R = root.rr, cx = root.cx, cy = root.cy;
                // marcas de minutos
                for (let i = 0; i < 60; i++) {
                    const a = (i * 6 - 90) * Math.PI / 180;
                    const major = i % 5 === 0;
                    const r1 = R - 7, r2 = major ? R - 17 : R - 12;
                    c.strokeStyle = major ? "rgba(230,235,255,0.95)" : "rgba(230,235,255,0.40)";
                    c.lineWidth = major ? 2.4 : 1.1;
                    c.beginPath();
                    c.moveTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a));
                    c.lineTo(cx + r2 * Math.cos(a), cy + r2 * Math.sin(a));
                    c.stroke();
                }
                // números 00..55
                c.fillStyle = "rgba(230,235,255,0.92)";
                c.font = "bold 13px '" + root.mono + "'";
                c.textAlign = "center";
                c.textBaseline = "middle";
                for (let i = 0; i < 12; i++) {
                    const a = (i * 30 - 90) * Math.PI / 180;
                    const r = R - 31;
                    const t = (i * 5 < 10 ? "0" : "") + (i * 5);
                    c.fillText(t, cx + r * Math.cos(a), cy + r * Math.sin(a));
                }
                // subesfera: marcas y números de hora
                const sx = root.scx, sy = root.scy, sr = root.sr;
                for (let i = 0; i < 12; i++) {
                    const a = (i * 30 - 90) * Math.PI / 180;
                    const major = i % 3 === 0;
                    c.strokeStyle = major ? "rgba(230,235,255,0.9)" : "rgba(230,235,255,0.4)";
                    c.lineWidth = major ? 2 : 1;
                    c.beginPath();
                    c.moveTo(sx + (sr - 4) * Math.cos(a), sy + (sr - 4) * Math.sin(a));
                    c.lineTo(sx + (sr - (major ? 9 : 7)) * Math.cos(a), sy + (sr - (major ? 9 : 7)) * Math.sin(a));
                    c.stroke();
                }
                c.font = "bold 10px '" + root.mono + "'";
                const hs = ["12", "3", "6", "9"];
                for (let i = 0; i < 4; i++) {
                    const a = (i * 90 - 90) * Math.PI / 180;
                    const r = sr - 17;
                    c.fillText(hs[i], sx + r * Math.cos(a), sy + r * Math.sin(a));
                }
            }
        }

        // aguja de horas (subesfera)
        Item {
            x: root.scx; y: root.scy
            rotation: root.hr * 30
            Rectangle {
                x: -1.5; y: -(root.sr - 10)
                width: 3; height: root.sr - 10; radius: 1.5
                color: root.ink
            }
        }
        Rectangle {
            x: root.scx - 3; y: root.scy - 3; width: 6; height: 6; radius: 3
            color: root.ink
        }

        // aguja de minutos: píldora de cristal
        Item {
            x: root.cx; y: root.cy
            rotation: root.min * 6
            Behavior on rotation { RotationAnimation { duration: 600; direction: RotationAnimation.Clockwise; easing.type: Easing.OutCubic } }
            Rectangle {
                readonly property real len: root.rr - 50
                x: -width / 2; y: -len - 12
                width: 10; height: len; radius: 5
                color: Qt.rgba(0.66, 0.75, 1, 0.22)
                border.width: 2
                border.color: root.glow
            }
        }

        // punto de segundos en el borde
        Item {
            x: root.cx; y: root.cy
            rotation: root.sec * 6
            Rectangle {
                x: -3.5; y: -root.rr + 1
                width: 7; height: 7; radius: 3.5
                color: root.glow
            }
        }

        // centro
        Rectangle {
            x: root.cx - 7; y: root.cy - 7; width: 14; height: 14; radius: 7
            color: "#151a2a"
            border.width: 2
            border.color: root.ink
        }
    }
}
