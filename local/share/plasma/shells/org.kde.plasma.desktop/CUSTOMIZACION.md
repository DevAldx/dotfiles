# Pantalla de bloqueo, inicio de sesión y fuente global

Este paquete de shell (`~/.local/share/plasma/shells/org.kde.plasma.desktop`) es una
copia del shell de Plasma con la pantalla de bloqueo modificada. Los archivos QML
que no se tocaron siguen enlazados a los del sistema. La fuente tipográfica se
aplica tanto al bloqueo como al resto del escritorio (ver «Fuente global»). La
pantalla de inicio de sesión se documenta en la última sección.

## Qué se cambió

- `contents/lockscreen/LockScreenUi.qml`
  - Botones de acción (Reposo, Hibernar, Cambiar usuario) con borde y relleno
    translúcido.
  - Botones del pie (teclado virtual, distribución de teclado) con el mismo estilo.
  - Iconos simbólicos blancos de Kora.
  - Degradado oscuro sobre el fondo para mejorar el contraste.
  - Widget del clima en la esquina superior derecha.
- `contents/lockscreen/MainBlock.qml`
  - Campo de contraseña y botón de desbloqueo con fondo transparente, borde y
    resaltado azul al enfocar.
  - Animación de feedback al escribir (destello, halo y punto de luz).
  - Botón de desbloqueo con icono de candado abierto.
- `contents/lockscreen/WeatherWidget.qml`
  - Widget del clima (temperatura, condición, máxima/mínima, sensación térmica).
  - Iconos meteorológicos simbólicos.
- `contents/lockscreen/FontConfig.qml`
  - Define la familia tipográfica que usa toda la pantalla de bloqueo.
- Configuración global de KDE, GTK y gsettings
  - La familia **CaskaydiaMono Nerd Font Mono** se aplica a todo el escritorio,
    no solo al bloqueo.
- `contents/lockscreen/LockClock.qml`, `LockUserList.qml`,
  `LockUserDelegate.qml` y `LockSessionManagementScreen.qml`
  - Copias locales de los componentes de Breeze para poder aplicarles la fuente
    sin modificar los archivos del sistema.
- `contents/lockscreen/weatherdata.js`
  - Datos del clima generados automáticamente. No lo edites a mano.

## Vistas previas

- `~/Imágenes/vista-previa-bloqueo-reposo.png`
- `~/Imágenes/vista-previa-bloqueo-activo.png`
- `~/Imágenes/vista-previa-bloqueo-tecleando.png`
- `~/Imágenes/vista-previa-login-modo-prueba.png` (el fondo gris es el color
  de prueba del greeter; en el login real se ve la imagen configurada)

## Fuente

La fuente se instaló desde `~/Descargas/CascadiaMono.zip` en:

```text
~/.local/share/fonts/CaskaydiaMono/
```

La familia que se usa es **CaskaydiaMono Nerd Font Mono**. Si el nombre no
aparece en alguna aplicación, actualiza la caché:

```bash
fc-cache -f
fc-list | grep -i caskaydia
```

### Pantalla de bloqueo

Para cambiar la fuente de la pantalla de bloqueo, edita una sola línea en
`contents/lockscreen/FontConfig.qml`:

```qml
readonly property string family: "CaskaydiaMono Nerd Font Mono"
```

Los componentes que necesitan una familia explícita (reloj, nombre de usuario,
notificaciones, clima, campo de contraseña, botones y controles multimedia) ya
leen esa propiedad.

### Fuente global

La misma familia se aplicó a todo el escritorio de KDE, conservando los tamaños
originales: 10 pt para el texto normal y los títulos de ventana, y 8 pt para el
texto pequeño.

En `~/.config/kdeglobals` se cambiaron estas claves:

- `[General] font`, `fixed`, `menuFont`, `toolBarFont` y `desktopFont`:
  `CaskaydiaMono Nerd Font Mono,10,-1,5,50,0,0,0,0,0`
- `[General] smallestReadableFont`:
  `CaskaydiaMono Nerd Font Mono,8,-1,5,50,0,0,0,0,0`
- `[WM] activeFont` e `inactiveFont`:
  `CaskaydiaMono Nerd Font Mono,10,-1,5,75,0,0,0,0,0`

También se sincronizaron las aplicaciones GTK:

