extends Control

signal terminada

@export var videos: Array[VideoStream] = []
@export var imagenes: Array[Texture2D] = []
## Activa o desactiva el filtro CRT en la reproducción.
@export var filtro_crt_activo: bool = true:
	set(valor):
		filtro_crt_activo = valor
		if is_node_ready() and filtro_crt != null:
			filtro_crt.visible = valor
## Tiempo de fundido de entrada y salida a negro para cada video o imagen.
@export_range(0.01, 3.0, 0.01) var tiempo_fundido: float = 0.6
## Tiempo con cada imagen completamente visible (cuando se usan imágenes estáticas).
@export_range(0.1, 30.0, 0.1) var tiempo_por_imagen: float = 4.0
## Si es mayor que 0, limita la duración máxima de reproducción por video (útil para pruebas).
@export_range(0.0, 60.0, 0.01) var duracion_maxima_video: float = 0.0

const NARRADOR_01: AudioStream = preload("res://assets/sonidos/narrador/la tierra no olvida.mp3")
const NARRADOR_05: AudioStream = preload("res://assets/sonidos/narrador/el abismo los espera.mp3")
const NARRADOR_09: AudioStream = preload("res://assets/sonidos/narrador/ahora te toca a ti.mp3")
const MUSICA_ANCIENT_RUINS: AudioStream = preload("res://assets/sonidos/sonidos finales/musica buena/Ancient Ruins.ogg")

@onready var contenedor_aspecto: AspectRatioContainer = $ContenedorAspecto
@onready var reproductor: VideoStreamPlayer = $ContenedorAspecto/Reproductor
@onready var imagen: TextureRect = $Imagen
@onready var filtro_crt: ColorRect = $FiltroCRT

var reproductor_narrador: AudioStreamPlayer
var reproductor_musica: AudioStreamPlayer


func _ready() -> void:
	if filtro_crt != null:
		filtro_crt.visible = filtro_crt_activo

	_iniciar_musica_cinematica()

	if not videos.is_empty():
		await _reproducir_videos()
	elif not imagenes.is_empty():
		await _reproducir_imagenes()
	else:
		_finalizar_cinematica()


func _iniciar_musica_cinematica() -> void:
	if not is_instance_valid(reproductor_musica):
		reproductor_musica = AudioStreamPlayer.new()
		reproductor_musica.name = "MusicaAncientRuins"
		reproductor_musica.volume_db = -8.0
		add_child(reproductor_musica)
	var stream_musica: Variant = MUSICA_ANCIENT_RUINS
	if stream_musica != null and "loop" in stream_musica:
		stream_musica.loop = true
	reproductor_musica.stream = MUSICA_ANCIENT_RUINS
	if not reproductor_musica.finished.is_connected(_on_musica_cinematica_finished):
		reproductor_musica.finished.connect(_on_musica_cinematica_finished)
	reproductor_musica.play()


func _on_musica_cinematica_finished() -> void:
	if is_instance_valid(reproductor_musica) and reproductor_musica.is_inside_tree():
		reproductor_musica.play()


func _finalizar_cinematica() -> void:
	if is_instance_valid(reproductor_musica) and reproductor_musica.playing:
		var tween := create_tween()
		tween.tween_property(reproductor_musica, "volume_db", -40.0, 1.0)
		await tween.finished
		if is_instance_valid(reproductor_musica):
			reproductor_musica.stop()
	terminada.emit()


func _reproducir_videos() -> void:
	reproductor.modulate.a = 0.0
	for indice in range(videos.size()):
		var video: VideoStream = videos[indice]
		if video == null:
			continue
		_reproducir_audio_narrador_cinematica(indice)
		reproductor.stream = video
		reproductor.play()

		var secuencia_in := create_tween()
		secuencia_in.tween_property(reproductor, "modulate:a", 1.0, tiempo_fundido)
		await secuencia_in.finished
		if not is_inside_tree():
			return

		if duracion_maxima_video > 0.0:
			var timer := get_tree().create_timer(duracion_maxima_video)
			var terminado := false
			var on_fin := func(): terminado = true
			reproductor.finished.connect(on_fin, CONNECT_ONE_SHOT)
			await timer.timeout
			if not is_inside_tree():
				return
			if reproductor.finished.is_connected(on_fin):
				reproductor.finished.disconnect(on_fin)
		else:
			await reproductor.finished
			if not is_inside_tree():
				return

		var secuencia_out := create_tween()
		secuencia_out.tween_property(reproductor, "modulate:a", 0.0, tiempo_fundido)
		await secuencia_out.finished
		if not is_inside_tree():
			return
		reproductor.stop()

	await _finalizar_cinematica()


func _reproducir_imagenes() -> void:
	imagen.visible = true
	imagen.modulate.a = 0.0
	for textura in imagenes:
		if textura == null:
			continue
		imagen.texture = textura
		var secuencia := create_tween()
		secuencia.tween_property(imagen, "modulate:a", 1.0, tiempo_fundido)
		secuencia.tween_interval(tiempo_por_imagen)
		secuencia.tween_property(imagen, "modulate:a", 0.0, tiempo_fundido)
		await secuencia.finished
		if not is_inside_tree():
			return
	await _finalizar_cinematica()


func _reproducir_audio_narrador_cinematica(indice: int) -> void:
	var stream: AudioStream = null
	match indice:
		0: stream = NARRADOR_01
		4: stream = NARRADOR_05
		8: stream = NARRADOR_09
	if stream == null:
		return
	if not is_instance_valid(reproductor_narrador):
		reproductor_narrador = AudioStreamPlayer.new()
		reproductor_narrador.name = "NarradorCinematica"
		reproductor_narrador.volume_db = 3.0
		add_child(reproductor_narrador)
	reproductor_narrador.volume_db = 3.0
	reproductor_narrador.stream = stream
	reproductor_narrador.play()
