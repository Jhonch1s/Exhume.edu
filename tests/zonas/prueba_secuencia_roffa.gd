extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var catalogo = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	escenario.get_node("Zona").free()
	var zona = load("res://scenes/Prision/prision.tscn").instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	current_scene = escenario
	for intento in 300:
		await process_frame
		if escenario.escenario_preparado:
			break
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var controlador = escenario.get_node("SecuenciaRoffa")
	var puerta = controlador.puerta
	puerta.abierta = true
	puerta.bloqueada = false
	puerta.presencia_cambiada.emit()
	escenario.secuencia_prision_activa = true
	escenario._actualizar_estado_modal_interaccion()
	var jugador: Ficha = escenario.ficha_jugador
	jugador.velocidad_paso = 0.001
	var posicion_original := jugador.coordenada_mapa
	for direccion in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var candidata: Vector2i = puerta.coordenada_mapa + direccion
		if not escenario.tablero.puede_entrar(candidata, jugador):
			continue
		escenario.tablero.liberar_celda(jugador.coordenada_mapa, jugador)
		jugador.inicializar(candidata, escenario.tablero.capa_referencia)
		escenario.tablero.ocupar_celda(candidata, jugador)
		var ruta_desde_puerta: Array[Vector2i] = controlador._camino_a_salida(controlador.roffa)
		if ruta_desde_puerta.is_empty():
			ruta_desde_puerta = await controlador._despejar_camino()
		print("Roffa con jugador en ", candidata, ": ", ruta_desde_puerta.size(), " pasos")
		escenario.tablero.liberar_celda(jugador.coordenada_mapa, jugador)
		jugador.inicializar(posicion_original, escenario.tablero.capa_referencia)
		escenario.tablero.ocupar_celda(posicion_original, jugador)
		assert(not ruta_desde_puerta.is_empty())
	var junto_a_puerta: Vector2i = puerta.coordenada_mapa + Vector2i.UP
	if escenario.tablero.puede_entrar(junto_a_puerta, jugador):
		escenario.tablero.liberar_celda(jugador.coordenada_mapa, jugador)
		jugador.inicializar(junto_a_puerta, escenario.tablero.capa_referencia)
		escenario.tablero.ocupar_celda(junto_a_puerta, jugador)
	var camino: Array[Vector2i] = controlador._camino_a_salida(controlador.roffa)
	if camino.is_empty():
		camino = await controlador._despejar_camino()
	print("Ruta de Roffa: ", camino.size(), " pasos")
	assert(not camino.is_empty())
	controlador.roffa.velocidad_paso = 0.001
	assert(await controlador._acompanar(camino))
	assert(controlador.roffa.coordenada_mapa == camino.back())
	var delta: Vector2i = controlador.roffa.coordenada_mapa - escenario.ficha_jugador.coordenada_mapa
	assert(absi(delta.x) + absi(delta.y) == 1)
	var dialogo = load("res://dialogues/prision/roffa.dialogue")
	assert(dialogo.cues.has("encuentro_guardias"))
	assert(dialogo.cues.has("encuentro_guardias_muertos"))
	escenario.queue_free()
	await process_frame
	print("SecuenciaRoffa: ruta y diálogos disponibles.")
	quit()
