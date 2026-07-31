extends Node
class_name FOVManager

var capa_oscuridad: TileMapLayer
var datos_tablero: Dictionary
var celdas_visibles_actuales: Array[Vector2i] = []

const ATLAS_OSCURIDAD = 0 
const TILE_SOMBRA_PLANO = Vector2i(0, 1) # tile al 60% de opacidad
const TILE_NEGRO_PLANO = Vector2i(0, 0) # tile negro total
const TILE_SOMBRA_ALTO = Vector2i(2, 0) 
const TILE_NEGRO_ALTO = Vector2i(1, 0)

func inicializar(_capa: TileMapLayer, _datos: Dictionary) -> void:
	capa_oscuridad = _capa
	datos_tablero = _datos
	
	# Al iniciar, cubrimos todo el mapa conocido de negro total
	for coord in datos_tablero.keys():
		_oscurecer_celda(coord, "OCULTO") # <-- Cambio aquí
		datos_tablero[coord]["visibilidad"] = "OCULTO"


func actualizar_vision(centro: Vector2i, radio: int) -> void:
	# 1 sombra lo que antes era visible
	for coord in celdas_visibles_actuales:
		_oscurecer_celda(coord, "EXPLORADO") # <-- Cambio aquí
		if datos_tablero.has(coord):
			datos_tablero[coord]["visibilidad"] = "EXPLORADO"
			
	celdas_visibles_actuales.clear()

	# 2. obtenemos TODAS las celdas dentro del círculo
	var celdas_area = _obtener_area_circulo(centro, radio)

	# 3 dibujamos un rayo a cada celda posible
	for destino in celdas_area:
		var linea = _trazar_linea_bresenham(centro, destino)
		
		# Recorremos el rayo paso a paso
		for coord in linea:
			# Si chocamos con una pared
			if datos_tablero.has(coord) and datos_tablero[coord].get("zona", "") == "pared":
				# Revelamos la pared para que el jugador vea qué bloquea la luz
				_revelar_celda(coord)
				break # ¡Rompemos el ciclo! La luz no pasa de esta pared
			
			# Si es suelo despejado, lo revelamos y el rayo sigue
			_revelar_celda(coord)


# matematiks sacadas de online madafakindiablo2

func _obtener_area_circulo(centro: Vector2i, radio: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for x in range(-radio, radio + 1):
		for y in range(-radio, radio + 1):
			# +0.5 ayuda a redondear los bordes isométricos para que no se vea tan cuadrado
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
	
func _revelar_celda(coord: Vector2i) -> void:
	capa_oscuridad.erase_cell(coord)
	if not coord in celdas_visibles_actuales:
		celdas_visibles_actuales.append(coord)
	if datos_tablero.has(coord):
		datos_tablero[coord]["visibilidad"] = "VISIBLE"

func _oscurecer_celda(coord: Vector2i, tipo_estado: String) -> void:
	var es_pared = false
	if datos_tablero.has(coord) and datos_tablero[coord].get("zona", "") == "pared":
		es_pared = true
		
	var tile_a_dibujar: Vector2i
	
	if tipo_estado == "OCULTO":
		tile_a_dibujar = TILE_NEGRO_ALTO if es_pared else TILE_NEGRO_PLANO
	elif tipo_estado == "EXPLORADO":
		tile_a_dibujar = TILE_SOMBRA_ALTO if es_pared else TILE_SOMBRA_PLANO
		
	capa_oscuridad.set_cell(coord, ATLAS_OSCURIDAD, tile_a_dibujar)
