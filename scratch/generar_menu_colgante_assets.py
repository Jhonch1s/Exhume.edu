import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageChops

random.seed(2026)

# Paleta refinada estilo cripta / losa pétrea oscura de Exhume:
COLOR_FONDO_SLAB = (26, 31, 40)       # Pizarra oscura uniforme
COLOR_FONDO_CENTRO = (20, 24, 31)     # Centro rehundido oscuro (alto contraste de texto)
COLOR_SOMBRA_PROF = (10, 12, 16)      # Sombra de cincel / cavidades
COLOR_BISEL_EXT = (58, 69, 86)        # Borde iluminado superior/izq
COLOR_BISEL_SOMBRA = (12, 14, 18)     # Borde inferior sombreado
COLOR_BORDE_LINEA = (40, 48, 60)      # Borde cincelado
COLOR_HERRAJE_HIERRO = (22, 26, 34)   # Placas de hierro forjado
COLOR_HERRAJE_LUZ = (70, 82, 102)     # Brillo metálico del hierro
COLOR_REMACHE_ORO = (140, 120, 85)    # Remaches bronce/hierro envejecido

def crear_textura_pizarra(w, h, color_base, varianza=8):
    """Crea una base de pizarra con textura suave y uniforme, sin ruido molesto."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Ruido sutil de baja frecuencia
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
            # Sutil gradiente vertical (luz cenital tenue)
            grad = int((1.0 - (y / float(h))) * 6)
            r = max(0, min(255, r0 + v + grad))
            g = max(0, min(255, g0 + v + grad))
            b = max(0, min(255, b0 + v + grad))
            pix[x, y] = (r, g, b, 255)
    return img

def dibujar_remache(draw, cx, cy, radio=9):
    """Dibuja un remache de hierro/bronce envejecido con volumen 3D."""
    draw.ellipse([cx - radio, cy - radio, cx + radio, cy + radio], fill=COLOR_SOMBRA_PROF)
    draw.ellipse([cx - radio + 1, cy - radio + 1, cx + radio - 1, cy + radio - 1], fill=(32, 38, 48))
    draw.ellipse([cx - radio + 3, cy - radio + 2, cx + 1, cy + 1], fill=(75, 88, 108))
    draw.ellipse([cx - radio + 4, cy - radio + 3, cx - 1, cy], fill=(130, 148, 175))

def dibujar_placa_soporte(draw, cx, cy, ancho=52, alto=68, invertido=False):
    """Dibuja un soporte de anclaje de hierro reforzado con remaches y argolla."""
    x0, y0 = cx - ancho // 2, cy - alto // 2
    x1, y1 = cx + ancho // 2, cy + alto // 2
    
    # Placa de hierro
    draw.rounded_rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], radius=6, fill=COLOR_SOMBRA_PROF)
    draw.rounded_rectangle([x0, y0, x1, y1], radius=5, fill=COLOR_HERRAJE_HIERRO)
    # Bisel metálico
    draw.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=COLOR_HERRAJE_LUZ, width=2)
    draw.line([x0 + 1, y0 + 1, x0 + 1, y1 - 1], fill=COLOR_HERRAJE_LUZ, width=2)
    draw.line([x0 + 1, y1 - 1, x1 - 1, y1 - 1], fill=COLOR_SOMBRA_PROF, width=2)
    draw.line([x1 - 1, y0 + 1, x1 - 1, y1 - 1], fill=COLOR_SOMBRA_PROF, width=2)
    
    # Remache
    ry = y0 + 14 if not invertido else y1 - 14
    dibujar_remache(draw, cx, ry, radio=6)
    
    # Argolla/ojo de hierro por donde pasa la cadena
    oy = y1 - 12 if not invertido else y0 + 12
    draw.ellipse([cx - 16, oy - 14, cx + 16, oy + 14], fill=COLOR_SOMBRA_PROF)
    draw.ellipse([cx - 14, oy - 12, cx + 14, oy + 12], fill=COLOR_HERRAJE_HIERRO)
    draw.ellipse([cx - 7, oy - 6, cx + 7, oy + 6], fill=(0, 0, 0, 0))
    # Brillo de argolla
    draw.arc([cx - 13, oy - 11, cx + 13, oy + 11], start=180, end=270, fill=COLOR_HERRAJE_LUZ, width=3)

def generar_menu_board_pulido(ruta_salida):
    """Genera la losa de piedra para opciones del menú (2176 x 544)."""
    w, h = 2176, 544
    margen_x = 36
    margen_y = 30
    
    # 1. Base sólida con máscara
    mascara = Image.new("L", (w, h), 0)
    draw_m = ImageDraw.Draw(mascara)
    # Losa rectangular sólida con esquinas biseladas (corte de cantería a 45 grados)
    puntos_losa = [
        (margen_x + 22, margen_y),
        (w - margen_x - 22, margen_y),
        (w - margen_x, margen_y + 22),
        (w - margen_x, h - margen_y - 22),
        (w - margen_x - 22, h - margen_y),
        (margen_x + 22, h - margen_y),
        (margen_x, h - margen_y - 22),
        (margen_x, margen_y + 22),
    ]
    draw_m.polygon(puntos_losa, fill=255)
    
    # 2. Textura de piedra
    textura = crear_textura_pizarra(w, h, COLOR_FONDO_SLAB, varianza=7)
    
    # Aplicar máscara
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.paste(textura, (0, 0), mascara)
    draw = ImageDraw.Draw(img)
    
    # 3. Bisel exterior de cantería
    # Iluminación arriba y a la izquierda
    draw.line([(margen_x + 22, margen_y), (w - margen_x - 22, margen_y)], fill=COLOR_BISEL_EXT, width=4)
    draw.line([(margen_x, margen_y + 22), (margen_x + 22, margen_y)], fill=COLOR_BISEL_EXT, width=4)
    draw.line([(margen_x, margen_y + 22), (margen_x, h - margen_y - 22)], fill=COLOR_BISEL_EXT, width=4)
    # Sombra abajo y a la derecha
    draw.line([(margen_x, h - margen_y - 22), (margen_x + 22, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(margen_x + 22, h - margen_y), (w - margen_x - 22, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(w - margen_x - 22, h - margen_y), (w - margen_x, h - margen_y - 22)], fill=COLOR_BISEL_SOMBRA, width=4)
    draw.line([(w - margen_x, margen_y + 22), (w - margen_x, h - margen_y - 22)], fill=COLOR_BISEL_SOMBRA, width=4)
    
    # 4. Campo interior rehundido y oscuro (para que las letras resalten con total claridad)
    in_x0, in_y0 = margen_x + 36, margen_y + 30
    in_x1, in_y1 = w - margen_x - 36, h - margen_y - 30
    # Fondo rehundido
    draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=8, fill=COLOR_FONDO_CENTRO)
    # Surco de cincel oscuro en el borde superior e izquierdo
    draw.line([in_x0, in_y0, in_x1, in_y0], fill=COLOR_SOMBRA_PROF, width=4)
    draw.line([in_x0, in_y0, in_x0, in_y1], fill=COLOR_SOMBRA_PROF, width=4)
    # Resalte de cincel en borde inferior y derecho
    draw.line([in_x0, in_y1, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
    draw.line([in_x1, in_y0, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
    
    # Filete sutil ornamental en los extremos (estilo estela funeraria)
    filete_izq = in_x0 + 60
    filete_der = in_x1 - 60
    draw.line([filete_izq, in_y0 + 12, filete_izq, in_y1 - 12], fill=COLOR_BORDE_LINEA, width=2)
    draw.line([filete_der, in_y0 + 12, filete_der, in_y1 - 12], fill=COLOR_BORDE_LINEA, width=2)
    
    # 5. Puntos de anclaje de cadenas (20.833% y 79.166%)
    x_cad_izq = int(w * 0.208333)
    x_cad_der = int(w * 0.791666)
    
    # Herrajes de anclaje superior
    dibujar_placa_soporte(draw, x_cad_izq, margen_y + 24, ancho=48, alto=64, invertido=False)
    dibujar_placa_soporte(draw, x_cad_der, margen_y + 24, ancho=48, alto=64, invertido=False)
    # Herrajes de anclaje inferior
    dibujar_placa_soporte(draw, x_cad_izq, h - margen_y - 24, ancho=48, alto=64, invertido=True)
    dibujar_placa_soporte(draw, x_cad_der, h - margen_y - 24, ancho=48, alto=64, invertido=True)
    
    img.save(ruta_salida, "PNG")
    print(f"Generado menu_board refinado: {ruta_salida}")

def generar_cadenas_verticales_pulidas(ruta_salida):
    """Genera cadenas de hierro forjado macizo de mazmorra (544 x 2176)."""
    w, h = 544, 2176
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx = w // 2
    periodo = h / 7.0  # 7 pares exactos de eslabones
    
    for i in range(8):
        y_base = i * periodo
        
        # 1. Eslabón de canto (perfil vertical detrás)
        py0 = int(y_base + periodo * 0.32)
        py1 = int(y_base + periodo * 0.92)
        p_ancho = 68
        
        # Sombra
        draw.rounded_rectangle([cx - p_ancho//2 - 4, py0 - 2, cx + p_ancho//2 + 4, py1 + 2], radius=20, fill=COLOR_SOMBRA_PROF)
        # Núcleo
        draw.rounded_rectangle([cx - p_ancho//2, py0, cx + p_ancho//2, py1], radius=18, fill=COLOR_HERRAJE_HIERRO)
        # Brillo especular
        draw.line([cx - 14, py0 + 12, cx - 14, py1 - 12], fill=COLOR_HERRAJE_LUZ, width=8)
        draw.line([cx - 12, py0 + 16, cx - 12, py1 - 16], fill=(140, 160, 190), width=3)
        # Sombra derecha
        draw.line([cx + 16, py0 + 10, cx + 16, py1 - 10], fill=COLOR_SOMBRA_PROF, width=8)
        
        # 2. Eslabón frontal (anillo ancho)
        fy0 = int(y_base - periodo * 0.16)
        fy1 = int(y_base + periodo * 0.52)
        f_ancho = 210
        grosor = 52
        
        # Sombra exterior
        draw.rounded_rectangle([cx - f_ancho//2 - 6, fy0 - 4, cx + f_ancho//2 + 6, fy1 + 6], radius=grosor, fill=COLOR_SOMBRA_PROF)
        # Anillo cuerpo
        draw.rounded_rectangle([cx - f_ancho//2, fy0, cx + f_ancho//2, fy1], radius=grosor, fill=(34, 40, 52))
        
        # Perforación hueca central
        in_w = f_ancho - grosor * 2
        in_h = (fy1 - fy0) - grosor * 2
        in_x0 = cx - in_w // 2
        in_x1 = cx + in_w // 2
        in_y0 = fy0 + grosor
        in_y1 = fy1 - grosor
        
        # Recorte de hueco
        draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=in_w//2, fill=(0, 0, 0, 0))
        # Borde interno sombreado
        draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=in_w//2, outline=COLOR_SOMBRA_PROF, width=6)
        
        # Iluminación 3D del aro frontal
        # Arco superior-izquierdo
        draw.arc([cx - f_ancho//2 + 6, fy0 + 6, cx + f_ancho//2 - 6, fy1 - 6], start=160, end=270, fill=COLOR_HERRAJE_LUZ, width=9)
        draw.arc([cx - f_ancho//2 + 10, fy0 + 9, cx + f_ancho//2 - 10, fy1 - 9], start=180, end=255, fill=(155, 175, 205), width=4)
        # Arco inferior-derecho oscuro
        draw.arc([cx - f_ancho//2 + 6, fy0 + 6, cx + f_ancho//2 - 6, fy1 - 6], start=0, end=90, fill=COLOR_SOMBRA_PROF, width=10)

    # Textura metálica sutil
    textura_metal = crear_textura_pizarra(w, h, (0, 0, 0), varianza=10)
    pix_m = textura_metal.load()
    pix = img.load()
    for y in range(h):
        for x in range(w):
            if pix[x, y][3] > 0:
                nv = pix_m[x, y][0] - 128
                r = max(0, min(255, int(pix[x, y][0] + nv * 0.12)))
                g = max(0, min(255, int(pix[x, y][1] + nv * 0.12)))
                b = max(0, min(255, int(pix[x, y][2] + nv * 0.12)))
                pix[x, y] = (r, g, b, pix[x, y][3])
                
    img.save(ruta_salida, "PNG")
    print(f"Generado chain_vertical refinado: {ruta_salida}")

def generar_logo_sign_pulido(ruta_empty, ruta_exhume, ruta_mask):
    """Genera la estela/cartel del logo en piedra cincelada (1904 x 640)."""
    w, h = 1904, 640
    margen_x = 44
    margen_y = 38
    
    # 1. Forma poligonal noble de dintel de cripta
    puntos_estela = [
        (margen_x + 36, margen_y),
        (w - margen_x - 36, margen_y),
        (w - margen_x, margen_y + 36),
        (w - margen_x, h - margen_y - 36),
        (w - margen_x - 36, h - margen_y),
        (margen_x + 36, h - margen_y),
        (margen_x, h - margen_y - 36),
        (margen_x, margen_y + 36),
    ]
    mascara = Image.new("L", (w, h), 0)
    draw_m = ImageDraw.Draw(mascara)
    draw_m.polygon(puntos_estela, fill=255)
    
    textura = crear_textura_pizarra(w, h, COLOR_FONDO_SLAB, varianza=7)
    img_empty = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img_empty.paste(textura, (0, 0), mascara)
    draw = ImageDraw.Draw(img_empty)
    
    # Bisel exterior
    draw.line([(margen_x + 36, margen_y), (w - margen_x - 36, margen_y)], fill=COLOR_BISEL_EXT, width=5)
    draw.line([(margen_x, margen_y + 36), (margen_x + 36, margen_y)], fill=COLOR_BISEL_EXT, width=5)
    draw.line([(margen_x, margen_y + 36), (margen_x, h - margen_y - 36)], fill=COLOR_BISEL_EXT, width=5)
    draw.line([(margen_x, h - margen_y - 36), (margen_x + 36, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=5)
    draw.line([(margen_x + 36, h - margen_y), (w - margen_x - 36, h - margen_y)], fill=COLOR_BISEL_SOMBRA, width=5)
    draw.line([(w - margen_x - 36, h - margen_y), (w - margen_x, h - margen_y - 36)], fill=COLOR_BISEL_SOMBRA, width=5)
    draw.line([(w - margen_x, margen_y + 36), (w - margen_x, h - margen_y - 36)], fill=COLOR_BISEL_SOMBRA, width=5)
    
    # Recuadro interior oscuro
    in_x0, in_y0 = margen_x + 42, margen_y + 36
    in_x1, in_y1 = w - margen_x - 42, h - margen_y - 36
    draw.rounded_rectangle([in_x0, in_y0, in_x1, in_y1], radius=10, fill=COLOR_FONDO_CENTRO)
    draw.line([in_x0, in_y0, in_x1, in_y0], fill=COLOR_SOMBRA_PROF, width=5)
    draw.line([in_x0, in_y0, in_x0, in_y1], fill=COLOR_SOMBRA_PROF, width=5)
    draw.line([in_x0, in_y1, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
    draw.line([in_x1, in_y0, in_x1, in_y1], fill=COLOR_BORDE_LINEA, width=2)
    
    # Herrajes de anclaje (23.07% y 76.92%)
    x_cad_izq = int(w * 0.2307)
    x_cad_der = int(w * 0.7692)
    dibujar_placa_soporte(draw, x_cad_izq, margen_y + 26, ancho=52, alto=68, invertido=False)
    dibujar_placa_soporte(draw, x_cad_der, margen_y + 26, ancho=52, alto=68, invertido=False)
    dibujar_placa_soporte(draw, x_cad_izq, h - margen_y - 26, ancho=52, alto=68, invertido=True)
    dibujar_placa_soporte(draw, x_cad_der, h - margen_y - 26, ancho=52, alto=68, invertido=True)
    
    # Guardar versión vacía
    img_empty.save(ruta_empty, "PNG")
    print(f"Generado logo_sign_empty refinado: {ruta_empty}")
    
    # 2. Versión con el logo EXHUME grabado
    img_exhume = img_empty.copy()
    if os.path.exists(ruta_mask):
        mask = Image.open(ruta_mask).convert("L")
        if mask.size != (w, h):
            mask = mask.resize((w, h), Image.Resampling.LANCZOS)
            
        sombra = ImageChops.offset(mask, 3, 4)
        luz = ImageChops.offset(mask, -2, -2)
        bisel_luz = ImageChops.subtract(luz, mask)
        bisel_sombra = ImageChops.subtract(sombra, mask)
        
        pix = img_exhume.load()
        m_pix = mask.load()
        bl_pix = bisel_luz.load()
        bs_pix = bisel_sombra.load()
        
        # Versión 2: Letras de EXHUME incisas con pigmento de oro/hueso antiguo y bisel de sombra
        color_pigmento_base = (205, 188, 152)      # Hueso/oro antiguo
        color_pigmento_luz = (240, 228, 202)       # Resalte de cantería
        
        for y in range(h):
            for x in range(w):
                if m_pix[x, y] > 35:
                    a = m_pix[x, y] / 255.0
                    # Tono tallado luminoso noble
                    r = int(pix[x, y][0] * (1.0 - a) + color_pigmento_base[0] * a)
                    g = int(pix[x, y][1] * (1.0 - a) + color_pigmento_base[1] * a)
                    b = int(pix[x, y][2] * (1.0 - a) + color_pigmento_base[2] * a)
                    pix[x, y] = (r, g, b, 255)
                elif bl_pix[x, y] > 35:
                    a = bl_pix[x, y] / 255.0
                    r = min(255, int(pix[x, y][0] * (1.0 - a) + color_pigmento_luz[0] * a))
                    g = min(255, int(pix[x, y][1] * (1.0 - a) + color_pigmento_luz[1] * a))
                    b = min(255, int(pix[x, y][2] * (1.0 - a) + color_pigmento_luz[2] * a))
                    pix[x, y] = (r, g, b, 255)
                elif bs_pix[x, y] > 30:
                    a = bs_pix[x, y] / 255.0
                    r = max(0, int(pix[x, y][0] * (1.0 - a * 0.85)))
                    g = max(0, int(pix[x, y][1] * (1.0 - a * 0.85)))
                    b = max(0, int(pix[x, y][2] * (1.0 - a * 0.85)))
                    pix[x, y] = (r, g, b, 255)
                    
    img_exhume.save(ruta_exhume, "PNG")
    print(f"Generado logo_sign_exhume refinado: {ruta_exhume}")

if __name__ == "__main__":
    dir_boards = "assets/ui/panels/main_menu/hanging_menu/boards"
    dir_chains = "assets/ui/panels/main_menu/hanging_menu/chains"
    dir_logo = "assets/ui/panels/main_menu/hanging_menu/logo_sign"
    dir_backup = "assets/ui/panels/main_menu/hanging_menu/_backup_wood"
    
    generar_menu_board_pulido(os.path.join(dir_boards, "menu_board.png"))
    generar_cadenas_verticales_pulidas(os.path.join(dir_chains, "chain_vertical.png"))
    generar_logo_sign_pulido(
        os.path.join(dir_logo, "logo_sign_empty.png"),
        os.path.join(dir_logo, "logo_sign_exhume.png"),
        os.path.join(dir_backup, "logo_mask.png")
    )
    print("¡Assets pétreos refinados generados con éxito!")
