#!/bin/bash
# Ajustes de velocidad que necesitan root (2 de noviembre de 2026).
# Uso:      sudo bash ~/limpieza-pc/acelerar-root.sh
# Revertir: sudo systemctl enable --now avahi-daemon.service avahi-daemon.socket NetworkManager-wait-online.service
set -u

echo "== 1. Servicios que no necesitas =="
# Avahi: descubre impresoras/dispositivos en la red local. No lo usas y consume
# CPU/red en segundo plano.
systemctl disable --now avahi-daemon.service avahi-daemon.socket 2>/dev/null && echo "  avahi desactivado"
# Espera a que haya Internet antes de terminar el arranque: retrasa el inicio.
systemctl disable NetworkManager-wait-online.service 2>/dev/null && echo "  NetworkManager-wait-online desactivado"

echo "== 2. Registro del sistema (journal) limitado a 100 MB =="
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=100M\n' > /etc/systemd/journald.conf.d/10-tamano.conf
systemctl restart systemd-journald
journalctl --vacuum-size=100M >/dev/null 2>&1

echo "== 3. Caché de paquetes =="
paccache -rk1 2>/dev/null; paccache -ruk0 2>/dev/null
du -sh /var/cache/pacman/pkg 2>/dev/null

echo
echo "Listo. Se nota sobre todo al reiniciar."
