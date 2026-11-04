#!/usr/bin/env bash
# =============================================================================
#  Script de limpieza y optimización del sistema (requiere root)
#  Sistema: CachyOS (Arch) en microSD 55G · Btrfs + snapper + limine
#
#  IMPORTANTE: es IDEMPOTENTE. Puedes ejecutarlo varias veces.
#  Todas las acciones destructivas afectan solo cachés regenerables.
#  Revertir:   sudo bash /home/dns10011/limpieza-pc/revertir.sh
# =============================================================================

set -uo pipefail

LOG="/home/dns10011/limpieza-pc/optimizar-root.log"
mkdir -p /tmp/opencode
exec > >(tee -a "$LOG") 2>&1

BALANCE=0
[[ "${1:-}" == "--balance" ]] && BALANCE=1

BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; NC=$'\033[0m'
seccion() { echo; echo "${BOLD}${YELLOW}══ $1 ══${NC}"; }
ok()      { echo "${GREEN}[OK]${NC} $1"; }
aviso()   { echo "${YELLOW}[!]${NC}  $1"; }
error()   { echo "${RED}[X]${NC}  $1"; }

if [[ $EUID -ne 0 ]]; then
  error "Este script necesita root. Ejecuta: sudo bash $0"
  exit 1
fi

echo "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo "${BOLD}  Limpieza y optimización del sistema — $(date '+%Y-%m-%d %H:%M')${NC}"
echo "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo "Espacio ANTES:"; df -h / | tail -1

# -----------------------------------------------------------------------------
seccion "1. Caché de pacman (4.6 GB de tarballs de 3062 paquetes)"
# -----------------------------------------------------------------------------
# paccache -rk2  : conserva las 2 versiones más recientes de cada paquete instalado
# paccache -ruk0 : elimina los tarballs de paquetes YA DESINSTALADOS
ANTES=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
paccache -rk2 2>/dev/null    # conserva las 2 versiones más recientes de cada paquete
paccache -ruk0 2>/dev/null   # borra los tarballs de paquetes ya desinstalados
DESPUES=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
ok "Caché de pacman: ${ANTES} → ${DESPUES}"
aviso "Reinstalar una versión anterior de un paquete requerirá descargarlo de nuevo (normal)."

