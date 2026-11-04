/*
    Widget de clima.

    Los datos los descarga ~/.local/bin/lockscreen-weather-update cada 15 min
    y los guarda en weatherdata.js (la pantalla no tiene acceso a Internet).
    Ciudad: Ciudad de México. Para cambiarla edita LAT/LON en ese script y
    la propiedad "city" de aquí abajo.
*/

import QtQuick
import QtQuick.Layouts

import "weatherdata.js" as WeatherData

GlassCard {
    id: root

    readonly property string city: "Ciudad de México"

    readonly property var cur: (WeatherData.data && WeatherData.data.current) ? WeatherData.data.current : null
    readonly property var daily: (WeatherData.data && WeatherData.data.daily) ? WeatherData.data.daily : null
    readonly property bool loaded: cur !== null && daily !== null
    readonly property bool isDay: loaded ? cur.is_day === 1 : true
    readonly property int code: loaded ? cur.weather_code : -1

    tint: Fx.weatherTint(code, isDay)
    width: 268
    height: col.implicitHeight + padding * 2

    function dayName(iso, i) {
        if (i === 0) return "Hoy";
        if (i === 1) return "Mañana";
        const d = new Date(iso + "T12:00:00");
        return ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"][d.getDay()];
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Icono animado: el sol gira lento, las nubes flotan
            Item {
                Layout.preferredWidth: 62
                Layout.preferredHeight: 62

                Rectangle {
                    anchors.centerIn: parent
                    width: 58; height: 58; radius: 29
                    color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.14)
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.08; duration: 2400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.96; duration: 2400; easing.type: Easing.InOutSine }
                    }
                }

                Glyph {
                    id: wIcon
                    anchors.centerIn: parent
                    size: 42
                    color: root.tint
                    text: Fx.weatherGlyph(root.code, root.isDay)
                    property bool sunny: root.code === 0 && root.isDay
                    RotationAnimation on rotation {
                        running: wIcon.sunny
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 24000
                    }
                    transform: Translate { id: drift }
                    SequentialAnimation {
                        running: !wIcon.sunny
                        loops: Animation.Infinite
                        NumberAnimation { target: drift; property: "x"; to: 3; duration: 2600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: drift; property: "x"; to: -3; duration: 2600; easing.type: Easing.InOutSine }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -2

                RowLayout {
                    spacing: 6
                    Text {
                        text: root.loaded ? Math.round(root.cur.temperature_2m) + "°" : "--°"
                        color: "white"
                        font.family: FontConfig.family
                        font.pixelSize: 38
                        font.weight: Font.DemiBold
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            text: "↑ " + (root.loaded ? Math.round(root.daily.temperature_2m_max[0]) : "--") + "°"
                            color: Fx.warm; font.family: FontConfig.family; font.pixelSize: 11
                        }
                        Text {
                            text: "↓ " + (root.loaded ? Math.round(root.daily.temperature_2m_min[0]) : "--") + "°"
                            color: Fx.accent; font.family: FontConfig.family; font.pixelSize: 11
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.loaded ? Fx.weatherText(root.code) : "Sin datos"
                    color: "white"; opacity: 0.85
                    font.family: FontConfig.family; font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    text: root.city
                    color: "white"; opacity: 0.5
                    font.family: FontConfig.family; font.pixelSize: 10
                }
            }
        }

        // Chips: sensación, humedad, viento
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    { ic: Fx.icThermo, v: root.loaded ? Math.round(root.cur.apparent_temperature) + "°" : "--", c: Fx.warm },
                    { ic: Fx.icDrop,   v: root.loaded && root.cur.relative_humidity_2m !== undefined ? root.cur.relative_humidity_2m + "%" : "--", c: Fx.accent },
                    { ic: Fx.icWind,   v: root.loaded && root.cur.wind_speed_10m !== undefined ? Math.round(root.cur.wind_speed_10m) + " km/h" : "--", c: Fx.accent3 }
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 13
                    color: Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Glyph { size: 13; text: modelData.ic; color: modelData.c; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: modelData.v; color: "white"; opacity: 0.9
                            font.family: FontConfig.family; font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.12) }

        // Pronóstico de 3 días
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.loaded
            Repeater {
                model: root.loaded ? Math.min(3, root.daily.time.length) : 0
                ColumnLayout {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2
                    readonly property var dcode: root.daily.weather_code ? root.daily.weather_code[index] : root.code

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.dayName(root.daily.time[index], index)
                        color: "white"; opacity: index === 0 ? 1 : 0.7
                        font.family: FontConfig.family; font.pixelSize: 11
                        font.weight: index === 0 ? Font.DemiBold : Font.Normal
                    }
                    Glyph {
                        Layout.alignment: Qt.AlignHCenter
                        size: 22
                        text: Fx.weatherGlyph(parent.dcode, true)
                        color: Fx.weatherTint(parent.dcode, true)
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5
                        Text {
                            text: Math.round(root.daily.temperature_2m_max[index]) + "°"
                            color: "white"
                            font.family: FontConfig.family; font.pixelSize: 12; font.weight: Font.DemiBold
                        }
                        Text {
                            text: Math.round(root.daily.temperature_2m_min[index]) + "°"
                            color: "white"; opacity: 0.5
                            font.family: FontConfig.family; font.pixelSize: 12
                        }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        visible: root.daily.precipitation_probability_max !== undefined
                        Glyph { size: 10; text: Fx.icUmbrella; color: Fx.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: (root.daily.precipitation_probability_max ? root.daily.precipitation_probability_max[index] : 0) + "%"
                            color: Fx.accent; font.family: FontConfig.family; font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
