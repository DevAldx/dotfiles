import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// Texto compacto para la barra: CPU · RAM · temperatura.
PlasmoidItem {
    id: main
    preferredRepresentation: fullRepresentation

    Sensors.Sensor { id: cpu;  sensorId: "cpu/all/usage";               updateRateLimit: 2000 }
    Sensors.Sensor { id: ram;  sensorId: "memory/physical/usedPercent"; updateRateLimit: 3000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/averageTemperature";  updateRateLimit: 3000 }

    function num(s) { const v = Number(s.value); return isNaN(v) ? 0 : v; }
    function pad(v) { const r = Math.round(v); return (r < 10 ? "0" : "") + r; }

    fullRepresentation: RowLayout {
        spacing: 14
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        component Stat: Row {
            property string glyph
            property string value
            spacing: 5
            Text {
                text: parent.glyph
                color: Kirigami.Theme.textColor; opacity: 0.8
                font.family: "CaskaydiaMono Nerd Font Propo"; font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: parent.value
                color: Kirigami.Theme.textColor
                font.family: "CaskaydiaMono Nerd Font Mono"; font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Stat { glyph: String.fromCodePoint(0xf0430); value: main.pad(main.num(cpu)) + "%" }
        Stat { glyph: String.fromCodePoint(0xf035b); value: main.pad(main.num(ram)) + "%" }
        Stat { glyph: String.fromCodePoint(0xf050f); value: main.pad(main.num(temp)) + "°" }
    }
}
