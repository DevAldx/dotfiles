import QtQuick
import QtQuick.Layouts

// Calendario del mes con el día de hoy resaltado (con pulso).
GlassCard {
    id: root

    width: 268
    height: col.implicitHeight + padding * 2
    tint: Fx.accent2

    property date today: new Date()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.today = new Date() }

    readonly property int year: today.getFullYear()
    readonly property int month: today.getMonth()
    readonly property int firstOffset: (new Date(year, month, 1).getDay() + 6) % 7   // lunes = 0
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property var monthNames: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio",
                                       "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Glyph { size: 18; text: Fx.icCalendar; color: Fx.accent2 }
            Text {
                text: root.monthNames[root.month]
                color: "white"
                font.family: FontConfig.family; font.pixelSize: 15; font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.year
                color: "white"; opacity: 0.5
                font.family: FontConfig.family; font.pixelSize: 13
            }
        }

        Grid {
            id: grid
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            readonly property real cell: (col.width - columnSpacing * 6) / 7

            Repeater {
                model: ["L", "M", "X", "J", "V", "S", "D"]
                Text {
                    required property string modelData
                    required property int index
                    width: grid.cell; height: 18
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: index >= 5 ? Fx.accent2 : "white"
                    opacity: 0.55
                    font.family: FontConfig.family; font.pixelSize: 11; font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: root.firstOffset + root.daysInMonth
                Item {
                    id: cellItem
                    required property int index
                    readonly property int day: index - root.firstOffset + 1
                    readonly property bool isToday: day === root.today.getDate()
                    readonly property bool weekend: index % 7 >= 5
                    width: grid.cell; height: 24

                    // aparece en cascada
                    opacity: 0
                    scale: 0.6
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 300 + cellItem.index * 14 }
                        ParallelAnimation {
                            NumberAnimation { target: cellItem; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
                            NumberAnimation { target: cellItem; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack }
                        }
                    }

                    Rectangle {
                        visible: cellItem.isToday
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Fx.accent }
                            GradientStop { position: 1; color: Fx.accent2 }
                        }
                        // anillo que late
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width; height: width; radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Fx.accent2
                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 1.6; duration: 1600; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 400 }
                            }
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.8; to: 0; duration: 1600; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 400 }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: cellItem.day > 0
                        text: cellItem.day
                        color: cellItem.isToday ? "#0b0f1e" : (cellItem.weekend ? Fx.accent2 : "white")
                        opacity: cellItem.isToday ? 1 : (cellItem.day < root.today.getDate() ? 0.4 : 0.85)
                        font.family: FontConfig.family
                        font.pixelSize: 12
                        font.weight: cellItem.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
