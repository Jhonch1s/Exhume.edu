class_name PantallaDesmayo
extends CanvasLayer

signal desmayo_completado

const SONIDO_CAIDA: AudioStream = preload("res://assets/sonidos/tension/caida.wav")
const SONIDO_NARRADOR_OSCURIDAD: AudioStream = preload("res://assets/sonidos/narrador/la oscuridad te atrapa.mp3")

@onready var fondo_negro: ColorRect = $FondoNegro
@onready var contenedor_central: VBoxContainer = $FondoNegro/ContenedorCentral
@onready var etiqueta_titulo: Label = $FondoNegro/ContenedorCentral/Titulo
@onready var etiqueta_subtitulo: Label = $FondoNegro/ContenedorCentral/Subtitulo
@onready var reproductor_caida: AudioStreamPlayer = $AudioCaida
@onready var reproductor_narrador: AudioStreamPlayer = $AudioNarrador

var en_curso: bool = false


func _ready() -> void:
	visible = false
	if is_instance_valid(fondo_negro):
		fondo_negro.modulate.a = 0.0
	if is_instance_valid(contenedor_central):
		contenedor_central.modulate.a = 0.0


func iniciar_desmayo(duracion_total: float = 5.0) -> void:
	if en_curso:
		return
	en_curso = true
	visible = true
	if is_instance_valid(fondo_negro):
		fondo_negro.modulate.a = 0.0
	if is_instance_valid(contenedor_central):
		contenedor_central.modulate.a = 0.0

	# 1. Reproducir audios
	if is_instance_valid(reproductor_caida) and is_inside_tree():
		reproductor_caida.stream = SONIDO_CAIDA
		reproductor_caida.play()
	if is_instance_valid(reproductor_narrador) and is_inside_tree():
		reproductor_narrador.stream = SONIDO_NARRADOR_OSCURIDAD
		reproductor_narrador.play()

	# 2. Fundido a negro (0.7s) y aparición del texto (0.9s)
	if is_inside_tree():
		var tween_in := create_tween().set_parallel(true)
		if is_instance_valid(fondo_negro):
			tween_in.tween_property(fondo_negro, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if is_instance_valid(contenedor_central):
			tween_in.tween_property(contenedor_central, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween_in.finished

		# 3. Mantener en pantalla durante el desmayo
		var tiempo_espera := maxf(0.5, duracion_total - 1.5)
		await get_tree().create_timer(tiempo_espera).timeout

		# 4. Desvanecimiento y despertar (0.8s)
		var tween_out := create_tween().set_parallel(true)
		if is_instance_valid(fondo_negro):
			tween_out.tween_property(fondo_negro, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		if is_instance_valid(contenedor_central):
			tween_out.tween_property(contenedor_central, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await tween_out.finished

	visible = false
	en_curso = false
	desmayo_completado.emit()
