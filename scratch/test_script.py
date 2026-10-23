import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageChops

# Semilla fija para reproducibilidad
random.seed(42)

# Paleta canónica del juego (estilo roca oscura / cripta de Exhume)
# Base grafito / pizarra azulada:
COLOR_STONE_BASE = (37, 43, 53)       # #252b35
COLOR_STONE_DARK = (24, 28, 36)       # #181c24
COLOR_STONE_DEEP = (16, 19, 25)       # #101319
COLOR_STONE_MID = (46, 54, 66)        # #2e3642
COLOR_STONE_LIGHT = (68, 79, 97)      # #444f61
COLOR_STONE_HIGHLIGHT = (95, 110, 132)# #5f6e84

# Hierro forjado / remaches / cadenas:
COLOR_IRON_BASE = (28, 32, 40)
COLOR_IRON_DARK = (14, 16, 20)
COLOR_IRON_LIGHT = (56, 64, 78)
COLOR_IRON_SPEC = (110, 125, 148)
COLOR_RUST = (52, 40, 32)

def crear_ruido_piedra(w, h, escala=4, opacidad=0.35):
    """Genera textura de grano y micro-relieve pétreo."""
    small_w, small_h = max(4, w // escala), max(4, h // escala)
    ruido_small = Image.new("L", (small_w, small_h))
    pix = ruido_small.load()
    for y in range(small_h):
        for x in range(small_w):
            v = random.randint(90, 165)
            pix[x, y] = v
    ruido = ruido_small.resize((w, h), Image.Resampling.BILINEAR)
    ruido = ruido.filter(ImageFilter.GaussianBlur(1.0))
    return ruido

def aplicar_relieve_y_grano(base_img, mascara_forma):
    """Añade micrograno y fracturas de piedra sobre una imagen base."""
    w, h = base_img.size
    ruido = crear_ruido_piedra(w, h, escala=3)
    
    # Crear capa RGBA con el grano modulado
    grano_rgba = Image.new("RGBA", (w, h))
    g_pix = grano_rgba.load()
    r_pix = ruido.load()
    m_pix = mascara_forma.load()
    
    for y in range(h):
        for x in range(w):
            alpha = m_pix[x, y]
            if alpha > 0:
                val = r_pix[x, y]
                # Variar luminosidad sutilmente
                delta = (val - 128) * 0.4
                r = min(255, max(0, int(COLOR_STONE_BASE[0] + delta)))
                g = min(255, max(0, int(COLOR_STONE_BASE[1] + delta)))
                b = min(255, max(0, int(COLOR_STONE_BASE[2] + delta)))
                g_pix[x, y] = (r, g, b, alpha)
    
    return grano_rgba

print("Módulo de ruido preparado correctamente.")
