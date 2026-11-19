import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// Reproductor: portada, letra sincronizada (lrclib.net), progreso ondulado
// y controles. Lee el reproductor activo por MPRIS.
PlasmoidItem {
    id: main
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: root
        Layout.minimumWidth: 420
        Layout.minimumHeight: 214
        Layout.preferredWidth: 420
        Layout.preferredHeight: 214
        Layout.maximumWidth: 420
        Layout.maximumHeight: 214

        readonly property string mono: "CaskaydiaMono Nerd Font Mono"
        readonly property string icons: "CaskaydiaMono Nerd Font Propo"
        readonly property color accent: "#f0954a"
        function g(cp) { return String.fromCodePoint(cp); }

        // ---------- reproductor ----------
        Loader { id: srcLoader; source: "NowPlayingSource.qml" }
        readonly property var src: srcLoader.status === Loader.Ready ? srcLoader.item : null
        readonly property bool has: src !== null && src.hasPlayer && src.track.length > 0
        readonly property bool playing: has && src.playing
        readonly property real lenMs: has ? src.length / 1000 : 0

        // posición interpolada para que la letra avance suave
        property real posMs: 0
        readonly property real srcPos: has ? src.position : 0
        onSrcPosChanged: posMs = srcPos / 1000
        Timer { interval: 100; repeat: true; running: root.playing; onTriggered: root.posMs += 100 }
        readonly property real progress: lenMs > 0 ? Math.min(1, posMs / lenMs) : 0

        function fmt(ms) {
            const s = Math.max(0, Math.floor(ms / 1000));
            return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
        }

        // ---------- letras ----------
        ListModel { id: lines }
        property bool synced: false
        property string state_: ""          // "", "loading", "ok", "none"
        readonly property string key: has ? (src.artist + "|" + src.track) : ""
        onKeyChanged: fetchTimer.restart()
        Timer { id: fetchTimer; interval: 800; onTriggered: root.fetchLyrics() }

        function get(url, cb) {
            const x = new XMLHttpRequest();
            x.onreadystatechange = function () { if (x.readyState === XMLHttpRequest.DONE) cb(x.status, x.responseText); };
            x.open("GET", url);
            x.send();
        }
        function clean(t) {
            return t.replace(/\s*[\(\[][^\)\]]*(remaster|official|video|audio|lyric|letra|visualizer|hd|4k)[^\)\]]*[\)\]]/ig, "")
                    .replace(/\s+-\s+[^-]*remaster.*$/i, "").trim();
        }
        function parseLrc(t) {
            lines.clear();
            const re = /^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/;
            t.split("\n").forEach(function (l) {
                const m = l.trim().match(re);
                if (m) lines.append({ t: (parseInt(m[1]) * 60 + parseFloat(m[2])) * 1000, text: m[3].trim() || "♪" });
            });
        }
        function apply(d) {
            if (d.syncedLyrics) { parseLrc(d.syncedLyrics); synced = true; }
            else {
                lines.clear();
                d.plainLyrics.split("\n").forEach(function (l) { lines.append({ t: -1, text: l }); });
                synced = false;
            }
            state_ = lines.count > 0 ? "ok" : "none";
        }
        function fetchLyrics() {
            lines.clear(); synced = false;
            if (!has) { state_ = ""; return; }
            state_ = "loading";
            const k = key;
            let artist = src.artist || "";
            let track = clean(src.track);
            // videos tipo "Artista - Canción"
            if ((!artist || / - Topic$|VEVO$/i.test(artist)) && track.indexOf(" - ") > 0) {
                artist = track.split(" - ")[0]; track = track.split(" - ").slice(1).join(" - ");
            }
            artist = artist.replace(/ - Topic$/i, "");
            let url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artist)
                    + "&track_name=" + encodeURIComponent(track);
            if (lenMs > 0) url += "&duration=" + Math.round(lenMs / 1000);
            get(url, function (st, body) {
                if (k !== root.key) return;
                let d = null; try { d = JSON.parse(body); } catch (e) {}
                if (st === 200 && d && (d.syncedLyrics || d.plainLyrics)) { apply(d); return; }
                get("https://lrclib.net/api/search?q=" + encodeURIComponent((artist + " " + track).trim()), function (st2, b2) {
                    if (k !== root.key) return;
                    let arr = []; try { arr = JSON.parse(b2) || []; } catch (e) {}
                    let best = null;
                    for (let i = 0; i < arr.length; i++) {
                        if (arr[i].syncedLyrics) { best = arr[i]; break; }
                        if (!best && arr[i].plainLyrics) best = arr[i];
                    }
                    if (best) apply(best); else state_ = "none";
                });
            });
        }
        readonly property int current: {
            if (!synced) return -1;
            let c = -1;
            for (let i = 0; i < lines.count; i++) {
                if (lines.get(i).t <= posMs + 250) c = i; else break;
            }
            return c;
        }

        // ---------- tarjeta ----------
        Item {
            id: card
            anchors.fill: parent
            anchors.margins: 4
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: card.width; height: card.height; radius: 16 }
            }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0.09, 0.08, 0.13, 0.62) }
            Image {
                id: bgArt
                anchors.fill: parent
                source: art.source
                fillMode: Image.PreserveAspectCrop
                visible: false
                sourceSize.width: 128
            }
            FastBlur { anchors.fill: parent; source: bgArt; radius: 64; opacity: 0.5; visible: bgArt.status === Image.Ready }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0.10, 0.07, 0.12, 0.40) }
        }
        Rectangle {
            anchors.fill: card
            radius: 16
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
        }

        Item {
            id: content
            anchors.fill: card
            anchors.margins: 14

            // portada
            Item {
                id: artBox
                width: 120; height: 120
                Rectangle {
                    anchors.fill: parent; radius: 10
                    color: Qt.rgba(1, 1, 1, 0.06)
                    visible: art.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: root.g(0xf0387); color: "white"; opacity: 0.5
                        font.family: root.icons; font.pixelSize: 40
                    }
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.has ? root.src.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 240
                    visible: false
                }
                OpacityMask {
                    anchors.fill: parent
                    source: art
                    visible: art.status === Image.Ready
                    maskSource: Rectangle { width: artBox.width; height: artBox.height; radius: 10 }
                }
                // ecualizador
                Row {
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                    anchors.margins: 7
                    spacing: 2
                    visible: root.has
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            anchors.bottom: parent.bottom
                            width: 3; radius: 1.5; color: "white"
                            height: 5
                            SequentialAnimation on height {
                                running: root.playing; loops: Animation.Infinite
                                NumberAnimation { to: 6 + index * 3; duration: 260 + index * 90 }
                                NumberAnimation { to: 3; duration: 300 + index * 70 }
                            }
                        }
                    }
                }
            }

            // letra
            ListView {
                id: lyr
                anchors.left: artBox.right; anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.top: parent.top
                height: 120
                clip: true
                model: lines
                interactive: !root.synced
                currentIndex: Math.max(0, root.current)
                highlightRangeMode: root.synced ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
                preferredHighlightBegin: height / 2 - 10
                preferredHighlightEnd: height / 2 + 10
                highlightMoveDuration: 450
                delegate: Text {
                    required property int index
                    required property var model
                    width: ListView.view.width
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    text: model.text
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    font.weight: index === root.current ? Font.DemiBold : Font.Normal
                    color: index === root.current ? root.accent : "white"
                    opacity: root.current < 0 ? 0.8 : Math.max(0.22, 1 - Math.abs(index - root.current) * 0.24)
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                Text {
                    anchors.centerIn: parent
                    visible: lines.count === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: "white"; opacity: 0.55
                    font.pixelSize: 12
                    text: !root.has ? "Nada reproduciéndose"
                        : root.state_ === "loading" ? "Buscando letra…"
                        : "Letra no disponible"
                }
            }

            // título y artista
            Column {
                id: info
                anchors.left: parent.left
                anchors.right: timeText.left; anchors.rightMargin: 8
                anchors.top: artBox.bottom; anchors.topMargin: 8
                spacing: 1
                Text {
                    width: parent.width
                    text: root.has ? root.src.track : "Sin música"
                    elide: Text.ElideRight
                    color: "white"
                    font.family: "serif"; font.pixelSize: 16; font.weight: Font.Bold
                }
                Text {
                    width: parent.width
                    text: root.has ? (root.src.artist || root.src.identity) : "Pon algo para escuchar"
                    elide: Text.ElideRight
                    color: "white"; opacity: 0.7
                    font.pixelSize: 11
                }
            }
            Text {
                id: timeText
                anchors.right: parent.right
                anchors.bottom: info.bottom
                text: root.lenMs > 0 ? root.fmt(root.posMs) + " / " + root.fmt(root.lenMs) : ""
                color: "white"; opacity: 0.75
                font.family: root.mono; font.pixelSize: 10
            }

            // progreso ondulado + controles
            Item {
                id: wave
                anchors.left: parent.left
                anchors.right: controls.left; anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                height: 18
                property real phase: 0
                NumberAnimation on phase { running: root.playing; from: 0; to: 2 * Math.PI; duration: 1400; loops: Animation.Infinite }
                readonly property real px: width * root.progress

                function pts() {
                    const p = [], cy = height / 2;
                    const n = Math.max(2, Math.ceil(px / 2));
                    for (let i = 0; i <= n; i++) {
                        const x = px * i / n;
                        p.push(Qt.point(x, cy + 3 * Math.sin(x / 2.6 - phase)));
                    }
                    return p;
                }
                Rectangle {
                    x: wave.px; width: Math.max(0, wave.width - wave.px)
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2; radius: 1
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.accent; strokeWidth: 2.4
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                        PathPolyline { path: wave.pts() }
                    }
                }
                Rectangle {
                    x: wave.px - 1.5; width: 3; height: 14; radius: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                    visible: root.has
                }
            }

            Row {
                id: controls
                anchors.right: parent.right
                anchors.verticalCenter: wave.verticalCenter
                spacing: 8
                component Btn: Item {
                    id: b
                    property string glyph
                    property bool primary: false
                    signal clicked()
                    width: primary ? 30 : 22; height: 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 30; radius: 15
                        color: root.accent
                        visible: b.primary
                        scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.07 : 1)
                        Behavior on scale { NumberAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: b.glyph
                        color: b.primary ? "#2a1608" : "white"
                        opacity: b.primary || ma.containsMouse ? 1 : 0.75
                        font.family: root.icons; font.pixelSize: b.primary ? 16 : 15
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
                }
                Btn { glyph: root.g(0xf04ae); onClicked: if (root.src) root.src.previous() }
                Btn { glyph: root.playing ? root.g(0xf03e4) : root.g(0xf040a); primary: true; onClicked: if (root.src) root.src.playPause() }
                Btn { glyph: root.g(0xf04ad); onClicked: if (root.src) root.src.next() }
            }
        }
    }
}
