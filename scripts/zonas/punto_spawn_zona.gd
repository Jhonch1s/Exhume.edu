@tool
class_name PuntoSpawnZona
extends Marker2D

@export var id_spawn: StringName = &"entrada"


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var capa := _obtener_capa_suelo()
	if capa == null:
		return
	var local_en_capa := capa.to_local(global_position)
	var centro := capa.to_global(capa.map_to_local(capa.local_to_map(local_en_capa)))
	if not global_position.is_equal_approx(centro):
		global_position = centro


func obtener_coordenada(capa: TileMapLayer) -> Vector2i:
	return capa.local_to_map(capa.to_local(global_position))


func _obtener_capa_suelo() -> TileMapLayer:
	var ancestro := get_parent()
	while ancestro != null:
		var capa := ancestro.get_node_or_null(^"CapaSuelo") as TileMapLayer
		if capa != null:
			return capa
		ancestro = ancestro.get_parent()
	return null
