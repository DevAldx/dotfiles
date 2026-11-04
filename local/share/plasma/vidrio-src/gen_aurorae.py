#!/usr/bin/env python3
# Genera el tema de decoración de ventanas "Vidrio" para Aurorae (KWin).
import os, sys
OUT = os.path.expanduser("~/.local/share/aurorae/themes/Vidrio")
os.makedirs(OUT, exist_ok=True)

P = 18          # sombra (padding)
R = 12          # radio esquinas superiores
RB = 4          # radio esquinas inferiores
B = 3           # borde lateral/inferior
TITLE = 32      # alto barra de título (edge top + title + edge bottom)
CW = P + R      # ancho de las piezas laterales/esquinas
TH = P + TITLE  # alto de las piezas superiores
BH = P + B + 3  # alto de las piezas inferiores
SH = 0.38       # opacidad de la sombra junto a la ventana

THEMES = {
    "decoration": dict(top="#302a5c", bot="#1a1830", side="#1a1830", a=0.74,
                       s1="#b9cdff", s2="#d6bcff", sa=0.80, hl=0.38),
    "decoration-inactive": dict(top="#1d1c2a", bot="#16151f", side="#16151f", a=0.78,
                       s1="#ffffff", s2="#ffffff", sa=0.16, hl=0.12),
}

def defs(pfx, t):
    return f'''
  <linearGradient id="{pfx}-tg" x1="0" y1="{P}" x2="0" y2="{TH}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{t['top']}" stop-opacity="{t['a']}"/>
    <stop offset="1" stop-color="{t['bot']}" stop-opacity="{t['a']}"/>
  </linearGradient>
  <linearGradient id="{pfx}-st" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{t['s1']}" stop-opacity="{t['sa']}"/>
    <stop offset="1" stop-color="{t['s2']}" stop-opacity="{t['sa']}"/>
  </linearGradient>'''

def shadow_lin(id_, x1, y1, x2, y2):
    return f'''<linearGradient id="{id_}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="{SH}"/></linearGradient>'''

def shadow_rad(id_, cx, cy, r0, r1):
    f = r0 / r1
    return f'''<radialGradient id="{id_}" cx="{cx}" cy="{cy}" r="{r1}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#000" stop-opacity="{SH}"/>
    <stop offset="{f:.4f}" stop-color="#000" stop-opacity="{SH}"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'''

