#!/usr/bin/env python3
"""Genera los marcos SVG del tema de Plasma "LiquidGlass".

Aspecto "cristal líquido": relleno oscuro muy translúcido, brillo suave en la
parte superior, borde que refleja la luz (más brillante arriba a la izquierda),
un borde interior oscuro que da grosor y sombra suave alrededor.
"""
import gzip, os

THEME = os.path.expanduser("~/.local/share/plasma/desktoptheme/LiquidGlass")


def frame_parts(pfx, ox, oy, r, fill, fop, rim, gloss, margins, shadow=None, mask=True):
    """Devuelve (defs, elementos) de un marco de 9 piezas con el prefijo dado."""
    P = (pfx + "-") if pfx else ""
    gid = f"g_{pfx or 'main'}_{ox}_{oy}"
    d, e = [], []
    # degradado de brillo vertical para la banda superior
    d.append(f'''<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#fff" stop-opacity="{gloss[0]}"/>
  <stop offset="1" stop-color="#fff" stop-opacity="{gloss[1]}"/></linearGradient>''')
    F = f'fill="{fill}" fill-opacity="{fop}"'
    G = f'fill="url(#{gid})"'
    W = 10  # tamaño de las piezas que se estiran
    X0, X1, X2 = ox, ox + r + 4, ox + r + 4 + W + 4
    Y0, Y1, Y2 = oy, oy + r + 4, oy + r + 4 + W + 4
    tl, tr, bl, br, top, side_l, side_r, bot = rim
    ri = r - 1.5
    k18 = 0.18 if fop > 0 else 0
    k22 = 0.22 if fop > 0 else 0

    # esquinas
    e.append(f'''<g id="{P}topleft">
  <path d="M{X0},{Y0+r} A{r},{r} 0 0 1 {X0+r},{Y0} V{Y0+r} Z" {F}/>
  <path d="M{X0},{Y0+r} A{r},{r} 0 0 1 {X0+r},{Y0} V{Y0+r} Z" {G}/>
  <path d="M{X0+0.5},{Y0+r} A{r-0.5},{r-0.5} 0 0 1 {X0+r},{Y0+0.5}" fill="none" stroke="#fff" stroke-opacity="{tl}" stroke-width="1"/>
  <path d="M{X0+1.5},{Y0+r} A{ri},{ri} 0 0 1 {X0+r},{Y0+1.5}" fill="none" stroke="#000" stroke-opacity="{k18}" stroke-width="1"/>
</g>''')
    e.append(f'''<g id="{P}topright">
  <path d="M{X2},{Y0} A{r},{r} 0 0 1 {X2+r},{Y0+r} H{X2} Z" {F}/>
  <path d="M{X2},{Y0} A{r},{r} 0 0 1 {X2+r},{Y0+r} H{X2} Z" {G}/>
  <path d="M{X2},{Y0+0.5} A{r-0.5},{r-0.5} 0 0 1 {X2+r-0.5},{Y0+r}" fill="none" stroke="#fff" stroke-opacity="{tr}" stroke-width="1"/>
  <path d="M{X2},{Y0+1.5} A{ri},{ri} 0 0 1 {X2+r-1.5},{Y0+r}" fill="none" stroke="#000" stroke-opacity="{k18}" stroke-width="1"/>
</g>''')
    e.append(f'''<g id="{P}bottomleft">
  <path d="M{X0},{Y2} A{r},{r} 0 0 0 {X0+r},{Y2+r} V{Y2} Z" {F}/>
  <path d="M{X0},{Y2} A{r},{r} 0 0 0 {X0+r},{Y2+r} V{Y2} Z" fill="#fff" fill-opacity="{gloss[1]}"/>
  <path d="M{X0+0.5},{Y2} A{r-0.5},{r-0.5} 0 0 0 {X0+r},{Y2+r-0.5}" fill="none" stroke="#fff" stroke-opacity="{bl}" stroke-width="1"/>
  <path d="M{X0+1.5},{Y2} A{ri},{ri} 0 0 0 {X0+r},{Y2+r-1.5}" fill="none" stroke="#000" stroke-opacity="{k22}" stroke-width="1"/>
</g>''')
    e.append(f'''<g id="{P}bottomright">
  <path d="M{X2},{Y2+r} A{r},{r} 0 0 0 {X2+r},{Y2} H{X2} Z" {F}/>
  <path d="M{X2},{Y2+r} A{r},{r} 0 0 0 {X2+r},{Y2} H{X2} Z" fill="#fff" fill-opacity="{gloss[1]}"/>
  <path d="M{X2},{Y2+r-0.5} A{r-0.5},{r-0.5} 0 0 0 {X2+r-0.5},{Y2}" fill="none" stroke="#fff" stroke-opacity="{br}" stroke-width="1"/>
  <path d="M{X2},{Y2+r-1.5} A{ri},{ri} 0 0 0 {X2+r-1.5},{Y2}" fill="none" stroke="#000" stroke-opacity="{k22}" stroke-width="1"/>
</g>''')
    # bordes
    e.append(f'''<g id="{P}top">
  <rect x="{X1}" y="{Y0}" width="{W}" height="{r}" {F}/>
  <rect x="{X1}" y="{Y0}" width="{W}" height="{r}" {G}/>
  <rect x="{X1}" y="{Y0}" width="{W}" height="1" fill="#fff" fill-opacity="{top}"/>
  <rect x="{X1}" y="{Y0+1}" width="{W}" height="1" fill="#000" fill-opacity="{k18}"/>
</g>''')
    e.append(f'''<g id="{P}bottom">
  <rect x="{X1}" y="{Y2}" width="{W}" height="{r}" {F}/>
  <rect x="{X1}" y="{Y2}" width="{W}" height="{r}" fill="#fff" fill-opacity="{gloss[1]}"/>
  <rect x="{X1}" y="{Y2+r-1}" width="{W}" height="1" fill="#fff" fill-opacity="{bot}"/>
  <rect x="{X1}" y="{Y2+r-2}" width="{W}" height="1" fill="#000" fill-opacity="{k22}"/>
</g>''')
    e.append(f'''<g id="{P}left">
  <rect x="{X0}" y="{Y1}" width="{r}" height="{W}" {F}/>
  <rect x="{X0}" y="{Y1}" width="{r}" height="{W}" fill="#fff" fill-opacity="{gloss[1]}"/>
  <rect x="{X0}" y="{Y1}" width="1" height="{W}" fill="#fff" fill-opacity="{side_l}"/>
  <rect x="{X0+1}" y="{Y1}" width="1" height="{W}" fill="#000" fill-opacity="{k18}"/>
</g>''')
    e.append(f'''<g id="{P}right">
  <rect x="{X2}" y="{Y1}" width="{r}" height="{W}" {F}/>
  <rect x="{X2}" y="{Y1}" width="{r}" height="{W}" fill="#fff" fill-opacity="{gloss[1]}"/>
  <rect x="{X2+r-1}" y="{Y1}" width="1" height="{W}" fill="#fff" fill-opacity="{side_r}"/>
  <rect x="{X2+r-2}" y="{Y1}" width="1" height="{W}" fill="#000" fill-opacity="{k18}"/>
</g>''')
    e.append(f'<g id="{P}center"><rect x="{X1}" y="{Y1}" width="{W}" height="{W}" {F}/>'
             f'<rect x="{X1}" y="{Y1}" width="{W}" height="{W}" fill="#fff" fill-opacity="{gloss[1]}"/></g>')
    # márgenes del contenido
    mt, mb, ml, mr = margins
    hy = Y2 + r + 6
    e.append(f'<rect id="{P}hint-top-margin" x="{ox}" y="{hy}" width="2" height="{mt}" fill="none"/>')
    e.append(f'<rect id="{P}hint-bottom-margin" x="{ox+4}" y="{hy}" width="2" height="{mb}" fill="none"/>')
    e.append(f'<rect id="{P}hint-left-margin" x="{ox+8}" y="{hy}" width="{ml}" height="2" fill="none"/>')
    e.append(f'<rect id="{P}hint-right-margin" x="{ox+8}" y="{hy+4}" width="{mr}" height="2" fill="none"/>')
    if mask and not pfx.startswith("shadow"):
        mp = (pfx + "-mask-") if pfx else "mask-"
        mx = ox + 3 * r + 40
        for name, (x, y, w, h, shape) in {
            "topleft": (mx, oy, r, r, "tl"), "top": (mx + r + 4, oy, W, r, None), "topright": (mx + r + W + 8, oy, r, r, "tr"),
            "left": (mx, oy + r + 4, r, W, None), "center": (mx + r + 4, oy + r + 4, W, W, None), "right": (mx + r + W + 8, oy + r + 4, r, W, None),
            "bottomleft": (mx, oy + r + W + 8, r, r, "bl"), "bottom": (mx + r + 4, oy + r + W + 8, W, r, None), "bottomright": (mx + r + W + 8, oy + r + W + 8, r, r, "br"),
        }.items():
            if shape == "tl":
                e.append(f'<path id="{mp}{name}" d="M{x},{y+r} A{r},{r} 0 0 1 {x+r},{y} V{y+r} Z" fill="#000"/>')
            elif shape == "tr":
                e.append(f'<path id="{mp}{name}" d="M{x},{y} A{r},{r} 0 0 1 {x+r},{y+r} H{x} Z" fill="#000"/>')
            elif shape == "bl":
                e.append(f'<path id="{mp}{name}" d="M{x},{y} A{r},{r} 0 0 0 {x+r},{y+r} V{y} Z" fill="#000"/>')
            elif shape == "br":
                e.append(f'<path id="{mp}{name}" d="M{x},{y+r} A{r},{r} 0 0 0 {x+r},{y} H{x} Z" fill="#000"/>')
            else:
                e.append(f'<rect id="{mp}{name}" x="{x}" y="{y}" width="{w}" height="{h}" fill="#000"/>')
    return d, e


