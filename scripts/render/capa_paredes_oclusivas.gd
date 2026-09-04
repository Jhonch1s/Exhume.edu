class_name CapaParedesOclusivas
extends TileMapLayer

const SHADER_OCLUSION := preload("res://assets/shaders/occlusion_jugador.gdshader")
const ALCANCE_SPRITE := Vector2(48.0, 112.0)
const MARGEN_CONO := 16.0

@export var radio_occlusion := Vector2(64.0, 52.0)
@export var desplazamiento_centro := Vector2(0.0, -32.0)
var _material_recorte := ShaderMaterial.new()
var _celdas_con_recorte: Dictionary[Vector2i, bool] = {}
var _celdas_a_actualizar: Dictionary[Vector2i, bool] = {}


func _init() -> void:
	_material_recorte.shader = SHADER_OCLUSION
	_material_recorte.set_shader_parameter(&"radio", radio_occlusion)


func actualizar_occlusion(posicion_jugador: Vector2) -> void:
	var centro_recorte := posicion_jugador + desplazamiento_centro
	_material_recorte.set_shader_parameter(&"posicion_jugador", centro_recorte)
	_material_recorte.set_shader_parameter(&"radio", radio_occlusion)
	var nuevas: Dictionary[Vector2i, bool] = {}
	for coordenada in get_used_cells():
		var datos_tile := get_cell_tile_data(coordenada)
		var origen_y := datos_tile.y_sort_origin if datos_tile != null else 0
		var ancla := to_global(map_to_local(coordenada) + Vector2(0.0, origen_y))
		var distancia_frontal := ancla - posicion_jugador
		if (
			distancia_frontal.y > 0.0
			and absf(distancia_frontal.x) <= distancia_frontal.y * 2.0 + MARGEN_CONO
			and absf(ancla.x - centro_recorte.x) <= radio_occlusion.x + ALCANCE_SPRITE.x
			and absf(ancla.y - centro_recorte.y) <= radio_occlusion.y + ALCANCE_SPRITE.y
		):
			nuevas[coordenada] = true
	if nuevas == _celdas_con_recorte:
		return
	_celdas_a_actualizar = _celdas_con_recorte.duplicate()
	for coordenada in nuevas:
		_celdas_a_actualizar[coordenada] = true
	_celdas_con_recorte = nuevas
	notify_runtime_tile_data_update()


func _use_tile_data_runtime_update(coordenada: Vector2i) -> bool:
	return _celdas_a_actualizar.has(coordenada)


func _tile_data_runtime_update(coordenada: Vector2i, datos_tile: TileData) -> void:
	datos_tile.material = _material_recorte if _celdas_con_recorte.has(coordenada) else null
