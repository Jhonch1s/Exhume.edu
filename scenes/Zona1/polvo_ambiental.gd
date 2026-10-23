extends Node2D

const MOTAS := preload("res://scenes/vfx/motas_polvo_antorcha.tscn")

var _vision: FOVManager
var _suelo: TileMapLayer
var _revision := -1
var _emisores: Dictionary[Vector2i, CPUParticles2D] = {}


func _ready() -> void:
	_suelo = get_parent().get_node(^"CapaSuelo") as TileMapLayer
	_vision = get_parent().get_parent().get_node_or_null(^"GestorVision") as FOVManager
	set_process(_vision != null)


func _process(_delta: float) -> void:
	if _vision.revision_vision == _revision:
		return
	_revision = _vision.revision_vision
	var necesarias: Dictionary[Vector2i, bool] = {}
	var visibles: Dictionary[Vector2i, bool] = {}
	for coord in _vision.celdas_visibles_actuales:
		visibles[coord] = true
	for coord in _vision.celdas_visibles_actuales:
		if posmod(coord.x * 17 + coord.y * 31, 5) != 0:
			continue
		var interior := true
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if not visibles.has(coord + Vector2i(dx, dy)):
					interior = false
		if not interior:
			continue
		var celda := _vision.datos_tablero.get(coord) as Celda
		var nivel := _vision.iluminacion_actual.get(coord, FOVManager.NivelLuz.OSCURIDAD) as int
		if celda == null or not celda.caminable or nivel == FOVManager.NivelLuz.OSCURIDAD:
			continue
		necesarias[coord] = true
		if _emisores.has(coord):
			_emisores[coord].modulate.a = 1.0 if nivel == FOVManager.NivelLuz.LUZ else 0.6
			continue
		var motas := MOTAS.instantiate() as CPUParticles2D
		motas.z_index = 0
		motas.amount = 8
		motas.position = _suelo.map_to_local(coord) + Vector2(0, -18)
		motas.modulate.a = 1.0 if nivel == FOVManager.NivelLuz.LUZ else 0.6
		add_child(motas)
		_emisores[coord] = motas
	for coord in _emisores.keys():
		if not necesarias.has(coord):
			_emisores[coord].queue_free()
			_emisores.erase(coord)
