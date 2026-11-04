extends SceneTree


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena: Node2D = load("res://tests/interacciones/escena_terror_nocturno.tscn").instantiate()
	var escenario: Node2D = escena.get_node("Escenario")
	var catalogo: CatalogoMensajesInteraccion = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	root.add_child(escena)
	for _intento in 300:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 1:
			break
	var enemigos: Array = escena.get("_enemigos")
	if enemigos.size() != 1:
		push_error("La escena no pudo colocar el murciélago.")
		quit(1)
		return
	var murcielago: PersonajeNPC = enemigos[0]
	var perfil := murcielago.obtener_definicion_personaje()
	var original := load("res://recursos/personajes/terror_nocturno.tres") as DefinicionPersonaje
	var valido := perfil == original and perfil.puede_combatir and perfil.estilo_combate == DefinicionPersonaje.EstiloCombate.TERROR_NOCTURNO
	valido = valido and escenario.tablero.obtener_interactuable(murcielago.id_instancia) == murcielago
	valido = valido and murcielago.vida_actual == 10 and murcielago.se_opone_al_jugador()
	valido = valido and murcielago.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial)
	murcielago.iniciar_turno()
	# La casilla disponible puede estar fuera de las tres casillas del chillido.
	var decisor: DecisorCombateNPC = escenario._obtener_decisor_npc(murcielago)
	var visibles: Array[Object] = [escenario.ficha_jugador]
	var plan: Dictionary = decisor.elegir(murcielago, escenario.tablero, escenario.pathfinding, visibles, true)
	var delta: Vector2i = murcielago.coordenada_mapa - escenario.ficha_jugador.coordenada_mapa
	valido = valido and plan["decision"] == (&"chillido_terror" if maxi(absi(delta.x), absi(delta.y)) <= 3 else &"acercarse")
	var zona := escenario.get_node("Zona") as Node2D
	var errores := ValidadorContenidoZona.new().validar(zona, escenario.tablero, zona.get_node("CapaSuelo"))
	if not errores.is_empty():
		push_error("Contenido inválido: %s" % str(errores))
	valido = valido and errores.is_empty()
	valido = valido and escenario._iniciar_combate(murcielago, false)
	if escenario.en_combate:
		if not escenario._es_turno_jugador():
			escenario._finalizar_turno_combate()
		valido = valido and escenario._es_turno_jugador()
		escenario.ficha_jugador.aplicar_o_renovar_estado(&"aturdido", 1, 1, 1)
		escenario.ejecutar_turnos = true
		escenario._programar_turno_npc()
		escenario._programar_turno_npc()
		await create_timer(0.05).timeout
		valido = valido and escenario.en_combate and escenario.gestor_rondas.actor_activo == murcielago
		valido = valido and escenario.ficha_jugador.obtener_estado(&"aturdido") == null
		escenario.ejecutar_turnos = false
	print("EscenaTerrorNocturno: ", "correcta" if valido else "fallo")
	escena.queue_free()
	await process_frame
	quit(0 if valido else 1)
