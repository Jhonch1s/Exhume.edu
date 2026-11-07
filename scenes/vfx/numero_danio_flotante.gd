class_name NumeroDanioFlotante
extends Node2D

@onready var etiqueta: Label = $Etiqueta

var cantidad_danio: int = 0


func _ready() -> void:
	if etiqueta != null:
		etiqueta.text = str(cantidad_danio)
	_iniciar_animacion()


func _iniciar_animacion() -> void:
	position.x += randf_range(-6.0, 6.0)
	scale = Vector2(0.65, 0.65)
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y - 36.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)


static func instanciar_en(padre: Node, posicion_global: Vector2, cantidad: int) -> NumeroDanioFlotante:
	if padre == null or not is_instance_valid(padre) or cantidad <= 0:
		return null
	var escena := load("res://scenes/vfx/numero_danio_flotante.tscn") as PackedScene
	if escena == null:
		return null
	var efecto := escena.instantiate() as NumeroDanioFlotante
	efecto.cantidad_danio = cantidad
	efecto.global_position = posicion_global
	padre.add_child(efecto)
	return efecto
