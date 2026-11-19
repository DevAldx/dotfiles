import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

// Paginador: cada escritorio muestra su número con una Miku distinta.
PlasmoidItem {
    id: main
    preferredRepresentation: fullRepresentation

    readonly property color miku: "#39C5BB"
    readonly property color mikuPink: "#E12885"

    TaskManager.VirtualDesktopInfo { id: vdi }

    function switchBy(step) {
        const ids = vdi.desktopIds;
        if (!ids || ids.length === 0) return;
        let i = ids.indexOf(vdi.currentDesktop);
        i = (i + step + ids.length) % ids.length;
        vdi.requestActivate(ids[i]);
    }

    fullRepresentation: RowLayout {
        spacing: 4
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (e) => main.switchBy(e.angleDelta.y > 0 ? -1 : 1)
        }

        Repeater {
            model: vdi.desktopIds

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool active: modelData === vdi.currentDesktop
                readonly property int imgIndex: (index % 5) + 1

                Layout.fillHeight: true
                Layout.preferredWidth: row.implicitWidth + 12

                // Fondo del escritorio activo
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 7
                    color: Qt.alpha(main.miku, cell.active ? 0.28 : (hover.hovered ? 0.12 : 0))
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Puntada "bordada" alrededor del activo
                Canvas {
                    id: stitch
                    anchors.fill: parent
                    anchors.margins: 2
                    visible: cell.active
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onVisibleChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d");
                        c.reset();
                        c.strokeStyle = main.miku;
                        c.lineWidth = 1.5;
                        c.setLineDash([3, 2]);
                        const r = 6, x = 1.5, y = 1.5, w = width - 3, h = height - 3;
                        c.beginPath();
                        c.roundedRect(x, y, w, h, r, r);
                        c.stroke();
                    }
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 3

                    Image {
                        source: Qt.resolvedUrl("../images/miku" + cell.imgIndex + ".png")
                        height: Math.max(16, cell.height - 8)
                        width: height * (sourceSize.width / Math.max(1, sourceSize.height))
                        fillMode: Image.PreserveAspectFit
                        smooth: cell.imgIndex !== 5
                        mipmap: cell.imgIndex !== 5
                        opacity: cell.active || hover.hovered ? 1 : 0.85
                        anchors.verticalCenter: parent.verticalCenter
                        scale: cell.active ? 1.0 : 0.9
                        Behavior on scale { NumberAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Text {
                        text: cell.index + 1
                        color: cell.active ? main.miku : Kirigami.Theme.textColor
                        opacity: cell.active ? 1 : 0.75
                        font.family: "CaskaydiaMono Nerd Font Mono"
                        font.pixelSize: 12
                        font.bold: cell.active
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: vdi.requestActivate(cell.modelData) }
            }
        }
    }
}