def pieces(pfx, t, ox, oy):
    """Devuelve las 9 piezas colocadas a partir de (ox, oy) en el lienzo."""
    g = []
    sx = lambda x: x + ox
    sy = lambda y: y + oy
    st = f"url(#{pfx}-st)"
    sideFill = f'fill="{t["side"]}" fill-opacity="{t["a"]}"'
    # columnas: x0 = izquierda (CW), x1 = centro (1px de ancho, se estira), x2 = derecha
    X0, X1, X2 = 0, CW + 10, CW + 30
    Y0, Y1, Y2 = 0, TH + 10, TH + 30
    D = f'<defs>{defs(pfx, t)}'
    # sombras con ids propios por pieza (coordenadas absolutas)
    # ---- topleft
    x, y = sx(X0), sy(Y0)
    D += shadow_rad(f"{pfx}-s-tl", x + CW, y + P + R, R, R + P)
    g.append(f'''<g id="{pfx}-topleft">
  <rect x="{x}" y="{y}" width="{CW}" height="{TH}" fill="url(#{pfx}-s-tl)"/>
  <path d="M{x+P},{y+TH} V{y+P+R} A{R},{R} 0 0 1 {x+P+R},{y+P} H{x+CW} V{y+TH} Z" fill="url(#{pfx}-tg)"/>
  <path d="M{x+P+0.5},{y+TH} V{y+P+R} A{R-0.5},{R-0.5} 0 0 1 {x+P+R},{y+P+0.5} H{x+CW}" fill="none" stroke="{t['s1']}" stroke-opacity="{t['sa']}" stroke-width="1"/>
  <path d="M{x+P+1.5},{y+P+R+2} A{R-1.5},{R-1.5} 0 0 1 {x+P+R},{y+P+1.5} H{x+CW}" fill="none" stroke="#fff" stroke-opacity="{t['hl']}" stroke-width="1"/>
</g>''')
    # ---- top
    x, y = sx(X1), sy(Y0)
    D += shadow_lin(f"{pfx}-s-t", 0, y, 0, y + P)
    g.append(f'''<g id="{pfx}-top">
  <rect x="{x}" y="{y}" width="10" height="{P}" fill="url(#{pfx}-s-t)"/>
  <rect x="{x}" y="{y+P}" width="10" height="{TITLE}" fill="url(#{pfx}-tg)"/>
  <rect x="{x}" y="{y+P}" width="10" height="1" fill="url(#{pfx}-st)"/>
  <rect x="{x}" y="{y+P+1}" width="10" height="1" fill="#fff" fill-opacity="{t['hl']}"/>
</g>''')
    # ---- topright
    x, y = sx(X2), sy(Y0)
    D += shadow_rad(f"{pfx}-s-tr", x, y + P + R, R, R + P)
    g.append(f'''<g id="{pfx}-topright">
  <rect x="{x}" y="{y}" width="{CW}" height="{TH}" fill="url(#{pfx}-s-tr)"/>
  <path d="M{x},{y+P} A{R},{R} 0 0 1 {x+R},{y+P+R} V{y+TH} H{x} Z" fill="url(#{pfx}-tg)"/>
  <path d="M{x},{y+P+0.5} A{R-0.5},{R-0.5} 0 0 1 {x+R-0.5},{y+P+R} V{y+TH}" fill="none" stroke="{t['s2']}" stroke-opacity="{t['sa']}" stroke-width="1"/>
  <path d="M{x},{y+P+1.5} A{R-1.5},{R-1.5} 0 0 1 {x+R-1.5},{y+P+R+2}" fill="none" stroke="#fff" stroke-opacity="{t['hl']}" stroke-width="1"/>
</g>''')
    # ---- left
    x, y = sx(X0), sy(Y1)
    D += shadow_lin(f"{pfx}-s-l", x, 0, x + P, 0)
    g.append(f'''<g id="{pfx}-left">
  <rect x="{x}" y="{y}" width="{P}" height="10" fill="url(#{pfx}-s-l)"/>
  <rect x="{x+P}" y="{y}" width="{CW-P}" height="10" {sideFill}/>
  <rect x="{x+P}" y="{y}" width="1" height="10" fill="{t['s1']}" fill-opacity="{t['sa']}"/>
</g>''')
    # ---- center
    x, y = sx(X1), sy(Y1)
    g.append(f'''<g id="{pfx}-center"><rect x="{x}" y="{y}" width="10" height="10" {sideFill}/></g>''')
    # ---- right
    x, y = sx(X2), sy(Y1)
    D += shadow_lin(f"{pfx}-s-r", x + CW, 0, x + CW - P, 0)
    g.append(f'''<g id="{pfx}-right">
  <rect x="{x+CW-P}" y="{y}" width="{P}" height="10" fill="url(#{pfx}-s-r)"/>
  <rect x="{x}" y="{y}" width="{CW-P}" height="10" {sideFill}/>
  <rect x="{x+CW-P-1}" y="{y}" width="1" height="10" fill="{t['s2']}" fill-opacity="{t['sa']}"/>
</g>''')
    # ---- bottomleft
    x, y = sx(X0), sy(Y2)
    edge = BH - P   # borde inferior visible + parte oculta
    D += shadow_rad(f"{pfx}-s-bl", x + P + RB, y + edge - RB, RB, RB + P)
    g.append(f'''<g id="{pfx}-bottomleft">
  <rect x="{x}" y="{y}" width="{CW}" height="{BH}" fill="url(#{pfx}-s-bl)"/>
  <path d="M{x+P},{y} V{y+edge-RB} A{RB},{RB} 0 0 0 {x+P+RB},{y+edge} H{x+CW} V{y} Z" {sideFill}/>
  <path d="M{x+P+0.5},{y} V{y+edge-RB} A{RB-0.5},{RB-0.5} 0 0 0 {x+P+RB},{y+edge-0.5} H{x+CW}" fill="none" stroke="{t['s1']}" stroke-opacity="{t['sa']}" stroke-width="1"/>
</g>''')
    # ---- bottom
    x, y = sx(X1), sy(Y2)
    D += shadow_lin(f"{pfx}-s-b", 0, y + BH, 0, y + edge)
    g.append(f'''<g id="{pfx}-bottom">
  <rect x="{x}" y="{y}" width="10" height="{edge}" {sideFill}/>
  <rect x="{x}" y="{y+edge}" width="10" height="{P}" fill="url(#{pfx}-s-b)"/>
  <rect x="{x}" y="{y+edge-1}" width="10" height="1" fill="url(#{pfx}-st)"/>
</g>''')
    # ---- bottomright
    x, y = sx(X2), sy(Y2)
    D += shadow_rad(f"{pfx}-s-br", x + CW - P - RB, y + edge - RB, RB, RB + P)
    g.append(f'''<g id="{pfx}-bottomright">
  <rect x="{x}" y="{y}" width="{CW}" height="{BH}" fill="url(#{pfx}-s-br)"/>
  <path d="M{x},{y} V{y+edge} H{x+CW-P-RB} A{RB},{RB} 0 0 0 {x+CW-P},{y+edge-RB} V{y} Z" {sideFill}/>
  <path d="M{x},{y+edge-0.5} H{x+CW-P-RB} A{RB-0.5},{RB-0.5} 0 0 0 {x+CW-P-0.5},{y+edge-RB} V{y}" fill="none" stroke="{t['s2']}" stroke-opacity="{t['sa']}" stroke-width="1"/>
</g>''')
    return D + "</defs>", g

