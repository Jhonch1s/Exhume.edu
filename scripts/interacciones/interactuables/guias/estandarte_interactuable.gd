@tool
class_name EstandarteInteractuable
extends "res://scripts/interacciones/interactuables/guias/guia_interactuable.gd"

enum Orientacion {
	IZQUIERDA,
	DERECHA,
}

@export var orientacion: Orientacion = Orientacion.IZQUIERDA:
	set(valor):
		orientacion = valor
		_actualizar_visual()


func _init() -> void:
	permite_caminar = false
	bloquea_proyectiles = true


func _actualizar_visual() -> void:
	var sprite := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if sprite == null:
		return
	sprite.region_enabled = true
	match orientacion:
		Orientacion.IZQUIERDA:
			sprite.region_rect = Rect2(128, 32, 64, 64)
		Orientacion.DERECHA:
			sprite.region_rect = Rect2(192, 32, 64, 64)
