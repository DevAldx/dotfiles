import QtQuick
import QtQuick.Shapes as S

/*
    Luces de colores que flotan detrás de la interfaz.
    - En reposo son muy sutiles.
    - Mientras escribes se encienden, se juntan hacia el centro y cada tecla
      les da un pulso de brillo.
*/
Item {
    id: aurora

    property bool active: false
    property real pulse: 0
    property real mix: active ? 1 : 0
    Behavior on mix { NumberAnimation { duration: 1400; easing.type: Easing.InOutCubic } }

    Connections {
        target: Fx
        function onKeystroke() { pulseAnim.restart(); }
    }
    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: aurora; property: "pulse"; to: 1; duration: 90 }
        NumberAnimation { target: aurora; property: "pulse"; to: 0; duration: 700; easing.type: Easing.OutCubic }
    }

    // velo oscuro para concentrar la atención en el centro
    Rectangle {
        anchors.fill: parent
        color: "#05060c"
        opacity: aurora.active ? 0.38 : 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }

    component Blob: Item {
        id: blob
        property color tint
        property real baseX
        property real baseY
        property real focusX: aurora.width / 2
        property real focusY: aurora.height * 0.55
        property real size: Math.max(aurora.width, aurora.height) * 0.55
        property real phase: 0
        property int period: 9000

        width: size; height: size
        x: baseX + (focusX - baseX) * 0.65 * aurora.mix - width / 2
        y: baseY + (focusY - baseY) * 0.65 * aurora.mix - height / 2
        transform: Translate { x: blob.driftX; y: blob.driftY }

        property real driftX: 0
        property real driftY: 0
        SequentialAnimation on driftX {
            loops: Animation.Infinite
            NumberAnimation { to: 60; duration: blob.period; easing.type: Easing.InOutSine }
            NumberAnimation { to: -60; duration: blob.period; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on driftY {
            loops: Animation.Infinite
            NumberAnimation { to: -40; duration: blob.period * 0.8; easing.type: Easing.InOutSine }
            NumberAnimation { to: 40; duration: blob.period * 0.8; easing.type: Easing.InOutSine }
        }

        scale: 1 + aurora.pulse * 0.08
        S.Shape {
            anchors.fill: parent
            preferredRendererType: S.Shape.CurveRenderer
            S.ShapePath {
                strokeWidth: -1
                strokeColor: "transparent"
                fillGradient: S.RadialGradient {
                    centerX: blob.width / 2; centerY: blob.height / 2; centerRadius: blob.width / 2
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0.55) }
                    GradientStop { position: 0.5; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0.14) }
                    GradientStop { position: 1.0; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0) }
                }
                startX: blob.width / 2; startY: 0
                PathArc { x: blob.width / 2; y: blob.height; radiusX: blob.width / 2; radiusY: blob.height / 2 }
                PathArc { x: blob.width / 2; y: 0; radiusX: blob.width / 2; radiusY: blob.height / 2 }
            }
        }
    }

    Item {
        id: blobs
        anchors.fill: parent
        opacity: (aurora.active ? 0.75 : 0.22) + aurora.pulse * 0.25
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Blob { tint: Fx.accent;  baseX: aurora.width * 0.15; baseY: aurora.height * 0.25; period: 9000 }
        Blob { tint: Fx.accent2; baseX: aurora.width * 0.85; baseY: aurora.height * 0.30; period: 11000 }
        Blob { tint: Fx.accent3; baseX: aurora.width * 0.50; baseY: aurora.height * 0.95; period: 13000; size: Math.max(aurora.width, aurora.height) * 0.45 }
    }
}
