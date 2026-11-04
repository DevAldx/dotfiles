import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// Widget "Reproduciendo ahora": portada (o vinilo girando), título con
// desplazamiento, ecualizador animado, barra de progreso y controles.
GlassCard {
    id: root

    width: 268
    height: col.implicitHeight + padding * 2
    tint: Fx.accent3

    Loader { id: srcLoader; source: "NowPlayingSource.qml" }
    readonly property var src: srcLoader.status === Loader.Ready ? srcLoader.item : null
    readonly property bool has: src !== null && src.hasPlayer && (src.track.length > 0 || src.playing)
    readonly property bool playing: has && src.playing
    readonly property real progress: has && src.length > 0 ? Math.min(1, src.position / src.length) : 0

    function fmt(us) {
        const s = Math.max(0, Math.floor(us / 1000000));
        const m = Math.floor(s / 60);
        return m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Portada / vinilo
            Item {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64

                // vinilo (se ve cuando no hay portada)
                Item {
                    id: vinyl
                    anchors.fill: parent
                    visible: art.status !== Image.Ready
                    Rectangle {
                        anchors.fill: parent; radius: width / 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#1b1f2e" }
                            GradientStop { position: 1; color: "#0a0c14" }
                        }
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                    }
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            anchors.centerIn: parent
                            width: 54 - index * 12; height: width; radius: width / 2
                            color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.07)
                        }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24; height: 24; radius: 12
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Fx.accent3 }
                            GradientStop { position: 1; color: Fx.accent2 }
                        }
                        Glyph { anchors.centerIn: parent; size: 13; text: root.has ? Fx.icMusicNote : Fx.icMusicOff; color: "#0b0f1e" }
                    }
                    RotationAnimation on rotation {
                        running: true
                        paused: !root.playing
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 4000
                    }
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.has ? root.src.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    sourceSize: Qt.size(128, 128)
                }
                Rectangle { id: artMask; anchors.fill: parent; radius: 14; visible: false }
                OpacityMask {
                    anchors.fill: parent
                    source: art
                    maskSource: artMask
                    visible: art.status === Image.Ready
                    scale: root.playing ? 1.0 : 0.92
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.has ? (root.playing ? "REPRODUCIENDO" : "EN PAUSA") : "MÚSICA"
                    color: Fx.accent3
                    font.family: FontConfig.family; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.DemiBold
                }

                // Título con marquesina si no cabe
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleText.implicitHeight
                    clip: true
                    Text {
                        id: titleText
                        text: root.has ? (root.src.track || "Sin título") : "Nada reproduciéndose"
                        color: "white"
                        font.family: FontConfig.family; font.pixelSize: 14; font.weight: Font.DemiBold
                        readonly property real overflow: Math.max(0, implicitWidth - parent.width)
                        SequentialAnimation on x {
                            running: titleText.overflow > 0
                            loops: Animation.Infinite
                            PauseAnimation { duration: 1800 }
                            NumberAnimation { to: -titleText.overflow; duration: titleText.overflow * 28; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: 1400 }
                            NumberAnimation { to: 0; duration: titleText.overflow * 28; easing.type: Easing.InOutSine }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.has ? (root.src.artist || root.src.identity) : "Pon algo de música"
                    color: "white"; opacity: 0.6
                    elide: Text.ElideRight
                    font.family: FontConfig.family; font.pixelSize: 11
                }

                // Ecualizador
                Row {
                    spacing: 3
                    Layout.topMargin: 3
                    Repeater {
                        model: 7
                        Rectangle {
                            id: bar
                            required property int index
                            width: 3; radius: 1.5
                            height: 3
                            anchors.bottom: parent.bottom
                            color: index % 2 ? Fx.accent3 : Fx.accent2
                            opacity: root.playing ? 0.95 : 0.35
                            SequentialAnimation on height {
                                running: root.playing
                                loops: Animation.Infinite
                                NumberAnimation { to: 6 + (bar.index * 37 % 11); duration: 260 + bar.index * 47 % 180; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 3 + (bar.index * 13 % 5); duration: 240 + bar.index * 31 % 150; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 9 + (bar.index * 7 % 6); duration: 300 + bar.index * 23 % 120; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 3; duration: 220; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                    height: 15
                }
            }
        }

        // Progreso
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            visible: root.has && root.src.length > 0
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.12)
                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height; radius: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Fx.accent3 }
                        GradientStop { position: 1; color: Fx.accent2 }
                    }
                    Behavior on width { NumberAnimation { duration: 950 } }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width - width / 2
                        width: 10; height: 10; radius: 5
                        color: "white"
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.has ? root.fmt(root.src.position) : ""; color: "white"; opacity: 0.5; font.family: FontConfig.family; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: root.has ? root.fmt(root.src.length) : ""; color: "white"; opacity: 0.5; font.family: FontConfig.family; font.pixelSize: 10 }
            }
        }

        // Controles
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            visible: root.has

            component CtrlButton: Item {
                id: cb
                property string icon
                property bool primary: false
                signal activated()
                implicitWidth: primary ? 42 : 32
                implicitHeight: implicitWidth
                opacity: enabled ? 1 : 0.35
                scale: ma.pressed ? 0.86 : (ma.containsMouse ? 1.1 : 1)
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    visible: cb.primary
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Fx.accent3 }
                        GradientStop { position: 1; color: Fx.accent2 }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    visible: !cb.primary
                    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Glyph { anchors.centerIn: parent; size: cb.primary ? 22 : 20; text: cb.icon; color: cb.primary ? "#0b0f1e" : "white" }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: cb.activated() }
            }

            CtrlButton { icon: Fx.icPrev; enabled: root.has && root.src.canPrev; onActivated: root.src.previous() }
            CtrlButton { icon: root.playing ? Fx.icPause : Fx.icPlay; primary: true; onActivated: root.src.playPause() }
            CtrlButton { icon: Fx.icNext; enabled: root.has && root.src.canNext; onActivated: root.src.next() }
        }
    }
}
