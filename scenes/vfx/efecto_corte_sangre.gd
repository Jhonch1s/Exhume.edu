class_name EfectoCorteSangre
extends Node2D

@onready var particulas_sangre: CPUParticles2D = $ParticulasSangre
@onready var linea_corte: Line2D = $LineaCorte

var _angulo_corte: float = 0.0


func _ready() -> void:
	# Orientar corte aleatoriamente o con leve inclinación diagonal
	rotation = _angulo_corte if _angulo_corte != 0.0 else randf_range(-PI / 4.0, PI / 4.0)
	if particulas_sangre != null:
		particulas_sangre.emitting = true
	
	if linea_corte != null:
		linea_corte.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(linea_corte, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var timer := get_tree().create_timer(0.65)
	timer.timeout.connect(queue_free)


static func instanciar_en(padre: Node, posicion_global: Vector2, angulo: float = 0.0) -> EfectoCorteSangre:
	if padre == null or not is_instance_valid(padre):
		return null
	var escena := load("res://scenes/vfx/efecto_corte_sangre.tscn") as PackedScene
	if escena == null:
		return null
	var efecto := escena.instantiate() as EfectoCorteSangre
	efecto._angulo_corte = angulo
	efecto.global_position = posicion_global
	padre.add_child(efecto)
	return efecto
