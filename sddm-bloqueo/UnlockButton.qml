import QtQuick
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects

// Botón de desbloqueo redondo. Candado cuando está vacío; cuando hay texto
// se llena con el degradado, muestra una flecha y "respira".
QQC2.AbstractButton {
    id: btn

    property bool ready: false

    implicitWidth: 50
    implicitHeight: 50
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    scale: pressed ? 0.9 : (hovered ? 1.06 : 1)
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    background: Item {
        RectangularGlow {
            anchors.fill: circle
            glowRadius: 14; spread: 0.2
            cornerRadius: circle.radius + glowRadius
            color: Fx.accent2
            opacity: btn.ready ? 0.45 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        Rectangle {
            id: circle
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(0.05, 0.06, 0.12, 0.55)
            border.width: 1
            border.color: btn.activeFocus || btn.hovered ? Fx.strokeHover : Qt.rgba(1, 1, 1, 0.28)
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            opacity: btn.ready ? 1 : 0
            scale: btn.ready ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: 260 } }
            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Fx.accent }
                GradientStop { position: 1; color: Fx.accent2 }
            }
            SequentialAnimation on scale {
                running: btn.ready
                loops: Animation.Infinite
                NumberAnimation { to: 1.06; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
    }

    contentItem: Item {
        Glyph {
            anchors.centerIn: parent
            size: 21
            text: Fx.icUnlock
            opacity: btn.ready ? 0 : 1
            scale: btn.ready ? 0.3 : 1
            rotation: btn.ready ? 90 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
            Behavior on rotation { NumberAnimation { duration: 320 } }
        }
        Glyph {
            anchors.centerIn: parent
            size: 24
            text: Fx.icArrowR
            color: "#0b0f1e"
            opacity: btn.ready ? 1 : 0
            anchors.horizontalCenterOffset: btn.ready ? (btn.hovered ? 3 : 0) : -14
            Behavior on opacity { NumberAnimation { duration: 260 } }
            Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
        }
    }
}
