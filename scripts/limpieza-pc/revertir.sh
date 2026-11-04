#!/usr/bin/env bash
# =============================================================================
#  Revertir los cambios de optimización aplicados por optimizar-root.sh
#  Ejecuta: sudo bash /home/dns10011/limpieza-pc/revertir.sh
# =============================================================================
set -uo pipefail

BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; NC=$'\033[0m'
[[ $EUID -ne 0 ]] && { echo "Necesita root: sudo bash $0"; exit 1; }

echo "${BOLD}Revirtiendo la optimización...${NC}"
echo

# 1. Servicios
systemctl enable --now avahi-daemon.service bluetooth.service >/dev/null 2>&1
echo "[OK] avahi y bluetooth reactivados"

# 2. plocate diario
rm -f /etc/systemd/system/plocate-updatedb.timer.d/10-weekly.conf
systemctl daemon-reload >/dev/null 2>&1
systemctl restart plocate-updatedb.timer >/dev/null 2>&1
echo "[OK] plocate-updatedb vuelve a ser diario"

# 3. Journal
rm -f /etc/systemd/journald.conf.d/10-size-limit.conf
systemctl restart systemd-journald >/dev/null 2>&1
echo "[OK] Límite del journal retirado"

# 4. limine: restaurar configuración y cmdline
rm -f /etc/limine-entry-tool.d/10-optimize.conf
if [[ -f /etc/kernel/cmdline ]]; then
  rm -f /etc/kernel/cmdline
  echo "[OK] /etc/kernel/cmdline eliminado (se usará /proc/cmdline)"
fi
BAK=$(ls -t /boot/limine.conf.bak-* 2>/dev/null | head -1)
if [[ -n "${BAK:-}" ]]; then
  cp -a "$BAK" /boot/limine.conf
  echo "[OK] /boot/limine.conf restaurado desde $BAK"
else
  limine-update >/dev/null 2>&1
  echo "[OK] Entradas de limine regeneradas"
fi

# 5. Tema Urabe: restaurar pantallas de arranque, inicio de sesión y bloqueo
if [[ -f /usr/lib/qt6/qml/org/kde/breeze/components/WallpaperFader.qml.bak ]]; then
  cp -a /usr/lib/qt6/qml/org/kde/breeze/components/WallpaperFader.qml.bak \
        /usr/lib/qt6/qml/org/kde/breeze/components/WallpaperFader.qml
  echo "[OK] Pantalla de bloqueo restaurada (WallpaperFader.qml)"
fi

BAK_TEMA=$(ls -t /usr/share/sddm/themes/breeze/theme.conf.bak-* 2>/dev/null | head -1)
if [[ -n "${BAK_TEMA:-}" ]]; then
  cp -a "$BAK_TEMA" /usr/share/sddm/themes/breeze/theme.conf
  echo "[OK] Fondo de la pantalla de inicio de sesión restaurado"
fi

systemctl disable --now limine-fondo-urabe.service >/dev/null 2>&1
rm -f /etc/systemd/system/limine-fondo-urabe.service
rm -f /usr/local/bin/limine-fondo-urabe.sh
systemctl daemon-reload >/dev/null 2>&1
echo "[OK] Servicio del fondo de Limine retirado"

rm -f /usr/lib/systemd/system-sleep/urabe-resume
rm -f /usr/share/backgrounds/urabeback.png
rm -rf /usr/share/plymouth/themes/urabe

BAK_PLY=$(ls -t /etc/plymouth/plymouthd.conf.bak-* 2>/dev/null | head -1)
if [[ -n "${BAK_PLY:-}" ]]; then
  cp -a "$BAK_PLY" /etc/plymouth/plymouthd.conf
  echo "[OK] Plymouth restaurado al tema original"
  mkinitcpio -P >/dev/null 2>&1 && echo "[OK] initramfs regenerado"
fi

echo
echo "${GREEN}Reversión completada.${NC}"
echo "Reinicia para aplicar: sudo reboot"
echo
echo "${YELLOW}Nota: las cachés borradas (pacman, flathub) no se recuperan,${NC}"
echo "${YELLOW}se re-descargan solas cuando hagan falta.${NC}"
