extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var pacifica := OS.get_cmdline_user_args().has("pacifica")
	EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false})
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
	if not pacifica:
		controlador.peeble.vida_actual = 0
		controlador.rengo.vida_actual = 0
	controlador.roffa.velocidad_paso = 0.001
	var jugador: Ficha = escenario.ficha_jugador
	jugador.velocidad_paso = 0.001
	var puerta: PuertaInteractuable = controlador.puerta
	var posicion_roffa: Vector2i = controlador.roffa.coordenada_mapa
	var posicion_jugador := jugador.global_position
	puerta.bloqueada = false
	var contexto := ContextoAccion.new(TiposInteraccion.TipoAccion.INTERACTUAR, jugador, jugador.coordenada_mapa, puerta.coordenada_mapa, puerta, null, &"abrir")
	assert(escenario.gestor_acciones.procesar_accion(contexto).exitosa)
	assert(controlador.en_curso and escenario.interaccion_modal_activa)
	var globo: Node = null
	for intento in 4000:
		await process_frame
		globo = escenario.get_node_or_null("ExampleBalloon")
		if globo != null:
			break
	assert(globo != null)
	assert(not escenario.en_combate)
	assert(controlador.roffa.coordenada_mapa == posicion_roffa and jugador.global_position == posicion_jugador)
	assert(globo.dialogue_line.character == "Roffa")
	escenario.camera_2d.libre = true
	escenario.camera_2d.global_position += Vector2(500, 300)
	escenario._actualizar_camara(0.016)
	assert(not escenario.camera_2d.libre)
	assert(escenario.camera_2d.global_position.is_equal_approx(escenario.camera_2d.limitar_posicion(jugador.global_position, escenario.get_viewport_rect().size)))
	globo.queue_free()
	await process_frame
	await process_frame
	globo = null
	var camara_se_movio := false
	for intento in 4000:
		await process_frame
		escenario._actualizar_camara(0.016)
		assert(escenario.camera_2d.global_position.is_equal_approx(escenario.camera_2d.limitar_posicion(jugador.global_position, escenario.get_viewport_rect().size)))
		if not jugador.global_position.is_equal_approx(posicion_jugador):
			camara_se_movio = true
		globo = escenario.get_node_or_null("ExampleBalloon")
		if globo != null:
			break
	assert(globo != null and camara_se_movio)
	assert(not escenario.en_combate)
	globo.queue_free()
	if pacifica:
		for intento in 100:
			await process_frame
			if current_scene != null and current_scene != escenario:
				break
		assert(current_scene != null and current_scene != escenario and current_scene.scene_file_path.ends_with("fin_demo.tscn"))
		print("MediacionRoffa: puerta, desplazamiento, diálogo y final correctos.")
		quit()
		return
	for intento in 100:
		await process_frame
		if escenario.en_combate:
			break
	assert(escenario.en_combate)
	assert(controlador.roffa.en_oposicion_encuentro)
	assert(EstadoPartida.trigger_consumido(&"res://scenes/Prision/prision.tscn", &"roffa_venganza"))
	controlador.roffa.vida_actual = 0
	escenario._resolver_fin_combate()
	for intento in 100:
		await process_frame
		if current_scene != null and current_scene != escenario:
			break
	assert(current_scene != null and current_scene != escenario and current_scene.scene_file_path.ends_with("fin_demo.tscn"))
	print("VenganzaRoffa: puerta, desplazamiento, diálogo, combate y final correctos.")
	quit()
