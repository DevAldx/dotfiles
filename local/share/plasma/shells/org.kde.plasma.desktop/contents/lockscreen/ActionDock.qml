import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/*
    Menú desplazable con todos los iconos (apagar, reiniciar, suspender…).

    Un botón tipo píldora en la parte inferior; al pulsarlo se despliega un
    panel de cristal con una lista horizontal que se puede arrastrar, mover
    con la rueda del ratón o con las flechas. Cada icono entra en cascada.

    actions: lista de objetos
      { icon, label, color, enabled, run: function() {} }
*/
Item {
    id: dock

    property var actions: []
    property bool open: false
    property bool hidden: false          // se oculta mientras escribes
    signal triggered()

    readonly property int tileW: 92
    readonly property int tileH: 104
    readonly property int visibleTiles: Math.min(5, Math.max(1, actions.length))
    readonly property int panelW: visibleTiles * tileW + (visibleTiles - 1) * 8 + 2 * 48
    readonly property int panelH: tileH + 44

    implicitWidth: panelW
    implicitHeight: panelH + pill.height + 12

    function toggle() { open = !open; }
    onHiddenChanged: if (hidden) open = false

    opacity: hidden ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    transform: Translate {
        y: dock.hidden ? 40 : 0
        Behavior on y { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
    }

    Keys.onEscapePressed: event => { if (open) { open = false; event.accepted = true; } else event.accepted = false; }

    // ---------- Panel ----------
    Item {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: pill.top
        anchors.bottomMargin: 12
        width: dock.panelW
        height: dock.panelH

        property real reveal: dock.open ? 1 : 0
        Behavior on reveal { NumberAnimation { duration: dock.open ? 560 : 320; easing.type: dock.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.2 } }
        visible: reveal > 0.01
        opacity: Math.min(1, reveal * 1.4)
        transform: [
            Scale { origin.x: panel.width / 2; origin.y: panel.height; xScale: 0.6 + 0.4 * panel.reveal; yScale: 0.3 + 0.7 * panel.reveal },
            Translate { y: (1 - panel.reveal) * 30 }
        ]

        RectangularGlow {
            anchors.fill: panelBg
            glowRadius: 22; spread: 0.1
            cornerRadius: panelBg.radius + glowRadius
            color: Qt.rgba(0.35, 0.45, 1.0, 0.18)
        }
        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: 28
            color: Qt.rgba(0.04, 0.05, 0.10, 0.62)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                height: parent.height * 0.5; radius: parent.radius - 1
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.07) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: 48
            anchors.topMargin: 14
            anchors.bottomMargin: 30
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            model: dock.actions
            snapMode: ListView.SnapToItem
            boundsBehavior: Flickable.DragAndOvershootBounds
            highlightMoveDuration: 300
            keyNavigationEnabled: true

            // rueda del ratón → desplaza horizontalmente
            WheelHandler {
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    list.flick(d * 9, 0);
                }
            }

            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                width: dock.tileW
                height: dock.tileH
                readonly property bool usable: modelData.enabled !== false
                readonly property color c: modelData.color || Fx.accent

                // entrada en cascada cada vez que se abre
                property real pop: 0
                Connections {
                    target: dock
                    function onOpenChanged() {
                        if (dock.open) { tile.pop = 0; popAnim.restart(); }
                    }
                }
                Component.onCompleted: if (dock.open) popAnim.restart()
                SequentialAnimation {
                    id: popAnim
                    PauseAnimation { duration: 80 + tile.index * 55 }
                    NumberAnimation { target: tile; property: "pop"; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 2 }
                }
                opacity: pop * (usable ? 1 : 0.38)
                transform: Translate { y: (1 - tile.pop) * 26 - (tma.containsMouse && tile.usable ? 6 : 0)
                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }

                // círculo del icono
                Item {
                    id: bubble
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width: 58; height: 58
                    scale: tma.pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                    // halo al pasar el ratón
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 14; height: width; radius: width / 2
                        color: Qt.rgba(tile.c.r, tile.c.g, tile.c.b, 0.22)
                        opacity: tma.containsMouse && tile.usable ? 1 : 0
                        scale: tma.containsMouse ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: 220 } }
                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(tile.c.r, tile.c.g, tile.c.b, tma.containsMouse ? 0.55 : 0.28) }
                            GradientStop { position: 1; color: Qt.rgba(tile.c.r * 0.5, tile.c.g * 0.5, tile.c.b * 0.6, tma.containsMouse ? 0.45 : 0.18) }
                        }
                        border.width: 1.2
                        border.color: Qt.rgba(tile.c.r, tile.c.g, tile.c.b, tma.containsMouse ? 0.95 : 0.45)
                    }
                    Glyph {
                        id: tileGlyph
                        anchors.centerIn: parent
                        size: 28
                        text: tile.modelData.icon
                        color: tma.containsMouse ? "white" : tile.c
                        Behavior on color { ColorAnimation { duration: 180 } }
                        // pequeño giro al pasar el ratón
                        rotation: tma.containsMouse && tile.usable ? (tile.modelData.spin ? 180 : 0) : 0
                        Behavior on rotation { NumberAnimation { duration: 520; easing.type: Easing.OutBack } }
                    }

                    // onda al hacer clic
                    Rectangle {
                        id: ripple
                        anchors.centerIn: parent
                        width: parent.width; height: width; radius: width / 2
                        color: "transparent"
                        border.width: 2; border.color: tile.c
                        opacity: 0
                    }
                    ParallelAnimation {
                        id: rippleAnim
                        NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.9; duration: 520; easing.type: Easing.OutCubic }
                        NumberAnimation { target: ripple; property: "opacity"; from: 0.9; to: 0; duration: 520; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: bubble.bottom
                    anchors.topMargin: 10
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: tile.modelData.label
                    color: "white"
                    opacity: tma.containsMouse ? 1 : 0.75
                    font.family: FontConfig.family
                    font.pixelSize: 12
                    font.weight: tma.containsMouse ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: tma
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: tile.usable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        rippleAnim.restart();
                        runTimer.restart();
                    }
                }
                Timer {
                    id: runTimer
                    interval: 220
                    onTriggered: {
                        dock.open = false;
                        dock.triggered();
                        if (tile.modelData.run) tile.modelData.run();
                    }
                }
            }
        }

        // Flechas
        component Arrow: Rectangle {
            id: arrow
            property string icon
            property bool active: true
            signal go()
            width: 32; height: 32; radius: 16
            anchors.verticalCenter: list.verticalCenter
            color: ama.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.06)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.18)
            opacity: active ? 1 : 0.25
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Glyph { anchors.centerIn: parent; size: 20; text: arrow.icon }
            MouseArea { id: ama; anchors.fill: parent; hoverEnabled: true; enabled: arrow.active; onClicked: arrow.go() }
        }
        Arrow {
            x: 9
            icon: Fx.icChevronL
            active: !list.atXBeginning
            onGo: list.flick(1600, 0)
        }
        Arrow {
            x: parent.width - width - 9
            icon: Fx.icChevronR
            active: !list.atXEnd
            onGo: list.flick(-1600, 0)
        }

        // Indicador de desplazamiento
        Rectangle {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: 70; height: 4; radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)
            visible: list.contentWidth > list.width + 1
            Rectangle {
                height: parent.height; radius: 2
                width: Math.max(14, parent.width * list.visibleArea.widthRatio)
                x: (parent.width - width) * (list.visibleArea.xPosition / Math.max(0.0001, 1 - list.visibleArea.widthRatio))
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Fx.accent }
                    GradientStop { position: 1; color: Fx.accent2 }
                }
            }
        }
    }

    // ---------- Botón píldora ----------
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: pillRow.implicitWidth + 30
        height: 40
        radius: 20
        color: pma.containsMouse || dock.open ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0.04, 0.05, 0.10, 0.5)
        border.width: 1
        border.color: dock.open ? Fx.accent : (pma.containsMouse ? Fx.strokeHover : Fx.stroke)
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
        scale: pma.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        // brillo que respira mientras está cerrado
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Fx.accent
            opacity: 0
            SequentialAnimation on opacity {
                running: !dock.open
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.0; duration: 1600; easing.type: Easing.InOutSine }
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8
            Glyph {
                size: 18
                text: Fx.icApps
                color: dock.open ? Fx.accent : "white"
                rotation: dock.open ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
            }
            Text {
                text: dock.open ? "Cerrar" : "Menú"
                color: "white"
                font.family: FontConfig.family; font.pixelSize: 13
            }
            Glyph {
                size: 16
                text: Fx.icChevronD
                rotation: dock.open ? 0 : 180
                opacity: 0.7
                Behavior on rotation { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            id: pma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dock.toggle()
        }
    }
}