# -----------------------------------------------------------------------------
seccion "2. Caché ostree de Flathub (6.1 GB de objetos)"
# -----------------------------------------------------------------------------
# /var/lib/flatpak/repo es la copia local del repositorio remoto de Flathub.
# NO afecta a las apps ya instaladas (viven en /var/lib/flatpak/app y /runtime).
ANTES=$(du -sh /var/lib/flatpak/repo 2>/dev/null | cut -f1)
rm -rf /var/lib/flatpak/repo/objects/* 2>/dev/null
DESPUES=$(du -sh /var/lib/flatpak/repo 2>/dev/null | cut -f1)
ok "Caché ostree de Flathub: ${ANTES} → ${DESPUES}"
if flatpak --system list >/dev/null 2>&1; then
  ok "Flatpak verificado: las apps instaladas siguen intactas ($(flatpak --system list --app --columns=application 2>/dev/null | wc -l) apps)"
else
  aviso "flatpak list devolvió error; ejecuta 'flatpak update' para re-sincronizar."
fi

# -----------------------------------------------------------------------------
seccion "3. Snapper y Btrfs"
# -----------------------------------------------------------------------------
echo "Subvolúmenes:"
btrfs subvolume list / 2>/dev/null | head -20
echo
echo "Snapshots de snapper (config 'root'):"
snapper -c root list --columns number,type,date,time,cleanup,description 2>/dev/null | head -25
SNAP_TOTAL=$(snapper -c root list --columns number 2>/dev/null | tail -n +2 | grep -c "^[0-9]" || echo 0)
echo "Total de snapshots: ${SNAP_TOTAL}"
echo

if [[ "$SNAP_TOTAL" -gt 0 ]]; then
  # Los snapshots 'pre'/'post' de pacman son discarded y se limpian solos.
  # Borramos los de más de 14 días.
  echo "Borrando snapshots de más de 14 días..."
  BORRADOS=0
  while IFS=$'\t' read -r NUM _TIPO FECHA HORA _CLEANUP _DESC; do
    [[ "$NUM" =~ ^[0-9]+$ ]] || continue
    EPOC=$(date -d "$FECHA $HORA" +%s 2>/dev/null) || continue
    EDAD=$(( ( $(date +%s) - EPOC ) / 86400 ))
    if [[ "$EDAD" -gt 14 ]]; then
      if snapper -c root delete "$NUM" >/dev/null 2>&1; then
        echo "  borrado #$NUM ($FECHA $HORA)"; BORRADOS=$((BORRADOS+1))
      fi
    fi
  done < <(snapper -c root list --columns number,type,date,time,cleanup,description 2>/dev/null | tail -n +2)
  ok "Snapshots borrados: ${BORRADOS}"
fi

# Poda de chunks no referenciados (seguro y rápido)
btrfs filesystem prune / 2>/dev/null && ok "btrfs filesystem prune ejecutado" || aviso "prune omitido"

# Balance de datos: redistribuye los chunks para liberar espacio contiguo.
# Escribe mucho en la microSD -> solo con --balance
if [[ $BALANCE -eq 1 ]]; then
  aviso "Iniciando balance de datos (puede tardar mucho y escribir bastante en la SD)..."
  btrfs balance start -dusage=50 / 2>&1 | tail -3
  ok "Balance finalizado"
else
  aviso "Balance de Btrfs NO ejecutado (opcional). Usa: sudo bash $0 --balance"
fi

echo
btrfs filesystem usage / 2>/dev/null | head -8

# -----------------------------------------------------------------------------
seccion "4. Journal: limitar tamaño a 100 MB"
# -----------------------------------------------------------------------------
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/10-size-limit.conf <<'EOF'
[Journal]
SystemMaxUse=100M
SystemKeepFree=500M
SystemMaxFileSize=20M
MaxRetentionSec=1month
EOF
ok "Creado /etc/systemd/journald.conf.d/10-size-limit.conf (SystemMaxUse=100M, MaxRetentionSec=1month)"
journalctl --vacuum-size=100M 2>/dev/null | tail -2
systemctl restart systemd-journald 2>/dev/null
ok "journald reiniciado y configurado"
journalctl --disk-usage 2>/dev/null

# -----------------------------------------------------------------------------
seccion "5. plocate-updatedb: de diario a semanal"
# -----------------------------------------------------------------------------
# Escaneaba toda la microSD cada día (2min 19s, 219 MB de RAM).
mkdir -p /etc/systemd/system/plocate-updatedb.timer.d
cat > /etc/systemd/system/plocate-updatedb.timer.d/10-weekly.conf <<'EOF'
[Timer]
OnCalendar=
OnCalendar=weekly
RandomizedDelaySec=1h
AccuracySec=1h
Persistent=true
EOF
systemctl daemon-reload 2>/dev/null
systemctl restart plocate-updatedb.timer 2>/dev/null
ok "plocate-updatedb.timer reprogramado a semanal"
systemctl list-timers plocate-updatedb.timer --no-pager 2>/dev/null | head -3

# -----------------------------------------------------------------------------
seccion "6. Deshabilitar avahi (mDNS) y bluetooth"
# -----------------------------------------------------------------------------
# bluetooth ya estaba soft-blocked por rfkill: el servicio solo consumía RAM.
for u in avahi-daemon.service avahi-daemon.socket bluetooth.service; do
  systemctl disable --now "$u" >/dev/null 2>&1
done
ok "avahi-daemon.service, avahi-daemon.socket y bluetooth.service deshabilitados"
echo "  Revertir: sudo systemctl enable --now avahi-daemon.service bluetooth.service"

# -----------------------------------------------------------------------------
seccion "7. Arranque: cmdline del kernel + configuración de limine"
# -----------------------------------------------------------------------------
CUR_CMDLINE=$(cat /proc/cmdline)
echo "Cmdline actual: ${CUR_CMDLINE}"

# 7a. Limitar los puertos serie 8250 (32 puertos que nunca existen ->
#     uded se re-probaba en el arranque real y costaba ~9,8 s).
if [[ "$CUR_CMDLINE" == *"8250.nr_uarts"* ]]; then
  aviso "8250.nr_uarts ya presente en el cmdline"
else
  mkdir -p /etc/kernel
  echo "${CUR_CMDLINE} 8250.nr_uarts=1" > /etc/kernel/cmdline
  ok "Creado /etc/kernel/cmdline con '8250.nr_uarts=1' añadido"
fi

# 7b. limine: desactivar el checksum BLAKE2 de los ficheros de arranque
#     (verificaba ~150 MB en cada arranque) y el escaneo de otros bootloaders.
mkdir -p /etc/limine-entry-tool.d
cat > /etc/limine-entry-tool.d/10-optimize.conf <<'EOF'
# Ajustes de rendimiento aplicados por la limpieza del sistema.
# Desactiva el checksum BLAKE2 de los ficheros de arranque (usa ~150 MB de
# lectura en la microSD en cada boot) y el escaneo de otros bootloaders.
ENABLE_VERIFICATION=no
FIND_BOOTLOADERS=no
EOF
ok "Creado /etc/limine-entry-tool.d/10-optimize.conf (ENABLE_VERIFICATION=no, FIND_BOOTLOADERS=no)"

# 7c. Regenerar las entradas de limine (con respaldo previo)
if [[ -f /boot/limine.conf ]]; then
  cp -a /boot/limine.conf "/boot/limine.conf.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null \
    && ok "Respaldo de /boot/limine.conf creado"
fi
if command -v limine-update >/dev/null 2>&1; then
  limine-update 2>&1 | tail -5
  ok "Entradas de limine regeneradas (limine-update)"
else
  aviso "limine-update no disponible; las entradas no se regeneraron"
fi

echo
echo "Verificación — cmdline que usará limine en el próximo arranque:"
limine-entry-tool --get-cmdline --no-mutex --no-hooks 2>/dev/null | tail -1 | sed 's/^/  /'
echo "Respaldo disponible en: /boot/limine.conf.bak-*"

# -----------------------------------------------------------------------------
seccion "8. Corregir el fallo de cachyos-rate-mirrors (DNS sin red lista)"
# -----------------------------------------------------------------------------
# El timer tiene Persistent=true: si el equipo estaba apagado a medianoche,
# se ejecuta nada más arrancar, cuando la red todavía no responde y falla
# con "Could not resolve host". Se retrasa 45 s para que la red esté lista.
mkdir -p /etc/systemd/system/cachyos-rate-mirrors.service.d
cat > /etc/systemd/system/cachyos-rate-mirrors.service.d/10-wait-for-network.conf <<'EOF'
[Service]
ExecStartPre=/bin/sleep 45
EOF
systemctl daemon-reload >/dev/null 2>&1
ok "cachyos-rate-mirrors: se retrasa 45 s para esperar a la red"

# -----------------------------------------------------------------------------
seccion "9. Plymouth (pantalla de arranque) con el fondo Urabe"
# -----------------------------------------------------------------------------
# El tema plymouth actual (cachyos-mac-style) muestra fondo NEGRO.
# Se crea un tema propio "urabe" = copia del tema actual + la imagen de fondo,
# de modo que el logo y la barra de progreso se mantienen igual.
TEMA_PLY="/usr/share/plymouth/themes/urabe"
IMG_WALL=""
for CAND in "/home/dns10011/Descargas/urabeback.png" \
            "/home/dns10011/.local/share/plasma/wallpapers/urabeback/contents/images/urabeback.png"; do
    [ -f "$CAND" ] && { IMG_WALL="$CAND"; break; }
done

# Copia de referencia en el sistema: la usan la pantalla de inicio de sesión
# y la pantalla de bloqueo (ambas se ejecutan fuera de la sesión del usuario).
if [ -n "$IMG_WALL" ]; then
    mkdir -p /usr/share/backgrounds
    IMGMAGICK="magick"; command -v magick >/dev/null 2>&1 || IMGMAGICK="convert"
    "$IMGMAGICK" "$IMG_WALL" -resize '1920x1080^' -gravity center -extent 1920x1080 \
            -strip -alpha off -define png:compression-level=9 \
            /usr/share/backgrounds/urabeback.png 2>/dev/null \
        && ok "Fondo del sistema creado: /usr/share/backgrounds/urabeback.png ($(du -h /usr/share/backgrounds/urabeback.png | cut -f1))"
fi

if [ -n "$IMG_WALL" ] && [ -d /usr/share/plymouth/themes/cachyos-mac-style ]; then
    mkdir -p "$TEMA_PLY/images"
    # Recursos de animación del tema actual (logo, progreso, teclado...)
    cp -a /usr/share/plymouth/themes/cachyos-mac-style/images/. "$TEMA_PLY/images/" 2>/dev/null

    # Fondo optimizado (PNG truecolor, 1920x1080) para que no engorde el initramfs
    IMGMAGICK="magick"; command -v magick >/dev/null 2>&1 || IMGMAGICK="convert"
    "$IMGMAGICK" "$IMG_WALL" -resize '1920x1080^' -gravity center -extent 1920x1080 \
            -strip -alpha off -define png:compression-level=9 -define png:compression-filter=5 \
            "$TEMA_PLY/images/background.png" 2>/dev/null \
        && ok "Fondo del splash de arranque generado ($(du -h "$TEMA_PLY/images/background.png" | cut -f1))"

    sed -e 's/^Name=.*/Name=urabe/' \
        -e "s|^ImageDir=.*|ImageDir=$TEMA_PLY/images|" \
        -e 's/^BackgroundStartColor=.*/BackgroundStartColor=0x0d0d12/' \
        -e 's/^BackgroundEndColor=.*/BackgroundEndColor=0x0d0d12/' \
        /usr/share/plymouth/themes/cachyos-mac-style/cachyos-mac-style.plymouth \
        > "$TEMA_PLY/urabe.plymouth" 2>/dev/null \
        && ok "Tema plymouth 'urabe' creado en $TEMA_PLY"

    # Activarlo
    if [ -f /etc/plymouth/plymouthd.conf ]; then
        cp -a /etc/plymouth/plymouthd.conf "/etc/plymouth/plymouthd.conf.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
        sed -i 's/^Theme=.*/Theme=urabe/' /etc/plymouth/plymouthd.conf
        ok "Tema plymouth activo: urabe"
    fi

    # Regenerar el initramfs para que incluya el tema nuevo
    echo "Regenerando el initramfs (puede tardar ~1 min)..."
    mkinitcpio -P >/dev/null 2>&1 \
        && ok "initramfs regenerado con el tema plymouth 'urabe'" \
        || aviso "mkinitcpio devolvió error; revisa /etc/mkinitcpio.conf"
