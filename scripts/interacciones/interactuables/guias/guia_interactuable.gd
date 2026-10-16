@tool
class_name GuiaInteractuable
extends "res://scripts/interacciones/interactuables/interactuable.gd"

@export var permite_caminar: bool = true
@export var bloquea_vision: bool = false
@export var bloquea_proyectiles: bool = false


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_actualizar_visual()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and ajustar_a_celda_en_editor:
		_ajustar_al_centro_celda()


func permite_caminar_interactuable() -> bool:
	return permite_caminar


func bloquea_vision_interactuable() -> bool:
	return bloquea_vision


func bloquea_proyectiles_interactuable() -> bool:
	return bloquea_proyectiles


func _actualizar_visual() -> void:
	pass
