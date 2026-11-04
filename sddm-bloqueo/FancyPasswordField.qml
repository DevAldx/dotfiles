import QtQuick
import QtQuick.Particles
import Qt5Compat.GraphicalEffects

import org.kde.plasma.extras as PlasmaExtras

/*
    Campo de contraseña animado.

    - No muestra caracteres: dibuja un punto por carácter que "explota" al
      aparecer y cambia de color.
    - Cada tecla lanza una ráfaga de partículas desde el cursor, una onda
      alrededor del campo y un pequeño rebote.
    - Con el foco, el borde es un degradado que gira.
    - Barra inferior que se llena según la longitud.
    - Al fallar, el borde se pone rojo (Fx.rejected()).
    - Publica la longitud en Fx.typed para que el resto de la interfaz cambie.
*/
PlasmaExtras.PasswordField {
    id: field

    property int lastLen: 0
    property real flash: 0
    property real errorFlash: 0
    readonly property bool masked: !showPassword

    onTextChanged: {
        if (text.length > lastLen && visible && activeFocus) {
            keyAnim.restart();
            burst.burst(10, caret.x + caret.width / 2, height / 2);
            Fx.keystroke();
        }
        lastLen = text.length;
        Fx.typed = text.length;
    }
    Component.onDestruction: Fx.typed = 0
    onVisibleChanged: if (!visible) Fx.typed = 0

    Connections {
        target: Fx
        function onRejected() { errAnim.restart(); }
    }

    color: masked ? "transparent" : "white"
    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
    selectionColor: masked ? "transparent" : Qt.rgba(0.55, 0.76, 1.0, 0.45)
    selectedTextColor: masked ? "transparent" : "white"
    cursorDelegate: Item { width: 0; height: 0 }
    leftPadding: 18
    rightPadding: 18
    topPadding: 13
    bottomPadding: 13
    horizontalAlignment: TextInput.AlignLeft

    SequentialAnimation {
        id: keyAnim
        ParallelAnimation {
            NumberAnimation { target: field; property: "flash"; from: 1; to: 0; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring; property: "scale"; from: 1.0; to: 1.12; duration: 560; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 560; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: field; property: "scale"; to: 1.03; duration: 70; easing.type: Easing.OutQuad }
                NumberAnimation { target: field; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3 }
            }
        }
    }
    SequentialAnimation {
        id: errAnim
        NumberAnimation { target: field; property: "errorFlash"; from: 0; to: 1; duration: 120 }
        PauseAnimation { duration: 700 }
        NumberAnimation { target: field; property: "errorFlash"; to: 0; duration: 600; easing.type: Easing.OutCubic }
    }

    background: Item {
        implicitWidth: 300
        implicitHeight: 50

        // onda por tecla
        Rectangle {
            id: ring
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Fx.accent2
            opacity: 0
        }

        // resplandor exterior cuando hay foco
        RectangularGlow {
            anchors.fill: base
            glowRadius: 16
            spread: 0.15
            cornerRadius: base.radius + glowRadius
            color: field.errorFlash > 0 ? Fx.danger : Fx.accent
            opacity: (field.activeFocus ? 0.28 : 0) + field.flash * 0.35 + field.errorFlash * 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {
            id: base
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(0.05 + field.flash * 0.10, 0.06 + field.flash * 0.10, 0.12 + field.flash * 0.18, 0.55)
            border.width: 1
            border.color: field.activeFocus ? "transparent" : Qt.rgba(1, 1, 1, 0.28)
        }

        // borde degradado que gira
        Item {
            id: gradBorder
            anchors.fill: parent
            visible: field.activeFocus
            opacity: field.activeFocus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 260 } }

            ConicalGradient {
                id: cone
                anchors.fill: parent
                visible: false
                angle: 0
                gradient: Gradient {
                    GradientStop { position: 0.00; color: field.errorFlash > 0 ? Fx.danger : Fx.accent }
                    GradientStop { position: 0.33; color: field.errorFlash > 0 ? Fx.danger : Fx.accent2 }
                    GradientStop { position: 0.66; color: field.errorFlash > 0 ? "#ffb0b8" : Fx.accent3 }
                    GradientStop { position: 1.00; color: field.errorFlash > 0 ? Fx.danger : Fx.accent }
                }
                NumberAnimation on angle {
                    running: field.activeFocus
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: Fx.typing ? 2600 : 6000
                }
            }
            Rectangle {
                id: borderMask
                anchors.fill: parent
                radius: height / 2
                color: "transparent"
                border.width: 1.8 + field.flash * 1.2
                visible: false
            }
            OpacityMask {
                anchors.fill: parent
                source: cone
                maskSource: borderMask
            }
        }

        // destello interior
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(Fx.accent.r, Fx.accent.g, Fx.accent.b, 0.35) }
                GradientStop { position: 1; color: Qt.rgba(Fx.accent2.r, Fx.accent2.g, Fx.accent2.b, 0.35) }
            }
            opacity: field.flash * 0.6
        }

        // puntos de la contraseña
        Item {
            id: dotsArea
            anchors.fill: parent
            anchors.leftMargin: field.leftPadding
            anchors.rightMargin: field.rightPadding
            clip: true
            visible: field.masked

            Row {
                id: dots
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                // si no caben, se desplaza para mostrar siempre los últimos
                x: Math.min(0, dotsArea.width - width - 14)
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Repeater {
                    model: field.text.length
                    Rectangle {
                        id: dot
                        required property int index
                        width: 10; height: 10; radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        // color según la posición: azul → violeta → menta
                        readonly property real t: (index % 12) / 11
                        color: Qt.rgba(
                            Fx.accent.r * (1 - t) + Fx.accent2.r * t,
                            Fx.accent.g * (1 - t) + Fx.accent2.g * t,
                            Fx.accent.b * (1 - t) + Fx.accent2.b * t, 1)
                        scale: 0
                        Component.onCompleted: popDot.start()
                        SequentialAnimation {
                            id: popDot
                            NumberAnimation { target: dot; property: "scale"; from: 0; to: 1.7; duration: 110; easing.type: Easing.OutQuad }
                            NumberAnimation { target: dot; property: "scale"; to: 1.0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 3 }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 18; height: 18; radius: 9
                            color: dot.color
                            opacity: 0.25
                        }
                    }
                }
            }
        }

        // cursor
        Rectangle {
            id: caret
            x: field.masked
                ? field.leftPadding + Math.min(dots.width + dots.x + (field.text.length > 0 ? 8 : 0), dotsArea.width)
                : field.leftPadding + field.cursorRectangle.x
            anchors.verticalCenter: parent.verticalCenter
            width: 2; height: 20; radius: 1
            color: Fx.accent3
            visible: field.activeFocus && (field.text.length > 0 || !field.masked)
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: caret.visible
                NumberAnimation { to: 0; duration: 520; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
            }
        }

        // barra de longitud
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 8
            width: parent.width * 0.6
            height: 3; radius: 1.5
            color: Qt.rgba(1, 1, 1, 0.08)
            opacity: Fx.typing ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Rectangle {
                height: parent.height; radius: 1.5
                width: parent.width * Math.min(1, field.text.length / 12)
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Fx.accent }
                    GradientStop { position: 0.5; color: Fx.accent2 }
                    GradientStop { position: 1; color: Fx.accent3 }
                }
            }
        }

        // partículas
        ParticleSystem { id: psys }
        ImageParticle {
            system: psys
            source: "qrc:///particleresources/glowdot.png"
            color: Fx.accent2
            colorVariation: 0.35
            alpha: 0.9
            entryEffect: ImageParticle.Scale
        }
        Emitter {
            id: burst
            system: psys
            width: 2; height: 2
            enabled: false
            lifeSpan: 700
            lifeSpanVariation: 250
            size: 12
            sizeVariation: 6
            endSize: 2
            velocity: AngleDirection { angleVariation: 360; magnitude: 110; magnitudeVariation: 60 }
            acceleration: PointDirection { y: -60 }
        }
    }
}
