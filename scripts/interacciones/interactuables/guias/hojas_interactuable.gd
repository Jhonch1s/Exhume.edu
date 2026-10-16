@tool
class_name HojasInteractuable
extends "res://scripts/interacciones/interactuables/guias/guia_interactuable.gd"

enum Variante {
	VARIANTE_1,
	VARIANTE_2,
}

@export var variante: Variante = Variante.VARIANTE_1:
	set(valor):
		variante = valor
		_actualizar_visual()


func _actualizar_visual() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	sprite.region_enabled = true
	match variante:
		Variante.VARIANTE_1:
			sprite.region_rect = Rect2(0, 64, 64, 32)
		Variante.VARIANTE_2:
			sprite.region_rect = Rect2(64, 64, 64, 32)
