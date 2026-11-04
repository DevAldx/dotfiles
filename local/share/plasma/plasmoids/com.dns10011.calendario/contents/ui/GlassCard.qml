import QtQuick
import Qt5Compat.GraphicalEffects

/*
    Tarjeta de cristal para los widgets.
    - Entra con un deslizamiento + escala (appearDelay para escalonar).
    - Al pasar el ratón se eleva un poco y el borde se ilumina.
    - "away" la saca de la pantalla hacia awayDx (se usa al escribir).
*/
Item {
    id: card

    default property alias content: inner.data
    property real padding: 14
    property real radius: 20
    property int appearDelay: 0
    property real appearDx: 0
    property bool away: false
    property real awayDx: 0
    property color tint: Fx.accent

    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: inner.childrenRect.height + padding * 2

    // estado de entrada
    property real _intro: 0
    opacity: _intro * (away ? 0 : 1)
    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

    transform: [
        Translate {
            x: (1 - card._intro) * card.appearDx + (card.away ? card.awayDx : 0)
            y: (1 - card._intro) * 24 - (hover.hovered && !card.away ? 3 : 0)
            Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        },
        Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: 0.94 + 0.06 * card._intro
            yScale: xScale
        }
    ]

    SequentialAnimation {
        running: true
        PauseAnimation { duration: card.appearDelay }
        NumberAnimation { target: card; property: "_intro"; from: 0; to: 1; duration: 820; easing.type: Easing.OutExpo }
    }

    HoverHandler { id: hover }

    // Sombra suave
    RectangularGlow {
        anchors.fill: bg
        glowRadius: 14
        spread: 0.1
        cornerRadius: card.radius + glowRadius
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: card.radius
        color: hover.hovered ? Fx.glassHover : Fx.glass
        border.width: 1
        border.color: hover.hovered ? Qt.rgba(card.tint.r, card.tint.g, card.tint.b, 0.65) : Fx.stroke
        Behavior on color { ColorAnimation { duration: 220 } }
        Behavior on border.color { ColorAnimation { duration: 220 } }

        // reflejo de borde (cristal líquido): línea brillante arriba que se
        // desvanece hacia los lados
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: card.radius * 0.6; rightMargin: card.radius * 0.6 }
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.55) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.30) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.05) }
            }
        }

        // reflejo superior tipo cristal
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: parent.height * 0.45
            radius: card.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }

    Item {
        id: inner
        x: card.padding
        y: card.padding
        width: card.width - card.padding * 2
        height: card.height - card.padding * 2
    }
}
