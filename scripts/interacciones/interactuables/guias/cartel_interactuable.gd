@tool
class_name CartelInteractuable
extends "res://scripts/interacciones/interactuables/guias/guia_interactuable.gd"

enum Orientacion {
	PARED_IZQUIERDA,
	PARED_DERECHA,
}

@export var orientacion: Orientacion = Orientacion.PARED_IZQUIERDA:
	set(valor):
		orientacion = valor
		_actualizar_visual()


func _actualizar_visual() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	sprite.region_enabled = true
	match orientacion:
		Orientacion.PARED_IZQUIERDA:
			sprite.region_rect = Rect2(66, 31, 26, 31)
		Orientacion.PARED_DERECHA:
			sprite.region_rect = Rect2(100, 31, 23, 31)
