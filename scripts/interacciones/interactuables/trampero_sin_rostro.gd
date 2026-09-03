@tool
class_name TramperoSinRostro
extends Interactuable


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and ajustar_a_celda_en_editor:
		_ajustar_al_centro_celda()


func permite_caminar_interactuable() -> bool:
	return false


func bloquea_vision_interactuable() -> bool:
	return false


func bloquea_proyectiles_interactuable() -> bool:
	return true
