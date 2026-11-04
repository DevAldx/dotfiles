# dotfiles — CachyOS (Arch) + KDE Plasma

Configuración personal de `dns10011`.

## Contenido
| Carpeta | Qué hay |
|---|---|
| `home/` | `.bashrc`, `.zshrc`, `.gitconfig`, `.gtkrc-2.0`… |
| `config/` | fish, alacritty, fastfetch (logo anime), micro, KDE (kwin, kdeglobals, atajos, panel/applets, bloqueo), GTK, servicios systemd de usuario, autostart |
| `local/share/` | Esquema de color *Vidrio*, Konsole, Aurorae, tema Plasma, look-and-feel, plasmoids propios (`com.dns10011.*`), shell del bloqueo con clima |
| `local/bin/` | `lockscreen-weather-update` |
| `themes/`, `icons/` | Nordic, cursores miku-cursor-linux y Win 10 |
| `sddm-bloqueo/` | Tema de login SDDM a juego con la pantalla de bloqueo |
| `scripts/` | Scripts de SDDM, tema y optimización (`limpieza-pc`) |
| `packages/` | Listas de paquetes: `pacman.txt`, `aur.txt`, `flatpak.txt`, `icon-themes.txt` |

## Restaurar
```bash
git clone git@github.com:DevAldx/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --packages   # o ./install.sh solo para las configs
```

Notas:
- Fuente: `CaskaydiaMono Nerd Font` → `sudo pacman -S ttf-cascadia-mono-nerd`.
- Iconos (kora, WhiteSur-purple) no están en el repo por tamaño; ver `packages/icon-themes.txt` (KDE → Descargar nuevos iconos, o AUR).
- No se incluyen tokens, claves ni `fish_variables`.
