@tool
class_name ItemSueloZona
extends Marker2D

@export var id_instancia: StringName = &""
@export var definicion: DefinicionItem
@export_range(1, 999, 1) var cantidad: int = 1

var _definicion_previsualizada: DefinicionItem
var _previsualizacion: Node2D


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	_actualizar_previsualizacion()


func _actualizar_previsualizacion() -> void:
	if definicion == _definicion_previsualizada:
		return
	if is_instance_valid(_previsualizacion):
		_previsualizacion.free()
	_previsualizacion = null
	_definicion_previsualizada = definicion
	if definicion == null or definicion.escena_mundo == null:
		return
	_previsualizacion = definicion.escena_mundo.instantiate() as Node2D
	if _previsualizacion == null:
		return
	_previsualizacion.name = "PrevisualizacionEditor"
	add_child(_previsualizacion)


func obtener_coordenada(capa: TileMapLayer) -> Vector2i:
	return capa.local_to_map(capa.to_local(global_position))


func obtener_desplazamiento_visual(capa: TileMapLayer) -> Vector2:
	var posicion_local := capa.to_local(global_position)
	return posicion_local - capa.map_to_local(capa.local_to_map(posicion_local))
