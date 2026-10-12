class_name RepresentacionItemSuelo
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var resaltador: ResaltadorOutline2D
var variante_visual: int = -1


func _ready() -> void:
	if variante_visual < 0:
		variante_visual = randi_range(0, sprite.hframes * sprite.vframes - 1)
	sprite.frame = variante_visual


func establecer_resaltado(activo: bool) -> void:
	if resaltador == null:
		resaltador = ResaltadorOutline2D.new()
		add_child(resaltador)
		resaltador.configurar(sprite, Color.WHITE, 1.0)
	resaltador.establecer_activo(activo)


func contiene_punto_global(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(sprite)
		and sprite.is_visible_in_tree()
		and sprite.is_pixel_opaque(sprite.to_local(punto_global))
	)
