pragma Singleton

import QtQuick

/*
    Fuente única de la pantalla de bloqueo.

    La familia se instaló desde ~/Descargas/CascadiaMono.zip en
    ~/.local/share/fonts/CaskaydiaMono. Si quieres usar otra variante,
    cambia esta cadena (por ejemplo, "CaskaydiaMono Nerd Font Propo").
*/
QtObject {
    readonly property string family: "CaskaydiaMono Nerd Font Mono"
}
