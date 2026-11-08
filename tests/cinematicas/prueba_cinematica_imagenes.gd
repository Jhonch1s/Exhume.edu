extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load("res://scenes/cinematicas/cinematica_imagenes.tscn") as PackedScene
	var cinematica = escena.instantiate()
	_comprobar(cinematica.videos.size() == 9, "La introducción debe contener nueve videos.")
	for indice in range(cinematica.videos.size()):
		_comprobar(
			cinematica.videos[indice].resource_path.get_file().begins_with("%02d_" % (indice + 1)),
			"Los videos deben estar en orden narrativo."
		)
	_comprobar(cinematica.imagenes.size() == 9, "La introducción debe conservar las nueve imágenes de respaldo.")

	cinematica.duracion_maxima_video = 0.05
	cinematica.tiempo_fundido = 0.02
	var finales := [0]
	cinematica.terminada.connect(func(): finales[0] += 1)
	root.add_child(cinematica)
	var vistas: Array[VideoStream] = []
	var hubo_video_visible := false
	var limite := Time.get_ticks_msec() + 4000
	while finales[0] == 0 and Time.get_ticks_msec() < limite:
		var stream_actual: VideoStream = cinematica.reproductor.stream
		if stream_actual != null and (vistas.is_empty() or vistas.back() != stream_actual):
			vistas.append(stream_actual)
		hubo_video_visible = hubo_video_visible or cinematica.reproductor.modulate.a > 0.99
		await process_frame
	_comprobar(vistas == cinematica.videos, "Debe mostrar los nueve videos en orden.")
	_comprobar(hubo_video_visible, "Los fundidos deben llegar a mostrar el video.")
	_comprobar(finales[0] == 1, "Debe terminar automáticamente una sola vez.")
	_comprobar(is_zero_approx(cinematica.reproductor.modulate.a), "Debe terminar en negro.")
	cinematica.queue_free()
	await process_frame

	var saltada = escena.instantiate()
	saltada.terminada.connect(func(): finales[0] += 1)
	root.add_child(saltada)
	saltada.get_node("Saltar").pressed.emit()
	saltada.get_node("Saltar").pressed.emit()
	_comprobar(finales[0] == 2, "Saltar debe terminar la cinemática una sola vez.")
	_comprobar(not saltada.reproductor_musica.playing and not saltada.reproductor_narrador.playing, "Saltar debe detener la música y la narración.")
	saltada.queue_free()
	await process_frame

	var vacia = escena.instantiate()
	vacia.videos.clear()
	vacia.imagenes.clear()
	vacia.terminada.connect(func(): finales[0] += 1)
	root.add_child(vacia)
	await create_timer(1.2).timeout
	_comprobar(finales[0] == 3, "Una secuencia vacía debe terminar sin bloquearse.")
	vacia.queue_free()
	await process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("Cinemática de videos: orden, fundidos, final y secuencia vacía correctos.")
	quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
