extends Node
class_name FOVManager

var capa_oscuridad: TileMapLayer
var datos_tablero: Dictionary
var celdas_visibles_actuales: Array[Vector2i] = []

const ATLAS_OSCURIDAD = 0 
const TILE_SOMBRA_PLANO = Vector2i(0, 1) # tile al 60% de opacidad
const TILE_NEGRO_PLANO = Vector2i(0, 0)  # tile negro total
const TILE_NEGRO_MEDIO = Vector2i(0, 2) 
const TILE_SOMBRA_MEDIO = Vector2i(0, 4)
const TILE_SOMBRA_ALTO = Vector2i(2, 0) 
const TILE_NEGRO_ALTO = Vector2i(1, 0)

func inicializar(_capa: TileMapLayer, _datos: Dictionary) -> void:
	capa_oscuridad = _capa
	datos_tablero = _datos
	
	# 1. Al iniciar, cubrimos todo el mapa conocido de negro total
	for coord in datos_tablero.keys():
		_oscurecer_celda(coord, "OCULTO")
		datos_tablero[coord]["visibilidad"] = "OCULTO"

func actualizar_vision(centro_jugador: Vector2i, radio_jugador: int) -> void:
	# 1. Sombreamos (al 60%) todo lo que estuvo visible en el paso anterior
	for coord in celdas_visibles_actuales:
		_oscurecer_celda(coord, "EXPLORADO")
		if datos_tablero.has(coord):
			datos_tablero[coord]["visibilidad"] = "EXPLORADO"
			
	celdas_visibles_actuales.clear()

	# 2. Proyectamos primero todas las antorchas/fogatas encendidas del mapa
	_procesar_luces_mapa()

	# 3. Proyectamos la luz del jugador (le agregamos 1 casilla de penumbra para suavizar los bordes)
	proyectar_luz_fuente(centro_jugador, radio_jugador, 1, false)

func _procesar_luces_mapa() -> void:
	for coord in datos_tablero.keys():
		var lista_luces = datos_tablero[coord].get("iluminacion", [])
		for luz in lista_luces:
			if luz.get("encendida", false):
				var r_luz: int = luz.get("radio_luz", 2)
				var r_penumbra: int = luz.get("radio_penumbra", 1)
				var atraviesa: bool = luz.get("atraviesa_muros", false)
				
				proyectar_luz_fuente(coord, r_luz, r_penumbra, atraviesa)

# --- MATEMÁTICAS Y RAYCASTING ---

func _obtener_area_circulo(centro: Vector2i, radio: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for x in range(-radio, radio + 1):
		for y in range(-radio, radio + 1):
			if Vector2(x, y).length() <= radio + 0.5: 
				area.append(centro + Vector2i(x, y))
	return area

func _trazar_linea_bresenham(p0: Vector2i, p1: Vector2i) -> Array[Vector2i]:
	var puntos: Array[Vector2i] = []
	var dx = abs(p1.x - p0.x)
	var dy = -abs(p1.y - p0.y)
	var sx = 1 if p0.x < p1.x else -1
	var sy = 1 if p0.y < p1.y else -1
	var err = dx + dy
	var e2 = 0
	var actual = p0
	
	while true:
		puntos.append(actual)
		if actual == p1: break
		e2 = 2 * err
		if e2 >= dy:
			err += dy
			actual.x += sx
		if e2 <= dx:
			err += dx
			actual.y += sy
			
	return puntos

# --- PROYECTOR DE LUZ GENÉRICO ---

func proyectar_luz_fuente(centro: Vector2i, radio_luz: int, radio_penumbra: int, atraviesa_muros: bool = false) -> void:
	var radio_total = radio_luz + radio_penumbra
	var celdas_area = _obtener_area_circulo(centro, radio_total)

	for destino in celdas_area:
		var linea = _trazar_linea_bresenham(centro, destino)
		
		for coord in linea:
			# Si choca con pared y la luz no atraviesa muros, iluminamos la pared y cortamos el rayo
			if not atraviesa_muros and datos_tablero.has(coord) and datos_tablero[coord].get("zona", "") == "pared":
				_aplicar_nivel_luz(coord, centro, radio_luz)
				break
				
			_aplicar_nivel_luz(coord, centro, radio_luz)

func _aplicar_nivel_luz(coord: Vector2i, centro: Vector2i, radio_luz: int) -> void:
	var distancia = int(Vector2(coord - centro).length())
	
	if distancia <= radio_luz:
		# Luz central potente (Borra la sombra completamente)
		_revelar_celda(coord)
	else:
		# Halo de penumbra (Sombra al 60%)
		# Solo se aplica si la casilla no tiene ya luz potente (VISIBLE)
		if datos_tablero.has(coord) and datos_tablero[coord].get("visibilidad", "") != "VISIBLE":
			_oscurecer_celda(coord, "EXPLORADO")
			datos_tablero[coord]["visibilidad"] = "EXPLORADO"

func _revelar_celda(coord: Vector2i) -> void:
	capa_oscuridad.erase_cell(coord)
	if not coord in celdas_visibles_actuales:
		celdas_visibles_actuales.append(coord)
	if datos_tablero.has(coord):
		datos_tablero[coord]["visibilidad"] = "VISIBLE"

func _oscurecer_celda(coord: Vector2i, tipo_estado: String) -> void:
	if not datos_tablero.has(coord):
		return
		
	var zona_tipo: String = datos_tablero[coord].get("zona", "")
	var altura: int = datos_tablero[coord].get("altura", 0) # 0: Plano, 1: Medio, 2: Pared
	var tiene_luz: bool = datos_tablero[coord].get("iluminacion", []).size() > 0
	
	var tile_a_dibujar: Vector2i
	
	if tipo_estado == "OCULTO":
		# En OCULTO (100% negro) mantenemos las sombras altas/medias
		# para tapar completamente objetos, luces y muros no descubiertos.
		if altura == 2 or zona_tipo == "pared":
			tile_a_dibujar = TILE_NEGRO_ALTO
		elif altura == 1 or tiene_luz:
			tile_a_dibujar = TILE_NEGRO_MEDIO
		else:
			tile_a_dibujar = TILE_NEGRO_PLANO
			
	elif tipo_estado == "EXPLORADO":
		# En EXPLORADO (60% semitransparente) SOLO las paredes llevan sombra alta.
		# Las decoraciones de piso (altura 1), luces y suelo usan sombra PLANA (altura 0)
		# para no encimar sombras semitransparentes con la celda de atrás.
		if altura == 2 or zona_tipo == "pared":
			tile_a_dibujar = TILE_SOMBRA_ALTO
		else:
			tile_a_dibujar = TILE_SOMBRA_PLANO
		
	capa_oscuridad.set_cell(coord, ATLAS_OSCURIDAD, tile_a_dibujar)