- `~/.config/gtk-3.0/settings.ini` y `~/.config/gtk-4.0/settings.ini`:
  `gtk-font-name` y `gtk-monospace-font-name`.
- `gsettings`: `font-name`, `monospace-font-name`, `document-font-name` y
  `titlebar-font`.

Para aplicar los cambios sin cerrar sesión:

```bash
dbus-send --session --type=signal /KDE/PlasmaShell \
  org.kde.KGlobalSettings.notifyChange int32:1 int32:0
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
kbuildsycoca6 --noincremental
```

Las aplicaciones que ya estaban abiertas pueden necesitar reiniciarse para
adoptar la fuente. Las que se abran después la usarán automáticamente. Konsole
es un caso aparte: usa la fuente de su propio perfil de terminal y no hereda
esta configuración.

### Respaldos y reversión de la fuente global

Antes de cambiar la fuente se guardaron estos respaldos:

- `~/.config/kdeglobals.bak-20261023-130259`
- `~/.config/gtk-3.0/settings.ini.bak-20261023-130259`
- `~/.config/gtk-4.0/settings.ini.bak-20261023-130259`
- `~/.config/kde-global-font-gsettings-backup-20261023-130259.txt`

Para volver a la fuente anterior:

```bash
cp ~/.config/kdeglobals.bak-20261023-130259 ~/.config/kdeglobals
cp ~/.config/gtk-3.0/settings.ini.bak-20261023-130259 \
  ~/.config/gtk-3.0/settings.ini
cp ~/.config/gtk-4.0/settings.ini.bak-20261023-130259 \
  ~/.config/gtk-4.0/settings.ini

gsettings set org.gnome.desktop.interface font-name 'Noto Sans  10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Hack  10'
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans  10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font \
  'Adwaita Sans Bold 11'

dbus-send --session --type=signal /KDE/PlasmaShell \
  org.kde.KGlobalSettings.notifyChange int32:1 int32:0
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
```

Después de restaurar, reinicia las aplicaciones abiertas o cierra sesión para
que todas vuelvan a la fuente anterior.

## Iconos

Se cambiaron los iconos de color por variantes simbólicas (monocromas) de Kora,
que combinan mejor con los botones de cristal:

| Acción | Icono |
| --- | --- |
| Reposo | `system-suspend-symbolic` |
| Hibernar | `system-hibernate-symbolic` |
| Cambiar usuario | `system-switch-user-symbolic` |
| Desbloquear | `object-unlocked` |
| Teclado virtual | `input-keyboard-symbolic` / `keyboard-hide-symbolic` |
| Distribución de teclado | `keyboard-layout-filled-symbolic` |
| Clima | `weather-*-symbolic` |

Los iconos del clima se asignan en `weatherIcon()` dentro de `WeatherWidget.qml`.
Si falta una variante simbólica, se usa una alternativa (por ejemplo,
`weather-clouds-symbolic` para las nubes nocturnas o `dialog-question-symbolic`
para un código desconocido).

Para usar otro icono, cambia el `icon.name` correspondiente en
`LockScreenUi.qml`, `MainBlock.qml` o `NoPasswordUnlock.qml`. El nombre debe
existir en el tema de iconos activo (Kora).

## Animación al teclear

En `MainBlock.qml`, el campo de contraseña compara la longitud del texto. Cada
vez que se añade un carácter (letra, número o símbolo) lanza `keyFeedback`, que
hace cuatro cosas a la vez:

1. Enciende y apaga un destello azul dentro del campo (`keyFlash`).
2. Expande y desvanece un halo alrededor del campo (`keyGlow`).
3. Hace subir y desaparecer un punto de luz sobre el campo (`keySpark`).
4. Da un pequeño rebote al campo (`passwordBox.scale`).

No se muestra el carácter escrito: el campo sigue ocultando la contraseña. La
animación solo se dispara al **aumentar** la longitud del texto, así que borrar
con Retroceso no la activa. Tampoco se activa si el texto cambia mientras la
interfaz está oculta.

Para hacerla más intensa o más discreta, ajusta los valores de
`ParallelAnimation { id: keyFeedback ... }` en `MainBlock.qml` (duración,
`scale`, opacidad y recorrido de `keySpark`).

## Fondo

El bloqueo se configura en `~/.config/kscreenlockerrc`:

