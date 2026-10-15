extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load("res://scenes/cinematicas/cinematica_imagenes.tscn") as PackedScene
	var cinematica = escena.instantiate()
	_comprobar(cinematica.imagenes.size() == 9, "La introducción debe contener nueve imágenes.")
	for indice in range(cinematica.imagenes.size()):
		_comprobar(
			cinematica.imagenes[indice].resource_path.get_file().begins_with("%02d_" % (indice + 1)),
			"Las imágenes deben estar en orden narrativo."
		)
	cinematica.tiempo_por_imagen = 0.08
	cinematica.tiempo_fundido = 0.04
	var finales := [0]
	cinematica.terminada.connect(func(): finales[0] += 1)
	root.add_child(cinematica)
	var vistas: Array[Texture2D] = []
	var hubo_imagen_visible := false
	var limite := Time.get_ticks_msec() + 3000
	while finales[0] == 0 and Time.get_ticks_msec() < limite:
		var textura: Texture2D = cinematica.imagen.texture
		if vistas.is_empty() or vistas.back() != textura:
			vistas.append(textura)
		hubo_imagen_visible = hubo_imagen_visible or cinematica.imagen.modulate.a > 0.99
		await process_frame
	_comprobar(vistas == cinematica.imagenes, "Debe mostrar las nueve imágenes en orden.")
	_comprobar(hubo_imagen_visible, "Los fundidos deben llegar a mostrar la imagen.")
	_comprobar(finales[0] == 1, "Debe terminar automáticamente una sola vez.")
	_comprobar(is_zero_approx(cinematica.imagen.modulate.a), "Debe terminar en negro.")
	cinematica.queue_free()
	await process_frame

	var vacia = escena.instantiate()
	vacia.imagenes.clear()
	vacia.terminada.connect(func(): finales[0] += 1)
	root.add_child(vacia)
	_comprobar(finales[0] == 2, "Una secuencia vacía debe terminar sin bloquearse.")
	vacia.queue_free()
	await process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("Cinemática: orden, fundidos, final y secuencia vacía correctos.")
	quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
