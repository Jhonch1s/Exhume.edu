extends Control

const ESCALA := 0.12
const FUENTE := preload("res://assets/ui/fonts/Amarante-Regular.ttf")
const COLOR_FONDO := Color(0.045, 0.039, 0.034, 0.96)
const COLOR_BORDE := Color(0.45, 0.36, 0.25, 1.0)

@onready var escenario: Node = get_parent().get_parent()
var _revision := -1
var _coord_anterior := Vector2i(2147483647, 2147483647)
var _zona_anterior: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var zona: Node2D = escenario.zona_actual
	visible = is_instance_valid(zona) and zona.get_node_or_null("CapaSuelo") is TileMapLayer
	if not visible or not is_instance_valid(escenario.ficha_jugador):
		return
	var vision: FOVManager = escenario.gestor_vision
	var coord: Vector2i = escenario.ficha_jugador.coordenada_mapa
	if _zona_anterior != zona or _revision != vision.revision_vision or coord != _coord_anterior:
		_zona_anterior = zona
		_revision = vision.revision_vision
		_coord_anterior = coord
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(3, 4), size), Color(0.0, 0.0, 0.0, 0.45))
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_FONDO)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BORDE, false, 2.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(0.24, 0.20, 0.15), false, 1.0)
	draw_rect(Rect2(7, 7, size.x - 14, 27), Color(0.13, 0.11, 0.085, 0.95))
	draw_line(Vector2(8, 35), Vector2(size.x - 8, 35), COLOR_BORDE, 1.0)
	var titulo := String(escenario.zona_actual.nombre_zona).to_upper()
	if titulo.is_empty():
		var archivo: String = escenario.zona_actual.scene_file_path.get_file().get_basename().to_lower()
		if archivo == "templodelastrampas":
			titulo = "TEMPLO DE LAS TRAMPAS"
		elif archivo == "descansocuevas":
			titulo = "DESCANSO EN LAS CUEVAS"
		else:
			titulo = archivo.replace("_", " ").to_upper() if not archivo.is_empty() else "MAPA"
	draw_string(FUENTE, Vector2(17, 26), titulo, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56, 16, Color(0.85, 0.76, 0.59))
	var ornamento := Vector2(size.x - 20, 21)
	draw_colored_polygon(PackedVector2Array([ornamento + Vector2(0, -5), ornamento + Vector2(4, 0), ornamento + Vector2(0, 5), ornamento + Vector2(-4, 0)]), COLOR_BORDE)
	if not is_instance_valid(escenario.ficha_jugador):
		return
	var suelo := escenario.zona_actual.get_node_or_null("CapaSuelo") as TileMapLayer
	if suelo == null:
		return
	var centro := Vector2(size.x * 0.5, 36.0 + (size.y - 54.0) * 0.5)
	var origen := suelo.map_to_local(escenario.ficha_jugador.coordenada_mapa)
	var vision: FOVManager = escenario.gestor_vision
	for coord: Vector2i in vision.datos_tablero:
		var celda: Celda = vision.datos_tablero[coord]
		if celda.visibilidad == Celda.EstadoVisibilidad.OCULTO:
			continue
		var punto := centro + (suelo.map_to_local(coord) - origen) * ESCALA
		if punto.x < 16 or punto.x > size.x - 16 or punto.y < 45 or punto.y > size.y - 19:
			continue
		var color := Color(0.70, 0.64, 0.53) if celda.caminable else Color(0.43, 0.36, 0.29)
		if celda.visibilidad == Celda.EstadoVisibilidad.EXPLORADO:
			color *= Color(0.53, 0.53, 0.53, 1.0)
		var mitad := Vector2(3.8, 1.9)
		draw_colored_polygon(PackedVector2Array([
			punto + Vector2(0, -mitad.y), punto + Vector2(mitad.x, 0),
			punto + Vector2(0, mitad.y), punto + Vector2(-mitad.x, 0),
		]), color)
	draw_circle(centro, 5.0, Color(0.12, 0.08, 0.04))
	draw_circle(centro, 3.0, Color(1.0, 0.77, 0.35))
	draw_circle(centro, 1.0, Color(1.0, 0.96, 0.79))