else
    aviso "No se encontró urabeback.png ni el tema cachyos-mac-style; Plymouth sin cambios"
fi

# -----------------------------------------------------------------------------
seccion "10. Menú de arranque de Limine con el fondo Urabe"
# -----------------------------------------------------------------------------
# Limine lee la imagen del fondo desde la partición EFI (/boot, vfat).
if [ -f "$IMG_WALL" ] && [ -f /boot/limine.conf ]; then
    IMGMAGICK="magick"; command -v magick >/dev/null 2>&1 || IMGMAGICK="convert"
    "$IMGMAGICK" "$IMG_WALL" -resize '1920x1080^' -gravity center -extent 1920x1080 \
            -strip -alpha off -define png:compression-level=9 -define png:compression-filter=5 \
            /boot/urabeback.png 2>/dev/null \
        && ok "Fondo copiado a la partición EFI (/boot/urabeback.png)"

    cp -a /boot/limine.conf "/boot/limine.conf.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null

    if grep -qE '^background:' /boot/limine.conf; then
        sed -i 's|^background:.*|background: /urabeback.png|' /boot/limine.conf
        ok "Fondo del menú de Limine actualizado (background: /urabeback.png)"
    else
        # La opción global debe ir antes del primer bloque de arranque
        sed -i '1i background: /urabeback.png' /boot/limine.conf 2>/dev/null
        ok "Fondo del menú de Limine añadido (background: /urabeback.png)"
    fi
    aviso "Si 'limine-update' regenera limine.conf y quita la línea 'background:',"
    aviso "el servicio limine-fondo-urabe.service la restaura en el siguiente arranque."

    # Servicio que garantiza el fondo en cada arranque (limine-entry-tool puede
    # regenerar limine.conf y descartar la línea 'background:')
    cat > /usr/local/bin/limine-fondo-urabe.sh <<'EOF'
