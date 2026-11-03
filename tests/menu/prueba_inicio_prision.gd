extends SceneTree

const RUTA_PRISION := "res://scenes/Prision/prision.tscn"
const RUTA_TEMPLO := "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"
const RUTA_GUARDADO_PRUEBA := "user://prueba_inicio_prision.json"

var fallos: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	# Nueva partida elimina el guardado anterior; no usar el archivo real del jugador.
	if FileAccess.file_exists("user://partida.json") or FileAccess.file_exists(RUTA_GUARDADO_PRUEBA):
		push_error("Ejecuta esta prueba con un directorio de usuario aislado.")
		quit(1)
		return

	var menu = load("res://scenes/menu/menu_principal.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.call(&"_on_excursion_solicitada", {
		"nombre": "Ada", "titulo": "la Audaz", "clase": "Ladrón",
		"origen": "Cripta Apócrifa", "fuerza": 3, "destreza": 4, "voluntad": 2,
	})

	var escenario: Node
	for intento in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/escenario_base/escenario_base.tscn":
			escenario = current_scene
			if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
				break
	_comprobar(escenario != null and escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador, "La nueva partida debe crear al aventurero.")
	if escenario != null and escenario.ficha_jugador != null:
		_comprobar(escenario.zona_actual.scene_file_path == RUTA_PRISION, "La nueva partida debe comenzar en Prisión.")
		_comprobar(escenario.presentacion_zona != null and escenario.presentacion_zona.etiqueta_titulo.text == "PRISIÓN", "La presentación debe mostrar el nombre de la zona.")
		_comprobar(escenario.ficha_jugador.nombre == "Ada" and escenario.ficha_jugador.clase == "Ladrón", "La creación debe conservar los datos del aventurero.")
		_comprobar(escenario.ficha_jugador.recursos_turno.obtener_maximo(RecursosTurnoActor.MOVIMIENTO) == escenario.ficha_jugador.movimiento_por_turno, "El movimiento inicial debe incluir las bonificaciones del equipo.")
		_comprobar(escenario.ficha_jugador.coordenada_mapa == Vector2i.ZERO, "El aventurero debe aparecer en el punto de entrada.")
		_comprobar(escenario.tablero.items_suelo_por_id.is_empty(), "Prisión no debe generar una piedra automática.")
		var guardado: StringName = escenario.guardar_partida(RUTA_GUARDADO_PRUEBA)
		_comprobar(guardado == &"", "Debe poder guardarse la partida en Prisión: %s" % guardado)
		if guardado == &"":
			escenario.ficha_jugador.nombre = "Otro nombre"
			var carga: StringName = escenario.cargar_partida(RUTA_GUARDADO_PRUEBA)
			_comprobar(carga == &"" and escenario.ficha_jugador.nombre == "Ada", "La carga debe restaurar al aventurero en Prisión.")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO_PRUEBA))
		var id_original := escenario.get_instance_id()
		escenario.call(&"_mostrar_pantalla_muerte")
		escenario.pantalla_muerte.reiniciar_solicitado.emit()
		var reiniciado: Node
		for intento in 300:
			await process_frame
			if current_scene != null and current_scene.get_instance_id() != id_original and current_scene.scene_file_path == "res://scenes/escenario_base/escenario_base.tscn":
				reiniciado = current_scene
				if reiniciado.ficha_jugador != null and reiniciado.hud.ficha == reiniciado.ficha_jugador:
					break
		_comprobar(reiniciado != null and reiniciado.ficha_jugador != null and reiniciado.hud.ficha == reiniciado.ficha_jugador, "Reiniciar debe volver a crear al aventurero.")
		if reiniciado != null and reiniciado.ficha_jugador != null:
			_comprobar(reiniciado.zona_actual.scene_file_path == RUTA_PRISION, "Reiniciar debe mantener la Prisión como zona.")
			_comprobar(reiniciado.tablero.items_suelo_por_id.is_empty(), "Reiniciar no debe generar una piedra automática.")
			await _probar_campamento(reiniciado)

	for ruta in ["res://scenes/Zona1/zona_1.tscn", RUTA_TEMPLO]:
		var otra_zona = await _crear_escenario(ruta)
		if otra_zona == null:
			continue
		_comprobar(otra_zona.tablero.obtener_item_suelo(&"zona1_piedra_prueba") == null, "La zona no debe generar una piedra automática: " + ruta)
		if ruta == RUTA_TEMPLO:
			_comprobar(otra_zona.tablero.obtener_item_suelo(&"templo_piedra_01") != null, "El templo conserva su primera piedra colocada.")
			_comprobar(otra_zona.tablero.obtener_item_suelo(&"templo_piedra_02") != null, "El templo conserva su segunda piedra colocada.")
		otra_zona.queue_free()
		await process_frame

	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("InicioPrision: %s" % ("prueba correcta" if fallos.is_empty() else "%d fallos" % fallos.size()))
	quit(0 if fallos.is_empty() else 1)


func _probar_campamento(escenario: Node) -> void:
	var motivo: StringName = escenario.entrar_campamento()
	_comprobar(motivo == &"", "Debe poder abrirse el campamento desde Prisión: %s" % motivo)
	if motivo != &"":
		return
	var descanso: Node
	for intento in 300:
		await process_frame
		if is_instance_valid(escenario.campamento):
			descanso = escenario.campamento.escenario_descanso
			if descanso != null and descanso.ficha_jugador != null and descanso.hud.ficha == descanso.ficha_jugador:
				break
	_comprobar(descanso != null and descanso.ficha_jugador != null and descanso.hud.ficha == descanso.ficha_jugador, "Debe iniciarse la zona de descanso.")
	if descanso != null and descanso.ficha_jugador != null:
		_comprobar(descanso.tablero.obtener_item_suelo(&"zona1_piedra_prueba") == null, "El campamento no debe generar una piedra automática.")
	_comprobar(escenario.salir_campamento() == &"", "Debe poder regresarse a Prisión desde el campamento.")
	await process_frame
	_comprobar(escenario.zona_actual.scene_file_path == RUTA_PRISION, "El regreso debe conservar la Prisión.")


func _crear_escenario(ruta: String) -> Node:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.get_node("Zona").free()
	var zona = load(ruta).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	for intento in 200:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			return escenario
	_comprobar(false, "No se pudo iniciar la zona: " + ruta)
	escenario.queue_free()
	return null


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)