def shadow_parts(ox, oy, s, r, alpha, dy=3):
    """Piezas shadow-*: la sombra solo se dibuja FUERA del marco (no bajo el cristal)."""
    d, e = [], []
    mt, mb, ml, mr = s - dy, s + dy, s, s
    def rad(id_, cx, cy):
        R = r + s
        f = r / R
        d.append(f'''<radialGradient id="{id_}" cx="{cx}" cy="{cy}" r="{R}" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="{f-0.02:.3f}" stop-color="#000" stop-opacity="0"/>
  <stop offset="{f:.3f}" stop-color="#000" stop-opacity="{alpha}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>''')
    def lin(id_, x1, y1, x2, y2, a=alpha):
        d.append(f'''<linearGradient id="{id_}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="{a}"/></linearGradient>''')
    x, y = ox, oy
    # esquinas
    rad("sh-tl", x + ml + r, y + mt + r); e.append(f'<rect id="shadow-topleft" x="{x}" y="{y}" width="{ml+r}" height="{mt+r}" fill="url(#sh-tl)"/>')
    x2 = ox + 80
    rad("sh-tr", x2, y + mt + r); e.append(f'<rect id="shadow-topright" x="{x2}" y="{y}" width="{mr+r}" height="{mt+r}" fill="url(#sh-tr)"/>')
    y2 = oy + 80
    rad("sh-bl", x + ml + r, y2); e.append(f'<rect id="shadow-bottomleft" x="{x}" y="{y2}" width="{ml+r}" height="{mb+r}" fill="url(#sh-bl)"/>')
    rad("sh-br", x2, y2); e.append(f'<rect id="shadow-bottomright" x="{x2}" y="{y2}" width="{mr+r}" height="{mb+r}" fill="url(#sh-br)"/>')
    # bordes (solo el margen exterior)
    xm, ym = ox + 50, oy + 50
    lin("sh-t", 0, oy, 0, oy + mt, alpha * 0.7); e.append(f'<rect id="shadow-top" x="{xm}" y="{oy}" width="10" height="{mt}" fill="url(#sh-t)"/>')
    lin("sh-b", 0, y2 + mb, 0, y2); e.append(f'<rect id="shadow-bottom" x="{xm}" y="{y2}" width="10" height="{mb}" fill="url(#sh-b)"/>')
    lin("sh-l", ox, 0, ox + ml, 0); e.append(f'<rect id="shadow-left" x="{ox}" y="{ym}" width="{ml}" height="10" fill="url(#sh-l)"/>')
    lin("sh-r", x2 + 20 + mr, 0, x2 + 20, 0); e.append(f'<rect id="shadow-right" x="{x2+20}" y="{ym}" width="{mr}" height="10" fill="url(#sh-r)"/>')
    e.append(f'<rect id="shadow-center" x="{xm}" y="{ym}" width="10" height="10" fill="none"/>')
    hy = oy + 140
    e.append(f'<rect id="shadow-hint-top-margin" x="{ox}" y="{hy}" width="2" height="{mt}" fill="none"/>')
    e.append(f'<rect id="shadow-hint-bottom-margin" x="{ox+4}" y="{hy}" width="2" height="{mb}" fill="none"/>')
    e.append(f'<rect id="shadow-hint-left-margin" x="{ox+8}" y="{hy}" width="{ml}" height="2" fill="none"/>')
    e.append(f'<rect id="shadow-hint-right-margin" x="{ox+8}" y="{hy+4}" width="{mr}" height="2" fill="none"/>')
    return d, e


