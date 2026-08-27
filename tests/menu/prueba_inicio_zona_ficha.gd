extends SceneTree


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var datos := {
		"nombre": "Ada",
		"titulo": "la Audaz",
		"fuerza": 2,
		"destreza": 4,
		"voluntad": 3,
		"pv_maximos": 9,
		"clase": "Ladrón",
		"origen": "Cripta Apócrifa",
	}
	assert(EstadoPartida.establecer_aventurero(datos))
	var ficha := load("res://scenes/ficha/ficha.tscn").instantiate() as Ficha
	assert(ficha.configurar_creacion(EstadoPartida.consumir_aventurero()))
	root.add_child(ficha)
	await process_frame
	assert(ficha.nombre == "Ada" and ficha.titulo == "la Audaz")
	assert(ficha.fue == 2 and ficha.des == 4 and ficha.vol == 3 and ficha.pv_max == 9)
	assert(ficha.clase == "Ladrón" and ficha.origen == "Cripta Apócrifa")
	assert(ficha.get_node("Sprite2D").frame == 0)
	print("InicioZonaFicha: prueba correcta.")
	quit()
