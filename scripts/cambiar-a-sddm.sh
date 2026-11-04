#!/bin/bash
# Cambia la pantalla de inicio de Plasma Login Manager a SDDM con el tema Breeze,
# que usa el mismo diseño que la pantalla de bloqueo de KDE.
# Para revertir:  sudo systemctl disable sddm && sudo systemctl enable plasmalogin
set -e
U=/home/dns10011
WALL=/usr/share/plasmalogin/wallpapers/wallhaven-49972w_1920x1080.png

# 1. Instalar SDDM y su módulo de Configuración del sistema
pacman -S --needed --noconfirm sddm sddm-kcm

# 2. Cursor "Win 10" a nivel sistema si solo está en tu carpeta personal
for d in "$U/.local/share/icons/Win 10" "$U/.icons/Win 10"; do
  if [ -d "$d" ] && [ ! -d "/usr/share/icons/Win 10" ]; then
    cp -r "$d" /usr/share/icons/
    echo "Cursor Win 10 instalado en el sistema"
  fi
done

# 3. Configurar SDDM: tema Breeze, Wayland, cursor
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-apariencia.conf <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1

[Theme]
Current=breeze
CursorTheme=Win 10
CursorSize=32
EOF

# 4. Mismo fondo que la pantalla de bloqueo
cat > /usr/share/sddm/themes/breeze/theme.conf.user <<EOF
[General]
background=$WALL
type=image
EOF

# 5. Copiar tus colores, tema de Plasma, fuente e iconos al usuario de SDDM
mkdir -p /var/lib/sddm/.config
for f in kdeglobals plasmarc kcminputrc; do
  cp "$U/.config/$f" /var/lib/sddm/.config/$f
done
chown -R sddm:sddm /var/lib/sddm/.config

# 6. Cambiar de gestor de inicio
systemctl disable plasmalogin.service
systemctl enable sddm.service

echo "Listo. Reinicia la PC para ver la nueva pantalla de inicio."