#!/usr/bin/env bash
# Asegura que el menú de Limine use el fondo Urabe.
[ -f /boot/limine.conf ] || exit 0
if ! grep -qE '^background:[[:space:]]*/urabeback\.png' /boot/limine.conf; then
    sed -i '1i background: /urabeback.png' /boot/limine.conf
fi
exit 0
EOF
    chmod 755 /usr/local/bin/limine-fondo-urabe.sh
    cat > /etc/systemd/system/limine-fondo-urabe.service <<'EOF'
[Unit]
Description=Asegura el fondo Urabe en el menú de Limine
DefaultDependencies=no
Before=limine-snapper-sync.service
After=local-fs.target
ConditionPathExists=/boot/limine.conf

[Service]
Type=oneshot
ExecStart=/usr/local/bin/limine-fondo-urabe.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
EOF
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable limine-fondo-urabe.service >/dev/null 2>&1
    ok "Servicio limine-fondo-urabe.service habilitado (restaura el fondo si Limine lo borra)"
else
    aviso "No se encontró /boot/limine.conf o la imagen; menú de Limine sin cambios"
fi

# -----------------------------------------------------------------------------
seccion "11. Pantalla de inicio de sesión (plasmalogin) con el fondo Urabe"
# -----------------------------------------------------------------------------
# El gestor de sesiones es plasmalogin (paquete plasma-login-manager), que
# reutiliza el tema 'breeze' de SDDM. Ese tema lo instala plasma-desktop y su
# fondo actual es el wallpaper 'Next' de Plasma:
#     /usr/share/wallpapers/Next/contents/images/5120x2880.png
# Es el fondo que ves justo ANTES de entrar a tu sesión.
TEMA_LOGIN="/usr/share/sddm/themes/breeze/theme.conf"
if [ -f "$TEMA_LOGIN" ] && [ -f /usr/share/backgrounds/urabeback.png ]; then
    cp -a "$TEMA_LOGIN" "$TEMA_LOGIN.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
    if grep -qE '^background=' "$TEMA_LOGIN"; then
        sed -i 's|^background=.*|background=/usr/share/backgrounds/urabeback.png|' "$TEMA_LOGIN"
    else
        sed -i '/^\[General\]/a background=/usr/share/backgrounds/urabeback.png' "$TEMA_LOGIN"
    fi
    ok "Fondo del inicio de sesión -> /usr/share/backgrounds/urabeback.png"
    aviso "Se verá al reiniciar (plasmalogin lo lee al arrancar)."
    aviso "Una actualización de plasma-desktop puede restaurar theme.conf;"
    aviso "vuelve a ejecutar este script (sección 11) si eso pasa."
