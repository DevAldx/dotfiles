pragma Singleton

import QtQuick

/*
    Estado y estilo compartidos por toda la pantalla.

    - typed / typing: cuántos caracteres hay en el campo de contraseña. Lo
      escribe FancyPasswordField y lo leen el reloj, los widgets, el avatar y
      el fondo para cambiar la interfaz mientras escribes.
    - keystroke() / rejected(): eventos para las animaciones.
    - Colores de acento y los iconos (glifos de la Nerd Font).
*/
QtObject {
    id: fx

    property int typed: 0
    readonly property bool typing: typed > 0

    signal keystroke()
    signal rejected()

    // Paleta
    readonly property color accent:  "#8ab4ff"   // azul
    readonly property color accent2: "#c49bff"   // violeta
    readonly property color accent3: "#7ff0dc"   // menta
    readonly property color danger:  "#ff7a8a"
    readonly property color warm:    "#ffb86b"
    readonly property color glass:       Qt.rgba(0.04, 0.05, 0.10, 0.55)
    readonly property color glassHover:  Qt.rgba(0.10, 0.12, 0.20, 0.56)
    readonly property color stroke:      Qt.rgba(1, 1, 1, 0.26)
    readonly property color strokeHover: Qt.rgba(0.70, 0.80, 1.0, 0.70)

    // Fuente de iconos (Nerd Font, variante proporcional = glifos grandes)
    readonly property string iconFont: "CaskaydiaMono Nerd Font Propo"

    function g(cp) { return String.fromCodePoint(cp); }

    // Iconos Material Design incluidos en la Nerd Font
    readonly property string icPower:      g(0xf0425)
    readonly property string icRestart:    g(0xf0709)
    readonly property string icSleep:      g(0xf0904)
    readonly property string icHibernate:  g(0xf0717)
    readonly property string icSwitchUser: g(0xf0019)
    readonly property string icUsers:      g(0xf000e)
    readonly property string icOtherUser:  g(0xf0009)
    readonly property string icKeyboard:   g(0xf097b)
    readonly property string icApps:       g(0xf15fc)
    readonly property string icChevronL:   g(0xf0141)
    readonly property string icChevronR:   g(0xf0142)
    readonly property string icChevronD:   g(0xf0140)
    readonly property string icUnlock:     g(0xf0fc6)
    readonly property string icLock:       g(0xf033e)
    readonly property string icArrowR:     g(0xf0054)
    readonly property string icPlay:       g(0xf040a)
    readonly property string icPause:      g(0xf03e4)
    readonly property string icNext:       g(0xf04ad)
    readonly property string icPrev:       g(0xf04ae)
    readonly property string icMusic:      g(0xf075a)
    readonly property string icMusicNote:  g(0xf0387)
    readonly property string icMusicOff:   g(0xf075b)
    readonly property string icCalendar:   g(0xf0e17)
    readonly property string icDrop:       g(0xf058e)
    readonly property string icWind:       g(0xf059d)
    readonly property string icThermo:     g(0xf050f)
    readonly property string icUmbrella:   g(0xf054b)
    readonly property string icQuote:      g(0xf0757)
    readonly property string icSession:    g(0xf0614)
    readonly property string icEye:        g(0xf0208)
    readonly property string icEyeOff:     g(0xf0209)

    function weatherGlyph(code, isDay) {
        if (code === undefined || code === null) return g(0xf0590);
        if (code === 0) return isDay ? g(0xf0599) : g(0xf0594);
        if (code === 1 || code === 2) return isDay ? g(0xf0595) : g(0xf0f31);
        if (code === 3) return g(0xf0590);
        if (code === 45 || code === 48) return g(0xf0591);
        if (code >= 51 && code <= 57) return g(0xf0597);
        if (code >= 61 && code <= 67) return g(0xf0596);
        if (code >= 71 && code <= 77) return g(0xf0598);
        if (code >= 80 && code <= 82) return g(0xf0597);
        if (code === 85 || code === 86) return g(0xf0598);
        if (code >= 95) return g(0xf067e);
        return g(0xf0590);
    }

    function weatherTint(code, isDay) {
        if (code === 0 || code === 1) return isDay ? "#ffd27a" : "#b9c6ff";
        if (code === 2 || code === 3 || code === 45 || code === 48) return "#d6e2ff";
        if (code >= 95) return "#ffe07a";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "#e8f6ff";
        return "#8ec9ff";
    }

    function weatherText(code) {
        if (code === 0) return "Despejado";
        if (code === 1) return "Mayormente despejado";
        if (code === 2) return "Parcialmente nublado";
        if (code === 3) return "Nublado";
        if (code === 45 || code === 48) return "Niebla";
        if (code >= 51 && code <= 55) return "Llovizna";
        if (code === 56 || code === 57) return "Llovizna helada";
        if (code >= 61 && code <= 65) return "Lluvia";
        if (code === 66 || code === 67) return "Lluvia helada";
        if (code >= 71 && code <= 77) return "Nieve";
        if (code >= 80 && code <= 82) return "Chubascos";
        if (code === 85 || code === 86) return "Chubascos de nieve";
        if (code >= 95) return "Tormenta";
        return "Clima";
    }

    function greeting() {
        const h = new Date().getHours();
        if (h < 6) return "Buenas noches";
        if (h < 12) return "Buenos días";
        if (h < 19) return "Buenas tardes";
        return "Buenas noches";
    }
}
