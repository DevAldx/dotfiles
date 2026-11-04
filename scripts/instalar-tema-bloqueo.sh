#!/bin/bash
# Instala/actualiza el tema "bloqueo" de SDDM desde ~/sddm-bloqueo.
# Uso: sudo bash ~/instalar-tema-bloqueo.sh
# Para volver al tema anterior: cambia Current=bloqueo por Current=breeze
# en /etc/sddm.conf.d/10-apariencia.conf
set -e
U=dns10011
SRC=/home/$U/sddm-bloqueo
DST=/usr/share/sddm/themes/bloqueo
rm -rf "$DST"
cp -r "$SRC" "$DST"
chown -R root:root "$DST"
chmod -R a+rX "$DST"
# El clima lo actualiza tu usuario cada 15 min, así que ese archivo es tuyo
chown $U:$U "$DST/weatherdata.js"
sed -i 's/^Current=.*/Current=bloqueo/' /etc/sddm.conf.d/10-apariencia.conf
echo "Tema instalado en $DST"
grep Current /etc/sddm.conf.d/10-apariencia.conf
echo "Listo. Cierra sesión o reinicia para verlo."
