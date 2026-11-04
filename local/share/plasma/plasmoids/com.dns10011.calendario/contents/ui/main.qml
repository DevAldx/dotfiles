import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: main
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    fullRepresentation: Item {
        Layout.minimumWidth: w.width + 8
        Layout.minimumHeight: w.height + 8
        Layout.preferredWidth: w.width + 8
        Layout.preferredHeight: w.height + 8
        CalendarWidget {
            id: w
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 4
        }
    }
}
