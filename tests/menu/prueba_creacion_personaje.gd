extends SceneTree


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var menu := (load("res://scenes/menu/nueva_partida.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame

	var generador := RandomNumberGenerator.new()
	generador.seed = _semilla_repeticion_manual()
	menu.motor_dados = MotorDados.new(generador)
	var boton: Button = menu.botones_tirada[&"fuerza"]
	await menu.call(&"_tirar_atributo", &"fuerza")
	assert(not menu.atributos.has(&"fuerza") and not boton.disabled)
	await menu.call(&"_tirar_atributo", &"fuerza")
	assert(menu.atributos[&"fuerza"] in range(2, 6) and boton.disabled)

	menu.atributos = {&"fuerza": 3, &"destreza": 4, &"voluntad": 2}
	menu.clase = "Ladrón"
	menu.origen = "Cripta Apócrifa"
	menu.nombre.text = "Ada"
	menu.titulo_aventurero.text = ""
	menu.call(&"_actualizar_comenzar")
	assert(menu.comenzar.disabled)
	assert(EstadoPartida.validar_aventurero({
		"nombre": "Ada",
		"titulo": "",
		"fuerza": 3,
		"destreza": 4,
		"voluntad": 2,
		"clase": "Ladrón",
		"origen": "Cripta Apócrifa",
	}) == &"identidad_aventurero_invalida")
	menu.titulo_aventurero.text = "la Audaz"
	menu.call(&"_actualizar_comenzar")
	assert(not menu.comenzar.disabled)

	var datos_emitidos: Array[Dictionary] = []
	menu.excursion_solicitada.connect(func(datos: Dictionary): datos_emitidos.append(datos))
	await menu.call(&"_solicitar_excursion")
	assert(menu.has_node("CinematicaProvisional"))
	assert(datos_emitidos.size() == 1 and datos_emitidos[0]["titulo"] == "la Audaz")
	print("CreacionPersonaje: prueba correcta.")
	quit()


func _semilla_repeticion_manual() -> int:
	for semilla in 1000:
		var generador := RandomNumberGenerator.new()
		generador.seed = semilla
		var primero := generador.randi_range(1, 6)
		var segundo := generador.randi_range(1, 6)
		if primero in [1, 6] and segundo in range(2, 6):
			return semilla
	assert(false, "No se encontró una semilla útil.")
	return 0