body, alldefs = [], []
oy = 0
for pfx, t in THEMES.items():
    d, g = pieces(pfx, t, 0, oy)
    alldefs.append(d); body += g
    oy += TH + 30 + BH + 20
# máscara (sin composición): rectángulos opacos
mask = []
for name, (x, y, w, h) in {"topleft": (0, 0, CW, TH), "top": (CW+10, 0, 10, TH), "topright": (CW+30, 0, CW, TH),
                           "left": (0, TH+10, CW, 10), "center": (CW+10, TH+10, 10, 10), "right": (CW+30, TH+10, CW, 10),
                           "bottomleft": (0, TH+30, CW, BH), "bottom": (CW+10, TH+30, 10, BH), "bottomright": (CW+30, TH+30, CW, BH)}.items():
    mask.append(f'<rect id="mask-{name}" x="{x}" y="{y+oy}" width="{w}" height="{h}" fill="#000"/>')
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{2*CW+40}" height="{oy+TH+BH+40}">' + "".join(alldefs) + "\n".join(body) + "\n".join(mask) + "</svg>"
open(f"{OUT}/decoration.svg", "w").write(svg)

# ---------------- botones ----------------
BS = 18
COL = {"close": "#ff7a8a", "maximize": "#7ff0dc", "restore": "#7ff0dc", "minimize": "#c49bff",
       "alldesktops": "#8ab4ff", "keepabove": "#8ab4ff", "keepbelow": "#8ab4ff", "shade": "#8ab4ff", "help": "#8ab4ff"}
GLYPH = {
    "close": "M6,6 L12,12 M12,6 L6,12",
    "maximize": "M9,5.5 V12.5 M5.5,9 H12.5",
    "restore": "M6,9 H12",
    "minimize": "M5.5,9 H12.5",
    "alldesktops": "M7,7 h4 v4 h-4 Z",
    "keepabove": "M6,10.5 L9,7 L12,10.5",
    "keepbelow": "M6,7.5 L9,11 L12,7.5",
    "shade": "M6,7 H12",
    "help": "M7,7.2 Q9,4.8 11,7.2 Q11,8.6 9,9.4 V10.5 M9,12.2 V12.4",
}
def button(name):
    c = COL[name]; gl = GLYPH[name]
    states = {
        "active":       (c, 0.95, 0.0, 6.0),
        "hover":        (c, 1.0, 1.0, 7.0),
        "pressed":      (c, 0.7, 1.0, 6.0),
        "inactive":     ("#ffffff", 0.22, 0.0, 6.0),
        "deactivated":  ("#ffffff", 0.10, 0.0, 6.0),
    }
    parts, x = [], 0
    for st, (col, op, gop, r) in states.items():
        cx, cy = x + BS / 2, BS / 2
        halo = f'<circle cx="{cx}" cy="{cy}" r="8.6" fill="{col}" fill-opacity="0.28"/>' if st == "hover" else ""
        parts.append(f'''<g id="{st}-center">
  <rect x="{x}" y="0" width="{BS}" height="{BS}" fill="none"/>
  {halo}<circle cx="{cx}" cy="{cy}" r="{r}" fill="{col}" fill-opacity="{op}"/>
  <path d="{gl}" transform="translate({x},0)" fill="none" stroke="#14122a" stroke-opacity="{gop}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
</g>''')
        x += BS + 4
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{x}" height="{BS}">' + "\n".join(parts) + "</svg>"
for n in COL:
    open(f"{OUT}/{n}.svg", "w").write(button(n))

open(f"{OUT}/Vidriorc", "w").write(f"""[General]
ActiveTextColor=232,230,255,255
InactiveTextColor=140,138,168,255
TitleAlignment=Center
TitleVerticalAlignment=Center
UseTextShadow=false
Shadow=true
Animation=160
DecorationPosition=0

[Layout]
BorderLeft={B}
BorderRight={B}
BorderBottom={B}
TitleEdgeTop=5
TitleEdgeBottom=5
TitleEdgeLeft=10
TitleEdgeRight=10
TitleBorderLeft=6
TitleBorderRight=6
TitleHeight={TITLE-10}
ButtonWidth={BS}
ButtonHeight={BS}
ButtonSpacing=6
ButtonMarginTop=2
ExplicitButtonSpacer=8
PaddingTop={P}
PaddingBottom={P}
PaddingLeft={P}
PaddingRight={P}
TitleEdgeTopMaximized=5
TitleEdgeBottomMaximized=5
TitleEdgeLeftMaximized=8
TitleEdgeRightMaximized=8
""")
open(f"{OUT}/metadata.desktop", "w").write("""[Desktop Entry]
Name=Vidrio
Comment=Bordes redondeados, borde degradado y botones de color
X-KDE-PluginInfo-Author=Claude para dns10011
X-KDE-PluginInfo-Name=Vidrio
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL_V3
X-KDE-PluginInfo-EnabledByDefault=true
X-KDE-PluginInfo-blur=true
""")
print("ok", OUT)
