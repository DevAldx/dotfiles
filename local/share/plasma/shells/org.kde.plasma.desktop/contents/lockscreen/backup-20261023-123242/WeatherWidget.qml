/*
    Widget de clima para la pantalla de bloqueo.

    Los datos los actualiza un servicio de usuario cada 15 minutos (ver
    lockscreen-weather-update) y se guardan en weatherdata.js, dentro de este
    mismo tema. La pantalla de bloqueo no tiene acceso a Internet por
    seguridad, así que el módulo se lee al cargar el bloqueo.

    Coordenadas: Ciudad de México (19.4326, -99.1332). Si te mudas, cambia las
    coordenadas tanto aquí como en el script del servicio.
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "weatherdata.js" as WeatherData

Item {
    id: weatherRoot

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    property var weatherData: null
    property var forecastData: null
    property bool loaded: false
    property bool failed: false

    readonly property string city: "Ciudad de México"

    function weatherIcon(code, isDay) {
        if (code === 0) {
            return isDay ? "weather-clear" : "weather-clear-night";
        } else if (code === 1 || code === 2) {
            return isDay ? "weather-few-clouds" : "weather-few-clouds-night";
        } else if (code === 3) {
            return isDay ? "weather-clouds" : "weather-clouds-night";
        } else if (code === 45 || code === 48) {
            return "weather-fog";
        } else if (code >= 51 && code <= 57) {
            return "weather-showers-scattered";
        } else if (code >= 61 && code <= 67) {
            return "weather-showers";
        } else if (code >= 71 && code <= 77) {
            return "weather-snow";
        } else if (code >= 80 && code <= 82) {
            return "weather-showers-scattered";
        } else if (code === 85 || code === 86) {
            return "weather-snow";
        } else if (code >= 95) {
            return "weather-storm";
        }
        return "weather-none-available";
    }

    function weatherText(code) {
        if (code === 0) {
            return "Despejado";
        } else if (code === 1) {
            return "Mayormente despejado";
        } else if (code === 2) {
            return "Parcialmente nublado";
        } else if (code === 3) {
            return "Nublado";
        } else if (code === 45 || code === 48) {
            return "Niebla";
        } else if (code >= 51 && code <= 55) {
            return "Llovizna";
        } else if (code === 56 || code === 57) {
            return "Llovizna helada";
        } else if (code >= 61 && code <= 65) {
            return "Lluvia";
        } else if (code === 66 || code === 67) {
            return "Lluvia helada";
        } else if (code >= 71 && code <= 77) {
            return "Nieve";
        } else if (code >= 80 && code <= 82) {
            return "Chubascos";
        } else if (code === 85 || code === 86) {
            return "Chubascos de nieve";
        } else if (code >= 95) {
            return "Tormenta";
        }
        return "Clima";
    }

    function loadCachedWeather() {
        if (WeatherData && WeatherData.data && WeatherData.data.current && WeatherData.data.daily) {
            weatherData = WeatherData.data.current;
            forecastData = WeatherData.data.daily;
            loaded = true;
            failed = false;
            console.log("WeatherWidget: datos cargados,", weatherData.temperature_2m + "°C");
        } else {
            failed = true;
            console.log("WeatherWidget: no hay datos en weatherdata.js");
        }
    }

    Component.onCompleted: loadCachedWeather()

    Rectangle {
        id: card

        implicitWidth: 222
        implicitHeight: content.implicitHeight + 26

        radius: 18
        color: Qt.rgba(0.03, 0.045, 0.08, 0.42)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.30)

        // Brillo superior muy sutil, tipo cristal.
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 1
                leftMargin: 1
                rightMargin: 1
            }
            height: 1
            radius: parent.radius
            color: Qt.rgba(1, 1, 1, 0.22)
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 13
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    implicitWidth: 46
                    implicitHeight: 46
                    source: weatherRoot.loaded
                        ? weatherRoot.weatherIcon(weatherRoot.weatherData.weather_code, weatherRoot.weatherData.is_day === 1)
                        : "weather-none-available"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -2

                    PlasmaComponents3.Label {
                        text: weatherRoot.loaded
                            ? Math.round(weatherRoot.weatherData.temperature_2m) + "°"
                            : "--°"
                        color: "white"
                        font.pointSize: 23
                        font.weight: Font.DemiBold
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: weatherRoot.loaded
                            ? weatherRoot.weatherText(weatherRoot.weatherData.weather_code)
                            : (weatherRoot.failed ? "Sin datos" : "Actualizando…")
                        color: "white"
                        opacity: 0.8
                        font.pointSize: 9
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.14)
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    text: weatherRoot.loaded
                        ? "Máx " + Math.round(weatherRoot.forecastData.temperature_2m_max[0]) + "°"
                        : "Máx --°"
                    color: "white"
                    opacity: 0.72
                    font.pointSize: 9
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: weatherRoot.loaded
                        ? "Mín " + Math.round(weatherRoot.forecastData.temperature_2m_min[0]) + "°"
                        : "Mín --°"
                    color: "white"
                    opacity: 0.72
                    font.pointSize: 9
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    text: weatherRoot.loaded
                        ? weatherRoot.city
                        : "Ciudad de México"
                    color: "white"
                    opacity: 0.55
                    font.pointSize: 8
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: weatherRoot.loaded
                        ? "Sens. " + Math.round(weatherRoot.weatherData.apparent_temperature) + "°"
                        : "Sens. --°"
                    color: "white"
                    opacity: 0.55
                    font.pointSize: 8
                }
            }
        }
    }
}