else
    aviso "No se encontró $TEMA_LOGIN; la pantalla de inicio de sesión no se modifica"
fi

# -----------------------------------------------------------------------------
seccion "12. Pantalla de bloqueo con el fondo Urabe"
# -----------------------------------------------------------------------------
# En Plasma 6 la pantalla de bloqueo usa SIEMPRE el wallpaper del escritorio
# (no hay ninguna opción para cambiarlo). Para que el bloqueo muestre
# urabeback.png sin tocar el fondo del escritorio, se parchea el componente
# WallpaperFader.qml, que solo usa la pantalla de bloqueo.
WF="/usr/lib/qt6/qml/org/kde/breeze/components/WallpaperFader.qml"
if [ -f /usr/share/backgrounds/urabeback.png ]; then
    ok "Fondo del sistema disponible para el bloqueo"
else
    aviso "Falta /usr/share/backgrounds/urabeback.png; el bloqueo seguirá igual"
fi

if [ -f "$WF" ]; then
    [ -f "$WF.bak" ] || cp -a "$WF" "$WF.bak"
    if grep -q "id: lockWallpaper" "$WF"; then
        ok "El bloqueo ya usa el fondo Urabe"
    else
        python3 - "$WF" <<'PYEOF'
import sys
ruta = sys.argv[1]
s = open(ruta, encoding='utf-8').read()

