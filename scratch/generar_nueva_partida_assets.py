import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageChops

random.seed(2026)

# Paleta canónica de Exhume (cripta / pizarra oscura):
COLOR_FONDO_SLAB = (26, 31, 40)
COLOR_FONDO_CENTRO = (20, 24, 31)
COLOR_SOMBRA_PROF = (10, 12, 16)
COLOR_BISEL_EXT = (58, 69, 86)
COLOR_BISEL_SOMBRA = (12, 14, 18)
COLOR_BORDE_LINEA = (40, 48, 60)
COLOR_HERRAJE_HIERRO = (22, 26, 34)
COLOR_HERRAJE_LUZ = (70, 82, 102)

def crear_textura_pizarra(w, h, color_base, varianza=7):
    """Crea una base de pizarra con textura suave y uniforme."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rw, rh = max(4, w // 8), max(4, h // 8)
    ruido_peq = Image.new("L", (rw, rh))
    pix_r = ruido_peq.load()
    for y in range(rh):
        for x in range(rw):
            pix_r[x, y] = random.randint(128 - varianza, 128 + varianza)
    ruido = ruido_peq.resize((w, h), Image.Resampling.BILINEAR).filter(ImageFilter.GaussianBlur(2.0))
    r_pix = ruido.load()
    
    pix = img.load()
    r0, g0, b0 = color_base
    for y in range(h):
        for x in range(w):
            v = (r_pix[x, y] - 128)
            grad = int((1.0 - (y / float(h))) * 6)
            r = max(0, min(255, r0 + v + grad))
            g = max(0, min(255, g0 + v + grad))
            b = max(0, min(255, b0 + v + grad))
            pix[x, y] = (r, g, b, 255)
    return img

def dibujar_remache(draw, cx, cy, radio=7):
    """Dibuja un remache de hierro/bronce envejecido con volumen 3D."""
    draw.ellipse([cx - radio, cy - radio, cx + radio, cy + radio], fill=COLOR_SOMBRA_PROF)
    draw.ellipse([cx - radio + 1, cy - radio + 1, cx + radio - 1, cy + radio - 1], fill=(32, 38, 48))
    draw.ellipse([cx - radio + 2, cy - radio + 2, cx, cy], fill=(75, 88, 108))
    draw.ellipse([cx - radio + 3, cy - radio + 2, cx - 1, cy - 1], fill=(130, 148, 175))

def dibujar_placa_soporte(draw, cx, cy, ancho=48, alto=64, invertido=False):
    """Dibuja un soporte de anclaje de hierro reforzado con remaches y argolla."""
    x0, y0 = cx - ancho // 2, cy - alto // 2
    x1, y1 = cx + ancho // 2, cy + alto // 2
    
    draw.rounded_rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], radius=6, fill=COLOR_SOMBRA_PROF)
    draw.rounded_rectangle([x0, y0, x1, y1], radius=5, fill=COLOR_HERRAJE_HIERRO)
    draw.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=COLOR_HERRAJE_LUZ, width=2)
    draw.line([x0 + 1, y0 + 1, x0 + 1, y1 - 1], fill=COLOR_HERRAJE_LUZ, width=2)
    draw.line([x0 + 1, y1 - 1, x1 - 1, y1 - 1], fill=COLOR_SOMBRA_PROF, width=2)
    draw.line([x1 - 1, y0 + 1, x1 - 1, y1 - 1], fill=COLOR_SOMBRA_PROF, width=2)
    
    ry = y0 + 12 if not invertido else y1 - 12
    dibujar_remache(draw, cx, ry, radio=5)
    
    oy = y1 - 12 if not invertido else y0 + 12
    draw.ellipse([cx - 14, oy - 12, cx + 14, oy + 12], fill=COLOR_SOMBRA_PROF)
    draw.ellipse([cx - 12, oy - 10, cx + 12, oy + 10], fill=COLOR_HERRAJE_HIERRO)
    draw.ellipse([cx - 6, oy - 5, cx + 6, oy + 5], fill=(0, 0, 0, 0))
    draw.arc([cx - 11, oy - 9, cx + 11, oy + 9], start=180, end=270, fill=COLOR_HERRAJE_LUZ, width=2)

def crear_losa_generica(w, h, margen_x=32, margen_y=28, radio_esquina=20, rehundido=True):
    """Crea una losa rectangular de cantería biselada con centro rehundido."""
    puntos = [
        (margen_x + radio_esquina, margen_y),
        (w - margen_x - radio_esquina, margen_y),
        (w - margen_x, margen_y + radio_esquina),
        (w - margen_x, h - margen_y - radio_esquina),
        (w - margen_x - radio_esquina, h - margen_y),
        (margen_x + radio_esquina, h - margen_y),
        (margen_x, h - margen_y - radio_esquina),
        (margen_x, margen_y + radio_esquina),
    ]
    mascara = Image.new("L", (w, h), 0)
    draw_m = ImageDraw.Draw(mascara)
    draw_m.polygon(puntos, fill=255)
    
    textura = crear_textura_pizarra(w, h, COLOR_FONDO_SLAB, varianza=7)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.paste(textura, (0, 0), mascara)
    draw = ImageDraw.Draw(img)
    
    # Bisel de cantería
    draw.line([(margen_x + radio_esquina, margen_y), (w - margen_x - radio_esquina, margen_y)], fill=COLOR_BISEL_EXT, width=4)
    draw.line([(margen_x, margen_y + radio_esquina), (margen_x + radio_esquina, margen_y)], fill=COLOR_BISEL_EXT, width=4)
    draw.line([(margen_x, margen_y + radio_esquina), (margen_x, h - margen_y - radio_esquina)], fill=COLOR_BISEL_EXT, width=4)
    draw.line([(margen_x, h - margen_y - radio_esquina), (margen_x + radio_esquina, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(margen_x + radio_esquina, h - margen_y), (w - margen_x - radio_esquina, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(w - margen_x - radio_esquina, h - margen_y), (w - margen_x, h - margen_y - radio_esquina)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(w - margen_x, margen_y + radio_esquina), (w - margen_x, h - margen_y - radio_esquina)], fill=COLOR_BISEL_SOMBRA, width=4)
    
    if rehundido:
        in_x0, in_y0 = margen_x + 32, margen_y + 26
        in_x1, in_y1 = w - margen_x - 32, h - margen_y - 26
        draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=8, fill=COLOR_FONDO_CENTRO)
        draw.line([in_x0, in_y0, in_x1, in_y0], fill=COLOR_SOMBRA_PROF, width=4)
        draw.line([in_x0, in_y0, in_x0, in_y1], fill=COLOR_SOMBRA_PROF, width=4)
        draw.line([in_x0, in_y1, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
        draw.line([in_x1, in_y0, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
        
    return img

# 1. Rig Izquierdo: Tablón de Atributos (1020 x 1304)
def generar_attributes_board(ruta):
    w, h = 1020, 1304
    img = crear_losa_generica(w, h, margen_x=34, margen_y=30, radio_esquina=22, rehundido=True)
    draw = ImageDraw.Draw(img)
    # Herrajes de suspensión superiores (cadenas izquierda y derecha)
    dibujar_placa_soporte(draw, 140, 52, ancho=48, alto=64, invertido=False)
    dibujar_placa_soporte(draw, w - 140, 52, ancho=48, alto=64, invertido=False)
    # Herrajes inferiores hacia el botón volver
    dibujar_placa_soporte(draw, 180, h - 52, ancho=48, alto=64, invertido=True)
    
    # Canales horizontales decorativos para los atributos
    for y_offset in [250, 410, 570]:
        draw.line([100, y_offset, w - 100, y_offset], fill=COLOR_BORDE_LINEA, width=2)
        draw.line([100, y_offset + 1, w - 100, y_offset + 1], fill=COLOR_SOMBRA_PROF, width=1)
        
    img.save(ruta, "PNG")
    print(f"Generado attributes_board: {ruta}")

# 2. Marco del Área de Dados (900 x 441)
def generar_dice_area_frame(ruta):
    w, h = 900, 441
    img = crear_losa_generica(w, h, margen_x=22, margen_y=18, radio_esquina=14, rehundido=True)
    draw = ImageDraw.Draw(img)
    # Canto cincelado interior de bandeja profunda
    draw.rounded_rectangle([70, 50, w - 70, h - 50], radius=10, fill=(14, 17, 22))
    draw.rounded_rectangle([70, 50, w - 70, h - 50], radius=10, outline=COLOR_SOMBRA_PROF, width=4)
    # Remaches en las 4 esquinas de la bandeja
    for cx in [60, w - 60]:
        for cy in [45, h - 45]:
            dibujar_remache(draw, cx, cy, radio=6)
    img.save(ruta, "PNG")
    print(f"Generado dice_area_frame: {ruta}")

# 3. Botón Pequeño de Tirar / Opciones (440 x 224)
def generar_small_button(ruta):
    w, h = 440, 224
    img = crear_losa_generica(w, h, margen_x=16, margen_y=12, radio_esquina=10, rehundido=False)
    draw = ImageDraw.Draw(img)
    # Recuadro interior oscuro con bisel
    draw.rounded_rectangle([28, 22, w - 28, h - 22], radius=6, fill=COLOR_FONDO_CENTRO)
    draw.rounded_rectangle([28, 22, w - 28, h - 22], radius=6, outline=COLOR_BORDE_LINEA, width=2)
    # Remaches en los lados
    dibujar_remache(draw, 42, h // 2, radio=5)
    dibujar_remache(draw, w - 42, h // 2, radio=5)
    img.save(ruta, "PNG")
    print(f"Generado small_button: {ruta}")

# 4. Botón Volver (840 x 285)
def generar_back_board(ruta):
    w, h = 840, 285
    img = crear_losa_generica(w, h, margen_x=24, margen_y=18, radio_esquina=14, rehundido=True)
    draw = ImageDraw.Draw(img)
    # Herraje de suspensión superior
    dibujar_placa_soporte(draw, w // 2, 38, ancho=48, alto=56, invertido=False)
    dibujar_remache(draw, 70, h // 2, radio=7)
    dibujar_remache(draw, w - 70, h // 2, radio=7)
    img.save(ruta, "PNG")
    print(f"Generado back_board: {ruta}")

# 5. Tira de Atributo (680 x 112)
def generar_attribute_strip(ruta):
    w, h = 680, 112
    img = crear_losa_generica(w, h, margen_x=10, margen_y=8, radio_esquina=8, rehundido=True)
    img.save(ruta, "PNG")
    print(f"Generado attribute_strip: {ruta}")

# 6. Campo de Nombre (1120 x 114)
def generar_name_field(ruta):
    w, h = 1120, 114
    img = crear_losa_generica(w, h, margen_x=12, margen_y=8, radio_esquina=8, rehundido=True)
    draw = ImageDraw.Draw(img)
    # Surco cincelado de entrada de texto
    draw.rounded_rectangle([30, 18, w - 30, h - 18], radius=6, fill=(15, 18, 24))
    draw.rounded_rectangle([30, 18, w - 30, h - 18], radius=6, outline=COLOR_SOMBRA_PROF, width=2)
    draw.line([30, h - 18, w - 30, h - 18], fill=COLOR_BORDE_LINEA, width=2)
    img.save(ruta, "PNG")
    print(f"Generado name_field: {ruta}")

# 7. Rig Central: Ficha de Personaje (1240 x 1939)
def generar_character_sheet_board(ruta):
    w, h = 1240, 1939
    img = crear_losa_generica(w, h, margen_x=42, margen_y=38, radio_esquina=26, rehundido=True)
    draw = ImageDraw.Draw(img)
    
    # Herrajes superiores de suspensión de cadenas (a ~18% y ~82%)
    dibujar_placa_soporte(draw, int(w * 0.18), 58, ancho=56, alto=76, invertido=False)
    dibujar_placa_soporte(draw, int(w * 0.82), 58, ancho=56, alto=76, invertido=False)
    
    # Marco cincelado donde descansará el retrato (entre Y=240 y Y=960 aprox)
    rec_x0, rec_y0 = 80, 230
    rec_x1, rec_y1 = w - 80, 970
    draw.rounded_rectangle([rec_x0, rec_y0, rec_x1, rec_y1], radius=14, outline=COLOR_SOMBRA_PROF, width=6)
    draw.rounded_rectangle([rec_x0 + 4, rec_y0 + 4, rec_x1 - 4, rec_y1 - 4], radius=10, outline=COLOR_BORDE_LINEA, width=2)
    
    # Línea divisoria de cantería entre retrato y datos
    draw.line([90, 1010, w - 90, 1010], fill=COLOR_BORDE_LINEA, width=3)
    draw.line([90, 1012, w - 90, 1012], fill=COLOR_SOMBRA_PROF, width=2)
    
    img.save(ruta, "PNG")
    print(f"Generado character_sheet_board: {ruta}")

# 8. Rig Derecho: Altar de Ritual y Orígenes (1020 x 1494)
def generar_ritual_board(ruta):
    w, h = 1020, 1494
    img = crear_losa_generica(w, h, margen_x=36, margen_y=32, radio_esquina=24, rehundido=True)
    draw = ImageDraw.Draw(img)
    
    # Herrajes de suspensión
    dibujar_placa_soporte(draw, 140, 52, ancho=48, alto=64, invertido=False)
    dibujar_placa_soporte(draw, w - 140, 52, ancho=48, alto=64, invertido=False)
    # Herrajes inferiores hacia el rig de comenzar
    dibujar_placa_soporte(draw, 160, h - 52, ancho=48, alto=64, invertido=True)
    dibujar_placa_soporte(draw, w - 160, h - 52, ancho=48, alto=64, invertido=True)
    
    img.save(ruta, "PNG")
    print(f"Generado ritual_board: {ruta}")

# 9. Retratos: Creación de alcoba de piedra + retrato oficial de héroe (944 x 1280)
def generar_retrato_enmarcado(ruta_original, ruta_salida, es_nadie=False):
    w, h = 944, 1280
    # Fondo de hornacina/alcoba de piedra
    img = crear_losa_generica(w, h, margen_x=28, margen_y=24, radio_esquina=18, rehundido=True)
    draw = ImageDraw.Draw(img)
    
    # Marco de piedra interior
    in_x0, in_y0 = 60, 50
    in_x1, in_y1 = w - 60, h - 50
    draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=12, fill=(12, 14, 18))
    draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=12, outline=COLOR_SOMBRA_PROF, width=6)
    
    # Cargar y colocar ilustración
    if es_nadie:
        # Generar silueta sombría de viajero encapuchado en estilo pixel art / grabado
        silueta = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw_s = ImageDraw.Draw(silueta)
        cx, cy = w // 2, h // 2 - 40
        # Capucha
        draw_s.polygon([
            (cx - 180, cy + 340),
            (cx - 140, cy + 80),
            (cx - 120, cy - 140),
            (cx - 40, cy - 280),
            (cx, cy - 310),
            (cx + 40, cy - 280),
            (cx + 120, cy - 140),
            (cx + 140, cy + 80),
            (cx + 180, cy + 340),
        ], fill=(18, 22, 28))
        # Ojos tenues en la sombra de la capucha
        draw_s.ellipse([cx - 36, cy - 65, cx - 18, cy - 55], fill=(190, 165, 110, 200))
        draw_s.ellipse([cx + 18, cy - 65, cx + 36, cy - 55], fill=(190, 165, 110, 200))
        # Capa y hombros
        draw_s.polygon([
            (cx - 320, h - 80),
            (cx - 240, cy + 240),
            (cx + 240, cy + 240),
            (cx + 320, h - 80),
        ], fill=(14, 17, 22))
        img.paste(silueta, (0, 0), silueta)
    elif os.path.exists(ruta_original):
        heroe = Image.open(ruta_original).convert("RGBA")
        # Escalar proporcionalmente para llenar la hornacina con aspecto pixel art nítido
        escala = min((in_x1 - in_x0 - 20) / float(heroe.width), (in_y1 - in_y0 - 20) / float(heroe.height))
        # Para retratos pequeños como 120x190, usar escala entera con Nearest
        escala_entera = max(1, int(escala))
        heroe_escalado = heroe.resize((heroe.width * escala_entera, heroe.height * escala_entera), Image.Resampling.NEAREST)
        
        pos_x = in_x0 + (in_x1 - in_x0 - heroe_escalado.width) // 2
        pos_y = in_y0 + (in_y1 - in_y0 - heroe_escalado.height) // 2
        img.paste(heroe_escalado, (pos_x, pos_y), heroe_escalado)
        
    # Bisel de luz alrededor de la hornacina
    draw.arc([in_x0 + 4, in_y0 + 4, in_x1 - 4, in_y1 - 4], start=180, end=270, fill=COLOR_HERRAJE_LUZ, width=2)
    
    if ruta_salida.lower().endswith(".jpg") or ruta_salida.lower().endswith(".jpeg"):
        img.convert("RGB").save(ruta_salida, "JPEG", quality=95)
    else:
        img.save(ruta_salida, "PNG")
    print(f"Generado retrato: {ruta_salida}")

if __name__ == "__main__":
    base_dir = "assets/ui/panels/new_game"
    
    generar_attributes_board(os.path.join(base_dir, "attributes/attributes_board.png"))
    generar_dice_area_frame(os.path.join(base_dir, "dice/dice_area_frame.png"))
    generar_small_button(os.path.join(base_dir, "buttons/small_button.png"))
    generar_back_board(os.path.join(base_dir, "buttons/back_board.png"))
    generar_attribute_strip(os.path.join(base_dir, "fields/attribute_strip.png"))
    generar_name_field(os.path.join(base_dir, "fields/name_field.png"))
    generar_character_sheet_board(os.path.join(base_dir, "character/character_sheet_board.png"))
    generar_ritual_board(os.path.join(base_dir, "ritual/ritual_board.png"))
    
    # Retratos oficiales desde dialogue
    dir_diag = "assets/characters/player/dialogue"
    generar_retrato_enmarcado(os.path.join(dir_diag, "guerrero.png"), os.path.join(base_dir, "knight.jpg"))
    generar_retrato_enmarcado(os.path.join(dir_diag, "ladron.png"), os.path.join(base_dir, "rogue.png"))
    generar_retrato_enmarcado(os.path.join(dir_diag, "mago.png"), os.path.join(base_dir, "mage.png"))
    generar_retrato_enmarcado("", os.path.join(base_dir, "nadie.png"), es_nadie=True)
    
    print("¡Todos los assets de Nueva Partida generados con éxito!")
