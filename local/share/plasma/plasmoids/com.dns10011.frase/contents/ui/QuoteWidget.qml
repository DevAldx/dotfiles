import QtQuick
import QtQuick.Layouts

// Saludo según la hora + frase del día (cambia cada día, rota cada 12 s
// con un fundido).
GlassCard {
    id: root

    width: 268
    height: col.implicitHeight + padding * 2
    tint: Fx.warm

    readonly property var quotes: [
        ["Hazlo con pasión o no lo hagas.", "Rosa Nouchette Carey"],
        ["La simplicidad es la máxima sofisticación.", "Leonardo da Vinci"],
        ["Un viaje de mil millas comienza con un paso.", "Lao Tse"],
        ["Lo que no te mata te hace más fuerte.", "Friedrich Nietzsche"],
        ["El código limpio parece escrito por alguien a quien le importa.", "Robert C. Martin"],
        ["Primero resuelve el problema. Luego escribe el código.", "John Johnson"],
        ["La creatividad es la inteligencia divirtiéndose.", "Albert Einstein"],
        ["Hoy es un buen día para empezar algo.", "—"],
        ["No cuentes los días, haz que los días cuenten.", "Muhammad Ali"],
        ["El secreto para avanzar es comenzar.", "Mark Twain"],
        ["La mejor forma de predecir el futuro es crearlo.", "Peter Drucker"],
        ["Sé el cambio que quieres ver en el mundo.", "Mahatma Gandhi"]
    ]

    property int qi: Math.floor(Date.now() / 86400000) % quotes.length

    Timer {
        interval: 12000; running: true; repeat: true
        onTriggered: swap.start()
    }
    SequentialAnimation {
        id: swap
        NumberAnimation { target: quoteBox; property: "opacity"; to: 0; duration: 380; easing.type: Easing.InCubic }
        ScriptAction { script: root.qi = (root.qi + 1) % root.quotes.length }
        NumberAnimation { target: quoteBox; property: "opacity"; to: 1; duration: 520; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 6

        Text {
            text: Fx.greeting() + " ✦"
            color: Fx.warm
            font.family: FontConfig.family; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        ColumnLayout {
            id: quoteBox
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Glyph { size: 16; text: Fx.icQuote; color: Qt.rgba(1, 1, 1, 0.4); Layout.alignment: Qt.AlignTop }
                Text {
                    Layout.fillWidth: true
                    text: root.quotes[root.qi][0]
                    wrapMode: Text.WordWrap
                    color: "white"; opacity: 0.9
                    font.family: FontConfig.family; font.pixelSize: 12; font.italic: true
                }
            }
            Text {
                Layout.alignment: Qt.AlignRight
                text: "— " + root.quotes[root.qi][1]
                color: "white"; opacity: 0.5
                font.family: FontConfig.family; font.pixelSize: 10
                visible: root.quotes[root.qi][1] !== "—"
            }
        }
    }
}
