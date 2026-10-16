@tool
class_name LibroInteractuable
extends "res://scripts/interacciones/interactuables/guias/guia_interactuable.gd"

enum Variante {
	CERRADO_1,
	CERRADO_2,
	ABIERTO_1,
	ABIERTO_2,
}

@export var variante: Variante = Variante.CERRADO_1:
	set(valor):
		variante = valor
		_actualizar_visual()


func _actualizar_visual() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	sprite.region_enabled = true
	match variante:
		Variante.CERRADO_1:
			sprite.region_rect = Rect2(0, 0, 64, 32)
		Variante.CERRADO_2:
			sprite.region_rect = Rect2(0, 32, 64, 32)
		Variante.ABIERTO_1:
			sprite.region_rect = Rect2(64, 0, 64, 32)
		Variante.ABIERTO_2:
			sprite.region_rect = Rect2(64, 32, 64, 32)
