extends Node
class_name FOVManager

var capa_oscuridad: TileMapLayer
var datos_tablero: Dictionary
var celdas_visibles_actuales: Array[Vector2i] = []

const FUENTES_FOG_EXPLORADO := {
	&"terreno": 0,
	&"pared": 2,
	&"columna": 4,
	&"estalagmita": 6,
	&"luz": 8,
}

const FUENTES_FOG_OCULTO := {
	&"terreno": 1,
	&"pared": 3,
	&"columna": 5,
	&"estalagmita": 7,
	&"luz": 9,
}

func inicializar(_capa: TileMapLayer, _datos: Dictionary) -> void:
	capa_oscuridad = _capa
	datos_tablero = _datos
	
	# 1. Al iniciar, cubrimos todo el mapa conocido de negro total
	for coord in datos_tablero.keys():
		_oscurecer_celda(coord, Celda.EstadoVisibilidad.OCULTO)
		datos_tablero[coord].visibilidad = Celda.EstadoVisibilidad.OCULTO

func actualizar_vision(centro_jugador: Vector2i, radio_jugador: int) -> void:
	# 1. Sombreamos (al 60%) todo lo que estuvo visible en el paso anterior
	for coord in celdas_visibles_actuales:
		_oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)
		if datos_tablero.has(coord):
			datos_tablero[coord].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
			
	celdas_visibles_actuales.clear()

	# 2. Proyectamos primero todas las antorchas/fogatas encendidas del mapa
	_procesar_luces_mapa()

	# 3. Proyectamos la luz del jugador (le agregamos 1 casilla de penumbra para suavizar los bordes)
	proyectar_luz_fuente(centro_jugador, radio_jugador, 1, false)

func _procesar_luces_mapa() -> void:
	for coord in datos_tablero.keys():
		var lista_luces: Array[Dictionary] = datos_tablero[coord].iluminacion
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
	return GeometriaGrid.trazar_linea(p0, p1)

# --- PROYECTOR DE LUZ GENÉRICO ---

func proyectar_luz_fuente(centro: Vector2i, radio_luz: int, radio_penumbra: int, atraviesa_muros: bool = false) -> void:
	var radio_total = radio_luz + radio_penumbra
	var celdas_area = _obtener_area_circulo(centro, radio_total)

	for destino in celdas_area:
		var linea = _trazar_linea_bresenham(centro, destino)
		
		for coord in linea:
			# Si choca con pared y la luz no atraviesa muros, iluminamos la pared y cortamos el rayo
			if not atraviesa_muros and datos_tablero.has(coord) and datos_tablero[coord].bloquea_vision:
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
		if datos_tablero.has(coord) and datos_tablero[coord].visibilidad != Celda.EstadoVisibilidad.VISIBLE:
			_oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)
			datos_tablero[coord].visibilidad = Celda.EstadoVisibilidad.EXPLORADO

func _revelar_celda(coord: Vector2i) -> void:
	capa_oscuridad.erase_cell(coord)
	if not coord in celdas_visibles_actuales:
		celdas_visibles_actuales.append(coord)
	if datos_tablero.has(coord):
		datos_tablero[coord].visibilidad = Celda.EstadoVisibilidad.VISIBLE

func _oscurecer_celda(coord: Vector2i, estado: int) -> void:
	if not datos_tablero.has(coord):
		return
		
	var celda: Celda = datos_tablero[coord]
	var fuentes: Dictionary = FUENTES_FOG_OCULTO
	if estado == Celda.EstadoVisibilidad.EXPLORADO:
		fuentes = FUENTES_FOG_EXPLORADO

	var source_id: int = fuentes.get(celda.familia_fog, fuentes[&"terreno"])
	capa_oscuridad.set_cell(coord, source_id, celda.coordenada_fog)
