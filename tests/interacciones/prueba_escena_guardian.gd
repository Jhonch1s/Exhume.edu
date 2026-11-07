extends SceneTree


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena: Node2D = load("res://tests/interacciones/escena_guardian.tscn").instantiate()
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
		push_error("La escena no pudo colocar el Guardián.")
		quit(1)
		return
	var guardian: PersonajeNPC = enemigos[0]
	var perfil := guardian.obtener_definicion_personaje()
	var original := load("res://recursos/personajes/guardian.tres") as DefinicionPersonaje
	var valido := perfil == original and perfil.puede_combatir and perfil.estilo_combate == DefinicionPersonaje.EstiloCombate.GUARDIAN
	valido = valido and escenario.tablero.obtener_interactuable(guardian.id_instancia) == guardian
	valido = valido and guardian.vida_actual == 20 and guardian.se_opone_al_jugador()
	valido = valido and guardian.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial)
	var opcion_ataque: OpcionAccion
	for opcion in guardian.obtener_opciones_accion(escenario.ficha_jugador):
		if opcion.id == &"ataque_basico":
			opcion_ataque = opcion
	for desplazamiento in [Vector2i.LEFT, Vector2i.UP, Vector2i(2, 1), Vector2i(1, 2)]:
		var fuera: Vector2i = guardian.coordenada_mapa + desplazamiento
		var borde := guardian.obtener_celda_mas_cercana(fuera)
		var contexto: Variant = escenario.constructor_contexto_accion.construir_desde_opcion(opcion_ataque, escenario.ficha_jugador, fuera, borde)
		valido = valido and contexto is ContextoAccion and escenario.gestor_acciones.esta_en_alcance(contexto) and guardian.validar_accion(contexto) == &""
	guardian.iniciar_turno()
	var decisor: DecisorCombateNPC = escenario._obtener_decisor_npc(guardian)
	var visibles: Array[Object] = [escenario.ficha_jugador]
	var plan: Dictionary = decisor.elegir(guardian, escenario.tablero, escenario.pathfinding, visibles, true)
	var delta: Vector2i = guardian.coordenada_mapa - escenario.ficha_jugador.coordenada_mapa
	valido = valido and plan["decision"] == (&"picotazo_guardian" if absi(delta.x) + absi(delta.y) == 1 else &"acercarse")
	var zona := escenario.get_node("Zona") as Node2D
	var errores := ValidadorContenidoZona.new().validar(zona, escenario.tablero, zona.get_node("CapaSuelo"))
	if not errores.is_empty():
		push_error("Contenido inválido: %s" % str(errores))
	valido = valido and errores.is_empty()
	valido = valido and escenario._iniciar_combate(guardian, false)
	if escenario.en_combate:
		if not escenario._es_turno_jugador():
			escenario._finalizar_turno_combate()
		valido = valido and escenario._es_turno_jugador()
		escenario.ficha_jugador.aplicar_o_renovar_estado(&"petrificado", 1, 1, 1)
		escenario.ejecutar_turnos = true
		escenario._programar_turno_npc()
		escenario._programar_turno_npc()
		await create_timer(0.05).timeout
		valido = valido and escenario.en_combate and escenario.gestor_rondas.actor_activo == guardian
		valido = valido and escenario.ficha_jugador.obtener_estado(&"petrificado") == null
		escenario.ejecutar_turnos = false
	print("EscenaGuardian: ", "correcta" if valido else "fallo")
	escena.queue_free()
	await process_frame
	quit(0 if valido else 1)