viejo_alias = "    property alias source: wallpaperBlur.source\n"
nuevo_alias = (
    "    // Fondo fijo de la pantalla de bloqueo (Urabe).\n"
    "    // El valor que envia kscreenlocker (el wallpaper del escritorio) se ignora.\n"
    "    property string source: \"\"\n"
)

viejo_blur = (
    "    FastBlur {\n"
    "        id: wallpaperBlur\n"
    "        anchors.fill: parent\n"
    "        radius: 50 * wallpaperFader.factor\n"
    "    }\n"
)
nuevo_blur = (
    "    Image {\n"
    "        id: lockWallpaper\n"
    "        anchors.fill: parent\n"
    "        source: \"/usr/share/backgrounds/urabeback.png\"\n"
    "        fillMode: Image.PreserveAspectCrop\n"
    "        smooth: true\n"
    "        asynchronous: true\n"
    "    }\n"
    "    FastBlur {\n"
    "        id: wallpaperBlur\n"
    "        anchors.fill: parent\n"
    "        radius: 50 * wallpaperFader.factor\n"
    "        source: lockWallpaper\n"
    "    }\n"
)

if viejo_alias in s:
    s = s.replace(viejo_alias, nuevo_alias, 1)
elif "property string source" not in s:
    print("AVISO: no se encontro la linea 'property alias source'")
if viejo_blur in s:
    s = s.replace(viejo_blur, nuevo_blur, 1)
else:
    print("AVISO: no se encontro el bloque FastBlur")
open(ruta, 'w', encoding='utf-8').write(s)
print("WallpaperFader.qml parcheado")
PYEOF
        ok "Componente de la pantalla de bloqueo parcheado (respaldo en $WF.bak)"
    fi
    aviso "Una actualizacion de plasma-workspace puede restaurar el archivo original;"
    aviso "vuelve a ejecutar este script (sección 12) para volver a parchearlo."
else
    aviso "No se encontró $WF; la pantalla de bloqueo no se modifica"
fi

# -----------------------------------------------------------------------------
seccion "13. Hook de sistema para reaplicar el tema al suspender/reanudar"
# -----------------------------------------------------------------------------
# Complementa al servicio de usuario: se ejecuta en el lado del sistema
# cuando el equipo reanuda de una suspensión.
mkdir -p /usr/lib/systemd/system-sleep
cat > /usr/lib/systemd/system-sleep/urabe-resume <<'EOF'
#!/usr/bin/env bash
# Hook de sistema: reaplica el tema Urabe tras reanudar de suspensión.
[ "$1" = "post" ] || exit 0
for USUARIO in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
    UID_NUM=$(id -u "$USUARIO" 2>/dev/null) || continue
    [ -S "/run/user/$UID_NUM/bus" ] || continue
    systemctl --user --machine="$USUARIO@.host" start aplicar-tema.service >/dev/null 2>&1
done
exit 0
EOF
chmod 755 /usr/lib/systemd/system-sleep/urabe-resume
ok "Hook /usr/lib/systemd/system-sleep/urabe-resume instalado"

# -----------------------------------------------------------------------------
seccion "14. Comprobación final"
# -----------------------------------------------------------------------------
echo "Espacio DESPUÉS:"; df -h / | tail -1
echo
echo "Servicios deshabilitados:"
for u in avahi-daemon.service bluetooth.service; do
  printf "  %-28s %s\n" "$u" "$(systemctl is-enabled $u 2>/dev/null || echo '?')"
done
echo
echo "Boot (antes era 34,7 s):"
systemd-analyze 2>/dev/null | tail -1
echo
echo "Btrfs:"
btrfs filesystem usage / 2>/dev/null | grep -E "Used|Free|Device allocated"
echo
echo "Journal:"; journalctl --disk-usage 2>/dev/null
echo
echo "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo "${GREEN}${BOLD}  Completado. Log en: $LOG${NC}"
echo "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
