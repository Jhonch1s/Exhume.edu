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

@onready var contenedor_aspecto: AspectRatioContainer = $ContenedorAspecto
@onready var reproductor: VideoStreamPlayer = $ContenedorAspecto/Reproductor
@onready var imagen: TextureRect = $Imagen
@onready var filtro_crt: ColorRect = $FiltroCRT


func _ready() -> void:
	if filtro_crt != null:
		filtro_crt.visible = filtro_crt_activo

	if not videos.is_empty():
		await _reproducir_videos()
	elif not imagenes.is_empty():
		await _reproducir_imagenes()
	else:
		terminada.emit()


func _reproducir_videos() -> void:
	reproductor.modulate.a = 0.0
	for video in videos:
		if video == null:
			continue
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

	terminada.emit()


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
	terminada.emit()
