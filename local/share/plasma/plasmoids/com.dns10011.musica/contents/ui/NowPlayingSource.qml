import QtQuick
import org.kde.plasma.private.mpris as Mpris

// Lee el reproductor activo por MPRIS (Spotify, Firefox, VLC, Elisa…).
// Se carga con un Loader: si el módulo no existe, el widget sigue funcionando
// en modo "nada reproduciéndose".
Item {
    id: src

    property bool hasPlayer: rep.count > 0
    property string track: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property string identity: ""
    property bool playing: false
    property real position: 0     // µs
    property real length: 0       // µs
    property bool canNext: false
    property bool canPrev: false
    property var container: null

    function playPause() { if (container) container.PlayPause(); }
    function next() { if (container) container.Next(); }
    function previous() { if (container) container.Previous(); }

    Timer {
        interval: 1000
        repeat: true
        running: src.playing && src.container !== null
        onTriggered: src.container.updatePosition()
    }

    Repeater {
        id: rep
        model: Mpris.MultiplexerModel { }
        delegate: Item {
            required property var model
            Binding { target: src; property: "track"; value: model.track || "" }
            Binding { target: src; property: "artist"; value: model.artist || "" }
            Binding { target: src; property: "album"; value: model.album || "" }
            Binding { target: src; property: "artUrl"; value: model.artUrl ? model.artUrl.toString() : "" }
            Binding { target: src; property: "identity"; value: model.identity || "" }
            Binding { target: src; property: "playing"; value: model.playbackStatus === Mpris.PlaybackStatus.Playing }
            Binding { target: src; property: "position"; value: model.position || 0 }
            Binding { target: src; property: "length"; value: model.length || 0 }
            Binding { target: src; property: "canNext"; value: !!model.canGoNext }
            Binding { target: src; property: "canPrev"; value: !!model.canGoPrevious }
            Binding { target: src; property: "container"; value: model.container }
        }
    }
}
