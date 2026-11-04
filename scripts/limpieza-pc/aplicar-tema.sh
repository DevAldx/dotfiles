#!/usr/bin/env bash
# =============================================================================
#  Aplica el tema Urabe (transparencia + fondos de arranque/bloqueo) de forma
#  idempotente.
#
#  IMPORTANTE: este script NO toca el fondo del escritorio. Ese lo eliges tú
#  en Configuración del sistema y se respeta tal cual.
#
#  Se ejecuta automáticamente:
#    - al arrancar la sesión  (systemd --user: aplicar-tema.service)
#    - al reanudar de suspensión (systemd --user: aplicar-tema.service)
#
#  Es IDEMPOTENTE: se puede ejecutar cuantas veces se quiera.
#  No necesita root (todo es configuración del usuario).
# =============================================================================

set -uo pipefail

USUARIO_HOME="${HOME}"
ORIGEN="$USUARIO_HOME/Descargas/urabeback.png"
PAQUETE="$USUARIO_HOME/.local/share/plasma/wallpapers/urabeback"
IMG_FINAL="$PAQUETE/contents/images/urabeback.png"
TEMA_SPLASH="$USUARIO_HOME/.local/share/plasma/look-and-feel/sumi.rembestgirl/contents/splash"
WF_SISTEMA="/usr/lib/qt6/qml/org/kde/breeze/components/WallpaperFader.qml"

log() { echo "[aplicar-tema] $*"; }

# -----------------------------------------------------------------------------
# 1. Paquete de wallpaper (solo como fuente de la imagen; el fondo del
#    escritorio NO se modifica aquí)
# -----------------------------------------------------------------------------
if [[ ! -f "$IMG_FINAL" ]]; then
    mkdir -p "$PAQUETE/contents/images" "$PAQUETE/contents/config"
    if [[ -f "$ORIGEN" ]]; then
        cp -f "$ORIGEN" "$IMG_FINAL"
        log "Imagen copiada desde Descargas al paquete del wallpaper."
    fi
fi

# -----------------------------------------------------------------------------
# 2. Transparencia de los paneles (OpacityMode: 0=Adaptive 1=Opaque 2=Translucent)
# -----------------------------------------------------------------------------
for panel in 115 138 161; do
    actual=$(kreadconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel $panel" --key panelOpacity 2>/dev/null)
    if [[ "$actual" != "2" ]]; then
        kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel $panel" \
            --key panelOpacity 2 2>/dev/null
        log "Panel $panel: opacidad -> Translucent (antes: ${actual:-sin definir})."
    fi
done

# -----------------------------------------------------------------------------
# 3. Transparencia de ventanas y desenfoque (KWin)
# -----------------------------------------------------------------------------
kwriteconfig6 --file kwinrc --group "Plugins" --key translucencyEnabled false 2>/dev/null
kwriteconfig6 --file kwinrc --group "Plugins" --key blurEnabled false 2>/dev/null
kwriteconfig6 --file kwinrc --group "Effect-translucency" --key Inactive 100 2>/dev/null
kwriteconfig6 --file kwinrc --group "Effect-translucency" --key MoveResize 85 2>/dev/null
kwriteconfig6 --file kwinrc --group "Effect-Blur" --key enabled false 2>/dev/null

# -----------------------------------------------------------------------------
# 4. Splash de inicio / apagado con el fondo Urabe (tema sumi.rembestgirl)
# -----------------------------------------------------------------------------
if [[ -d "$TEMA_SPLASH" && -f "$IMG_FINAL" ]]; then
    if [[ ! -f "$TEMA_SPLASH/images/urabeback.png" ]]; then
        cp -f "$IMG_FINAL" "$TEMA_SPLASH/images/urabeback.png"
        log "Fondo añadido al tema del splash."
    fi

    QML="$TEMA_SPLASH/Splash.qml"
    if [[ -f "$QML" ]] && ! grep -q 'id: wallpaper' "$QML"; then
        [[ -f "$QML.bak" ]] || cp -f "$QML" "$QML.bak"
        python3 - "$QML" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
block = '''    Image {
        id: wallpaper
        anchors.fill: parent
        source: "images/urabeback.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: root.scrimOpacity
    }

'''
if 'property real scrimOpacity' not in s:
    s = s.replace('    property int stage\n',
                  '    property int stage\n    property real scrimOpacity: 0.35\n', 1)
if 'id: wallpaper' not in s:
    s = s.replace('    Item {\n        id: content\n', block + '    Item {\n        id: content\n', 1)
open(p, 'w', encoding='utf-8').write(s)
print("Splash.qml parcheado")
PYEOF
    fi
fi

# -----------------------------------------------------------------------------
# 5. Aviso sobre la pantalla de bloqueo (requiere el parche de root)
# -----------------------------------------------------------------------------
if [[ -f "$WF_SISTEMA" ]] && ! grep -q "id: lockWallpaper" "$WF_SISTEMA" 2>/dev/null; then
    log "AVISO: la pantalla de bloqueo volvió al wallpaper del escritorio."
    log "       Vuelve a ejecutar: sudo bash $USUARIO_HOME/limpieza-pc/optimizar-root.sh"
fi

log "Transparencia y splash aplicados. El fondo del escritorio no se ha modificado."
exit 0
