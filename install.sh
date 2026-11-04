#!/usr/bin/env bash
# Restaura los dotfiles en una instalación nueva de Arch/CachyOS.
# Uso: ./install.sh            -> copia configs (hace backup de lo existente)
#      ./install.sh --packages -> además instala paquetes (pacman, AUR con yay, flatpak)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BK="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

copy() { # origen destino
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then mkdir -p "$BK/$(dirname "${dst#$HOME/}")"; cp -a "$dst" "$BK/${dst#$HOME/}"; fi
  mkdir -p "$(dirname "$dst")"; cp -a "$src" "$(dirname "$dst")/"
}

if [ "${1:-}" = "--packages" ]; then
  sudo pacman -S --needed - < <(grep -vxF -f <(pacman -Qqg base-devel 2>/dev/null || true) "$DIR/packages/pacman.txt") || true
  command -v yay >/dev/null && yay -S --needed - < "$DIR/packages/aur.txt" || echo "yay no instalado: salta AUR"
  command -v flatpak >/dev/null && xargs -r flatpak install -y flathub < "$DIR/packages/flatpak.txt" || true
fi

for f in "$DIR"/home/.[!.]*; do copy "$f" "$HOME/$(basename "$f")"; done
for f in "$DIR"/config/* ; do copy "$f" "$HOME/.config/$(basename "$f")"; done
for f in "$DIR"/local/share/*; do
  if [ "$(basename "$f")" = plasma ]; then for p in "$f"/*; do copy "$p" "$HOME/.local/share/plasma/$(basename "$p")"; done
  else copy "$f" "$HOME/.local/share/$(basename "$f")"; fi
done
for f in "$DIR"/local/bin/*; do copy "$f" "$HOME/.local/bin/$(basename "$f")"; done
for f in "$DIR"/themes/*; do copy "$f" "$HOME/.themes/$(basename "$f")"; done
for f in "$DIR"/icons/*;  do copy "$f" "$HOME/.icons/$(basename "$f")"; done
mkdir -p "$HOME/limpieza-pc" && cp -a "$DIR"/scripts/limpieza-pc/. "$HOME/limpieza-pc/"
cp -a "$DIR"/scripts/*.sh "$HOME/"
cp -a "$DIR"/sddm-bloqueo "$HOME/"

systemctl --user daemon-reload || true
echo "Listo. Backup de lo anterior en: $BK"
echo "Tema SDDM: ejecuta ~/instalar-tema-bloqueo.sh (pide sudo). Reinicia sesión para aplicar KDE."