def write(path, groups):
    defs, els = [], []
    for d, e in groups:
        defs += d; els += e
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="900" height="900">'
           '<defs>' + "\n".join(defs) + '</defs>\n' + "\n".join(els) + '</svg>')
    for variant in ("", "translucent/", "solid/"):
        full = os.path.join(THEME, variant, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with gzip.open(full, "wb") as f:
            f.write(svg.encode())


DARK = "#14132a"
GLASS_RIM = (0.70, 0.55, 0.28, 0.34, 0.55, 0.30, 0.26, 0.30)   # tl tr bl br top left right bottom

# Panel (barras): muy translúcido, píldora redondeada
write("widgets/panel-background.svgz", [
    frame_parts("", 0, 0, 16, DARK, 0.42, GLASS_RIM, (0.20, 0.05), (4, 4, 10, 10)),
    shadow_parts(0, 300, 12, 16, 0.30),
])

# Menús y ventanas emergentes
write("dialogs/background.svgz", [
    frame_parts("", 0, 0, 18, DARK, 0.97, GLASS_RIM, (0.12, 0.03), (12, 12, 12, 12)),
    shadow_parts(0, 300, 18, 18, 0.40),
])

# Fondo de widgets del escritorio
write("widgets/background.svgz", [
    frame_parts("", 0, 0, 18, DARK, 0.50, GLASS_RIM, (0.14, 0.04), (14, 14, 14, 14)),
    shadow_parts(0, 300, 14, 18, 0.28),
])

# Tooltips
write("widgets/tooltip.svgz", [
    frame_parts("", 0, 0, 12, DARK, 0.86, GLASS_RIM, (0.12, 0.03), (8, 8, 10, 10)),
    shadow_parts(0, 300, 12, 12, 0.35),
])

# Resaltados de la barra de tareas (pastillas de cristal)
CLEAR = (0, 0, 0, 0, 0, 0, 0, 0)
tasks = []
y = 0
for pfx, fill, fop, rim, gloss in [
    ("normal", DARK, 0.0, CLEAR, (0.0, 0.0)),
    ("minimized", DARK, 0.0, CLEAR, (0.0, 0.0)),
    ("hover", "#ffffff", 0.10, (0.55, 0.45, 0.20, 0.25, 0.45, 0.22, 0.20, 0.22), (0.14, 0.03)),
    ("focus", "#a48cff", 0.22, (0.80, 0.60, 0.30, 0.35, 0.65, 0.30, 0.26, 0.30), (0.20, 0.05)),
    ("attention", "#ffb86b", 0.30, (0.70, 0.55, 0.30, 0.30, 0.55, 0.28, 0.24, 0.28), (0.18, 0.05)),
]:
    tasks.append(frame_parts(pfx, 0, y, 10, fill, fop, rim, gloss, (4, 4, 4, 4), mask=False))
    y += 80
write("widgets/tasks.svgz", tasks)
print("ok")
