class_name NumeroDanioFlotante
extends Node2D

@onready var etiqueta: Label = $Etiqueta

var cantidad_danio: int = 0
var tipo_danio: StringName = &""

const COLORES := {
	&"quemado": Color(1.0, 0.55, 0.18),
	&"bola_fuego": Color(1.0, 0.55, 0.18),
	&"lava": Color(1.0, 0.55, 0.18),
	&"explosion": Color(1.0, 0.55, 0.18),
	&"veneno": Color(0.53, 0.9, 0.25),
}
const COLOR_GOLPE := Color(0.95, 0.15, 0.15)


func _ready() -> void:
	if etiqueta != null:
		etiqueta.text = str(cantidad_danio)
		etiqueta.add_theme_color_override("font_color", COLORES.get(tipo_danio, COLOR_GOLPE))
	_iniciar_animacion()


func _iniciar_animacion() -> void:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	position.x += azar.randf_range(-6.0, 6.0)
	scale = Vector2(0.5, 0.5)
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y - 36.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.6)
	var origen_x := position.x
	var vaiven := create_tween()
	vaiven.tween_property(self, "position:x", origen_x + azar.randf_range(-14.0, 14.0), 0.3).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(self, "position:x", origen_x + azar.randf_range(-14.0, 14.0), 0.35).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(self, "position:x", origen_x + azar.randf_range(-14.0, 14.0), 0.35).set_trans(Tween.TRANS_SINE)

	tween.chain().tween_callback(queue_free)


static func instanciar_en(padre: Node, posicion_global: Vector2, cantidad: int, tipo: StringName = &"") -> NumeroDanioFlotante:
	if padre == null or not is_instance_valid(padre) or cantidad <= 0:
		return null
	var escena := load("res://scenes/vfx/numero_danio_flotante.tscn") as PackedScene
	if escena == null:
		return null
	var efecto := escena.instantiate() as NumeroDanioFlotante
	efecto.cantidad_danio = cantidad
	efecto.tipo_danio = tipo
	efecto.global_position = posicion_global
	padre.add_child(efecto)
	return efecto
