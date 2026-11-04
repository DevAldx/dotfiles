#!/bin/bash
# Rellena la configuración de SDDM que quedó vacía (fondo, tema, cursor, Wayland).
set -e
U=/home/dns10011
WALL=/usr/share/plasmalogin/wallpapers/wallhaven-49972w_1920x1080.png

mkdir -p /etc/sddm.conf.d
printf '%s\n' \
  '[General]' \
  'DisplayServer=wayland' \
  'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
  '' \
  '[Wayland]' \
  'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1' \
  '' \
  '[Theme]' \
  'Current=breeze' \
  'CursorTheme=Win 10' \
  'CursorSize=32' \
  > /etc/sddm.conf.d/10-apariencia.conf

printf '%s\n' \
  '[General]' \
  "background=$WALL" \
  'type=image' \
  > /usr/share/sddm/themes/breeze/theme.conf.user

mkdir -p /var/lib/sddm/.config
for f in kdeglobals plasmarc kcminputrc; do
  [ -f "$U/.config/$f" ] && cp "$U/.config/$f" /var/lib/sddm/.config/$f
done
chown -R sddm:sddm /var/lib/sddm/.config

echo "--- /etc/sddm.conf.d/10-apariencia.conf"; cat /etc/sddm.conf.d/10-apariencia.conf
echo "--- theme.conf.user"; cat /usr/share/sddm/themes/breeze/theme.conf.user
echo "Listo. Cierra sesión o reinicia para verlo."