```ini
[Greeter][Wallpaper][org.kde.image][General]
Image=/home/dns10011/Descargas/wallhaven-49972w_1920x1080.png
PreviewImage=/home/dns10011/Descargas/wallhaven-49972w_1920x1080.png
FillMode=2
```

Cambia las dos rutas por la imagen que quieras. `FillMode=2` recorta la imagen
para llenar la pantalla sin deformarla.

El inicio de sesión usa una copia de ese mismo fondo en
`/usr/share/plasmalogin/wallpapers/wallhaven-49972w_1920x1080.png`, porque el
usuario `plasmalogin` no puede leer `/home/dns10011`. Para cambiar el fondo del
login, copia la imagen nueva a esa carpeta y actualiza la ruta en
`/etc/plasmalogin.conf` (ver «Pantalla de inicio de sesión»).

## Clima

El bloqueo de KDE no tiene acceso a Internet, así que un servicio de usuario
descarga el clima y genera `weatherdata.js` cada 15 minutos.

- Script: `~/.local/bin/lockscreen-weather-update`
- Servicio: `~/.config/systemd/user/lockscreen-weather.service`
- Temporizador: `~/.config/systemd/user/lockscreen-weather.timer`

Comandos útiles:

```bash
systemctl --user status lockscreen-weather.timer
systemctl --user start lockscreen-weather.service   # actualizar ahora
journalctl --user -u lockscreen-weather.service     # ver errores
```

Para cambiar la ciudad, edita `LAT` y `LON` en el script y el texto `city` en
`WeatherWidget.qml`. Después ejecuta:

```bash
systemctl --user start lockscreen-weather.service
```

## Volver al bloqueo original

Para revertir solo la personalización de la pantalla de bloqueo (fuente, iconos
y animación), usa el respaldo que quedó dentro del tema:

```bash
cd ~/.local/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
cp backup-20261023-123242/LockScreenUi.qml \
   backup-20261023-123242/MainBlock.qml \
   backup-20261023-123242/WeatherWidget.qml \
   backup-20261023-123242/MediaControls.qml \
   backup-20261023-123242/NoPasswordUnlock.qml \
   backup-20261023-123242/qmldir .
rm -f FontConfig.qml LockClock.qml LockUserList.qml LockUserDelegate.qml \
      LockSessionManagementScreen.qml
```

Esto no revierte la fuente global del escritorio; para eso usa la sección
«Respaldos y reversión de la fuente global». Si vas a quitar la fuente instalada,
restaura antes la configuración global para que KDE no busque una familia que ya
no existe:

```bash
rm -rf ~/.local/share/fonts/CaskaydiaMono
fc-cache -f
```

Para volver por completo al bloqueo del sistema:

```bash
rm -rf ~/.local/share/plasma/shells/org.kde.plasma.desktop
cp ~/.config/kscreenlockerrc.bak-20261023-095140 ~/.config/kscreenlockerrc
systemctl --user disable --now lockscreen-weather.timer
```

El respaldo de la configuración original está en
`~/.config/kscreenlockerrc.bak-20261023-095140`.

## Pantalla de inicio de sesión (Plasma Login Manager)

El equipo usa **Plasma Login Manager** (`plasmalogin.service`), no SDDM. PLM no
permite temas QML personalizados como el bloqueo: su interfaz está compilada. Por
eso no se pudieron replicar los botones de cristal, el clima ni la animación al
teclear. Sí se igualaron el fondo, el reloj, la fuente, los colores, los iconos y
el cursor.

### Qué se cambió

- `/etc/plasmalogin.conf`:
  - `[Greeter] ShowClock=true`
  - `[Greeter] WallpaperPluginId=org.kde.image`
  - `[Greeter][Wallpaper][org.kde.image][General]` con `FillMode=2` e
    `Image=file:///usr/share/plasmalogin/wallpapers/wallhaven-49972w_1920x1080.png`.
  - Se conservó `[Autologin] Session=plasma`.
- Fondo: copia del fondo actual del bloqueo en
  `/usr/share/plasmalogin/wallpapers/wallhaven-49972w_1920x1080.png` y en
  `/var/lib/plasmalogin/wallpapers/` (ruta que usa el KCM).
- Fuente **CaskaydiaMono Nerd Font Mono** instalada globalmente en
  `/usr/local/share/fonts/CaskaydiaMono/` y caché regenerada con `fc-cache -f`.
