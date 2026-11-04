import QtQuick

// Icono dibujado con la Nerd Font (siempre nítido y del color que quieras).
Text {
    property real size: 20
    font.family: Fx.iconFont
    font.pixelSize: size
    color: "white"
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
}