- Tema de iconos **Kora** instalado globalmente en `/usr/share/icons/kora/`.
- Cursor **Win 10** instalado globalmente en `/usr/share/icons/Win 10/`.
- Ajustes de Plasma sincronizados al usuario del greeter en
  `/var/lib/plasmalogin/.config/`: `kdeglobals`, `plasmarc`,
  `plasma-localerc`, `kcminputrc` y `kwinoutputconfig.json`, con propietario
  `plasmalogin:plasmalogin`.

La instalación global es necesaria porque el greeter se ejecuta como el usuario
`plasmalogin` (uid 957, home `/var/lib/plasmalogin`) y `/home/dns10011` tiene
permisos `700`.

### Comprobar y cambiar

El greeter se puede probar sin cerrar la sesión:

```bash
timeout 12 /usr/lib/plasma-login-greeter --test
```

En modo de prueba el fondo se ve gris (`Qt::darkGray`); es normal, porque el
fondo real lo dibuja `plasma-login-wallpaper` en la sesión del greeter. Los
cambios se aplican al siguiente cierre de sesión, reinicio o apagado.

Para cambiar el fondo del login:

```bash
sudo cp ~/Descargas/mi-fondo.png /usr/share/plasmalogin/wallpapers/
sudoedit /etc/plasmalogin.conf
```

y actualiza `Image=file:///usr/share/plasmalogin/wallpapers/mi-fondo.png`.
También puedes usar **Preferencias del sistema → Pantalla de inicio de sesión**;
el KCM copia el fondo a `/var/lib/plasmalogin/wallpapers/` y reescribe la ruta.

### Respaldos y reversión

Antes de aplicar los cambios se guardaron:

- `/var/backups/plasmalogin/plasmalogin.conf.bak-20261023-232504`
- `/var/backups/plasmalogin/plasmalogin-config.bak-20261023-232504.tar.gz`
- Registro: `/var/log/plasmalogin-customization-20261023-232504.log`

Para revertir la configuración del login:

```bash
sudo cp /var/backups/plasmalogin/plasmalogin.conf.bak-20261023-232504 \
  /etc/plasmalogin.conf
sudo tar -C /var/lib/plasmalogin -xzf \
  /var/backups/plasmalogin/plasmalogin-config.bak-20261023-232504.tar.gz
sudo rm -f /var/lib/plasmalogin/.config/plasmarc \
  /var/lib/plasmalogin/.config/kcminputrc
sudo rm -rf /var/lib/plasmalogin/wallpapers \
  /usr/share/plasmalogin/wallpapers
sudo chown -R plasmalogin:plasmalogin /var/lib/plasmalogin/.config
```

Los activos globales se pueden quitar si ya no se usan:

```bash
sudo rm -rf /usr/local/share/fonts/CaskaydiaMono \
  /usr/share/icons/kora "/usr/share/icons/Win 10"
sudo fc-cache -f
```

El bloqueo y el escritorio siguen usando las copias de
`~/.local/share/fonts/CaskaydiaMono` y `~/.local/share/icons/kora`, así que
quitarlas del sistema no afecta la sesión del usuario.

## Rediseño (2 de noviembre de 2026)

Se aplicó igual al bloqueo (esta carpeta) y al tema de SDDM `~/sddm-bloqueo`.
Archivos nuevos en `contents/lockscreen/` y `~/sddm-bloqueo/`:

- `Fx.qml`: colores, iconos (glifos de la Nerd Font) y el estado "escribiendo".
- `FancyPasswordField.qml`, `UnlockButton.qml`: campo con puntos animados,
  partículas, borde degradado giratorio y botón redondo.
- `Aurora.qml`: luces de fondo que se encienden al escribir.
- `ActionDock.qml`: botón «Menú» con todos los iconos en una lista desplazable.
- Widgets: `CalendarWidget.qml`, `NowPlayingWidget.qml` (+ `NowPlayingSource.qml`),
  `WeatherWidget.qml` (con pronóstico de 3 días), `QuoteWidget.qml`.

Al escribir la contraseña: el reloj se encoge, los widgets y el menú salen,
el fondo se oscurece con luces de color y el avatar recibe un anillo animado.

Respaldos previos: `~/sddm-bloqueo.bak-20261102-180739` y
`~/.local/share/plasma/shells/lockscreen.bak-20261102-180739`.
Para instalar los cambios del login: `sudo bash ~/instalar-tema-bloqueo.sh`.
