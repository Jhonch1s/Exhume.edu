extends SceneTree

var _fallos: Array[String] = []
var _casos := 0


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_memoria()
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var catalogo: CatalogoMensajesInteraccion = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	escenario.get_node("Zona").free()
	var zona = load("res://scenes/Prision/prision.tscn").instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	current_scene = escenario
	for intento in range(300):
		await process_frame
		if escenario.escenario_preparado:
			break
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var npc := escenario.tablero.obtener_interactuable(&"banga_roffa") as PersonajeNPC
	_comprobar(npc != null, "Roffa está registrado en la prisión.")
	if npc != null:
		await _probar_roffa(escenario, npc)
	escenario.queue_free()
	await process_frame
	for fallo in _fallos:
		push_error(fallo)
	print("RoffaPrisionero: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _probar_roffa(escenario: Node, npc: PersonajeNPC) -> void:
	var ficha: Ficha = escenario.ficha_jugador
	var perfil := npc.obtener_definicion_personaje()
	_comprobar(npc.obtener_actitud_hacia_jugador() == DefinicionPersonaje.ActitudInicialJugador.NEUTRAL and not npc.se_opone_al_jugador(), "Roffa comienza neutral.")
	_comprobar(not npc.puede_detectar_jugador(ficha, escenario.validador_espacial), "Roffa no abre combate al ver al jugador.")
	_comprobar(not npc.obtener_patrulla().esta_configurada(), "El preso no patrulla fuera de la celda.")
	var guardia := escenario.tablero.obtener_interactuable(&"banga_peeble") as PersonajeNPC
	_comprobar(guardia.se_opone_al_jugador() and not npc.comparte_faccion(guardia), "Roffa no se suma a los guardias por facción.")
	var opcion: OpcionAccion
	for candidata in npc.obtener_opciones_accion(ficha):
		if candidata.id == &"hablar:prision":
			opcion = candidata
		elif candidata.id in [&"ataque_basico", &"recoger_botin"]:
			_comprobar(npc.obtener_alcance_maximo_opcion(candidata) == 1.0, "El alcance de ataque y botín sigue siendo una casilla.")
	_comprobar(opcion != null and npc.obtener_alcance_maximo_opcion(opcion) == 4.0, "Hablar tiene alcance de cuatro casillas, superior al mínimo de tres.")
	_comprobar(DefinicionPersonaje.new().alcance_dialogo == 1, "Los demás NPC conservan el alcance predeterminado.")
	if opcion == null:
		return
	# Buscar un punto del pasillo alcanzable desde la entrada con la celda cerrada.
	var origen: Variant = null
	for candidata: Vector2i in escenario.tablero.datos:
		var delta := candidata - npc.coordenada_mapa
		if absi(delta.x) + absi(delta.y) != 4 or not escenario.tablero.puede_entrar(candidata, ficha):
			continue
		if escenario.validador_espacial.validar_linea_visual(candidata, npc.coordenada_mapa) != &"":
			continue
		var camino: Array[Vector2i] = escenario.pathfinding.calcular_camino(ficha.coordenada_mapa, candidata, escenario.tablero.datos, ficha)
		if not camino.is_empty():
			origen = candidata
			break
	_comprobar(origen != null, "Hay un punto visible a cuatro casillas, accesible desde la entrada sin abrir la celda.")
	print("RoffaPrisionero: celda=", npc.coordenada_mapa, " conversación desde=", origen)
	if origen == null:
		return
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(origen, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(origen, ficha)
	var contexto := npc.construir_contexto_accion(opcion, ficha, origen, npc.coordenada_mapa)
	var resultado: ResultadoAccion = escenario._procesar_accion_contextual(contexto)
	print("RoffaPrisionero: hablar resultado=", resultado.motivo, " alcance=", contexto.alcance_maximo, " combate=", escenario.en_combate)
	_comprobar(resultado.exitosa and not escenario.en_combate, "Se puede hablar desde el pasillo a cuatro casillas sin combate ni acercamiento.")
	var lejano := npc.construir_contexto_accion(opcion, ficha, npc.coordenada_mapa + Vector2i(5, 0), npc.coordenada_mapa)
	_comprobar(escenario.gestor_acciones.procesar_accion(lejano).motivo == &"fuera_de_alcance", "Cinco casillas quedan fuera de alcance.")
	var tras_pared := npc.construir_contexto_accion(opcion, ficha, Vector2i(49, -16), npc.coordenada_mapa)
	_comprobar(escenario.gestor_acciones.procesar_accion(tras_pared).motivo == &"linea_de_efecto_bloqueada", "No se conversa atravesando la pared de piedra.")
	await _probar_dialogo(escenario, npc, perfil.dialogos[0])
	escenario._presentar_resultado_contextual("Hablar", resultado, contexto)
	await create_timer(0.15).timeout
	_comprobar(escenario.dialogo_npc_activo and escenario.npc_dialogo_activo == npc, "El flujo contextual abre el diálogo de Roffa.")
	for globo in escenario.get_children():
		if globo.get_script() == load("res://scenes/dialogue/balloon.gd") and globo.dialogue_resource == perfil.dialogos[0].recurso:
			print("RoffaIlustracion: textura=", globo.ilustracion_npc.texture, " visible=", globo.ilustracion_npc.visible, " configurada=", globo.textura_npc)
			_comprobar(globo.ilustracion_npc.visible and globo.ilustracion_npc.texture == perfil.ilustracion_dialogo, "El globo muestra la ilustración de Roffa suministrada por el usuario.")
			_comprobar(perfil.ilustracion_dialogo.resource_path.ends_with("roffa_dialogo.png"), "La ilustración de diálogo es independiente del retrato de turno.")
			EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false, "roffa_conocido": true})
			await globo.next("preguntas")
			await process_frame
			var visibles: Array = globo.responses_menu.get_children().filter(func(n): return n.visible)
			_comprobar(globo.responses_menu.hide_failed_responses and visibles.size() == 3, "Las ramas aún desconocidas se ocultan por completo en la interfaz.")
			for paso in range(4):
				if not globo.dialogue_line.responses.is_empty():
					break
				await globo.next(globo.dialogue_line.next_id)
			globo._on_responses_menu_response_selected(globo.dialogue_line.responses.back())
			await create_timer(0.1).timeout
			await globo.next(globo.dialogue_line.next_id)
	await process_frame
	_comprobar(not escenario.dialogo_npc_activo, "Cerrar el diálogo libera el modal.")


func _probar_dialogo(escenario: Node, npc: PersonajeNPC, tema: DialogoNPC) -> void:
	var gestor := root.get_node("DialogueManager")
	_comprobar(tema.es_valido(), "El tema está configurado.")
	var estados := [npc, escenario.ficha_jugador, escenario]
	var intro: DialogueLine = await gestor.get_next_dialogue_line(tema.recurso, "start", estados)
	_comprobar(intro.responses.size() == 2 and intro.text.contains("Pssst") and not EstadoPartida.roffa_conocido, "La primera conversación ofrece responder o retirarse, sin revelar sus planes.")
	await _hasta_menu(tema.recurso, intro.responses.back().next_id, estados)
	_comprobar(not EstadoPartida.roffa_conocido, "Retirarse antes de presentarse conserva la introducción pendiente.")
	var presentacion: Dictionary = await _hasta_menu(tema.recurso, intro.responses[0].next_id, estados)
	_comprobar(EstadoPartida.roffa_conocido and presentacion.textos.contains("Me llamo Roffa"), "Responder lleva a la presentación y la recuerda al completarla.")
	_comprobar(not presentacion.textos.contains("herramienta") and not presentacion.textos.contains("campamento"), "La introducción no revela el objetivo ni la solución del nivel.")
	_comprobar(_permitidas(presentacion.linea).size() == 3 and not _ofrece(presentacion.linea, "guardias") and not _ofrece(presentacion.linea, "derrumbe"), "Antes de los triggers no se ofrecen preguntas sobre guardias ni derrumbe.")
	var regreso: Dictionary = await _hasta_menu(tema.recurso, "start", estados)
	_comprobar(regreso.textos.contains("Ah, eres tú") and not regreso.textos.contains("Me llamo"), "Volver a hablar usa el saludo corto.")
	var celda: Dictionary = await _hasta_menu(tema.recurso, "celda", estados)
	_comprobar(_ofrece(celda.linea, "otra forma") and not celda.textos.contains("Ya has visto"), "Los rumores se descubren al preguntar por la cerradura, sin asumir encuentros previos.")
	var rumores: Dictionary = await _hasta_menu(tema.recurso, "rumores", estados)
	_comprobar(rumores.textos.contains("trampas") and rumores.textos.contains("rumor"), "Roffa sólo transmite rumores del lugar con trampas.")
	await _cruzar_guardias(escenario)
	var tras_trigger: Dictionary = await _hasta_menu(tema.recurso, "preguntas", estados)
	_comprobar(_ofrece(tras_trigger.linea, "guardias") and not _ofrece(tras_trigger.linea, "derrumbe"), "El trigger real de guardias desbloquea únicamente su rama.")
	var interprete: Dictionary = await _hasta_menu(tema.recurso, "interprete", estados)
	_comprobar(interprete.textos.contains("campamento") and interprete.textos.contains("explicarles tu situación"), "Tras ver a los guardias ofrece mediar al salir.")
	var derrumbe := load("res://dialogues/prision/derrumbe.dialogue") as DialogueResource
	await _hasta_menu(derrumbe, "start", [escenario.ficha_jugador, escenario])
	var tras_derrumbe: Dictionary = await _hasta_menu(tema.recurso, "preguntas", estados)
	_comprobar(EstadoPartida.prision_derrumbe_visto and _ofrece(tras_derrumbe.linea, "derrumbe"), "El diálogo del derrumbe habilita su pregunta.")
	var snapshot: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, escenario.obtener_id_zona(), escenario.ficha_jugador, escenario.registro_conocimiento)
	_comprobar(not snapshot.is_empty() and snapshot.memoria_narrativa.roffa_conocido, "El snapshot real incluye la presentación y los hitos narrativos.")
	EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false})
	_comprobar(EstadoPartida.restaurar_estado_persistente(snapshot.memoria_narrativa) == &"", "Los hitos se restauran desde el snapshot.")
	var restaurado: Dictionary = await _hasta_menu(tema.recurso, "start", estados)
	_comprobar(restaurado.textos.contains("Ah, eres tú") and _ofrece(restaurado.linea, "guardias") and _ofrece(restaurado.linea, "derrumbe"), "Cargar conserva el saludo corto y las ramas desbloqueadas.")
	for cue in ["encierro", "rumores", "interprete", "derrumbe"]:
		var resultado: Dictionary = await _hasta_menu(tema.recurso, cue, estados)
		_comprobar(not resultado.textos.to_lower().contains("broma") and not resultado.textos.to_lower().contains("ganzúa"), "El tema %s conserva las revelaciones posteriores." % cue)


func _hasta_menu(recurso: DialogueResource, cue: String, estados: Array) -> Dictionary:
	var linea: DialogueLine = await recurso.get_next_dialogue_line(cue, estados)
	var textos := ""
	for paso in range(20):
		if linea == null:
			break
		textos += linea.text + " "
		if not linea.responses.is_empty():
			break
		linea = await recurso.get_next_dialogue_line(linea.next_id, estados)
	return {"linea": linea, "textos": textos}


func _permitidas(linea: DialogueLine) -> Array:
	return linea.responses.filter(func(r): return r.is_allowed) if linea != null else []


func _ofrece(linea: DialogueLine, texto: String) -> bool:
	return _permitidas(linea).any(func(r): return r.text.contains(texto))


func _cruzar_guardias(escenario: Node) -> void:
	var trigger := escenario.zona_actual.get_node("Triggers/Dialogos/Guardias") as TriggerMapa
	var origen := trigger.obtener_coordenada(escenario.tablero.capa_referencia)
	var ficha: Ficha = escenario.ficha_jugador
	var tramo: Variant = null
	for i in range(trigger.longitud_umbral):
		var desde := origen + Vector2i(i, 0)
		if escenario.tablero.puede_entrar(desde, ficha) and escenario.tablero.puede_entrar(desde + Vector2i.DOWN, ficha):
			tramo = desde
			break
	_comprobar(tramo != null, "El trigger de guardias tiene un cruce transitable.")
	if tramo == null:
		return
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(tramo, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(tramo, ficha)
	await ficha.mover_por_camino([tramo, tramo + Vector2i.DOWN], escenario._preparar_paso_actor, escenario._confirmar_paso_actor, escenario._cancelar_paso_actor, escenario._procesar_salida_paso_actor, escenario._procesar_entrada_paso_actor, escenario._calcular_coste_paso_actor)
	await escenario.gestor_triggers.procesar(escenario)
	_comprobar(EstadoPartida.trigger_consumido(escenario.obtener_id_zona(), &"guardias"), "Cruzar el umbral consume el trigger existente y recuerda el encuentro.")
	var globo: Node = escenario.gestor_triggers._globo_activo
	if is_instance_valid(globo):
		for i in range(4):
			if not is_instance_valid(globo) or globo.dialogue_line == null:
				break
			await globo.next(globo.dialogue_line.next_id)
	await process_frame
	# Volver al pasillo para comprobar luego la conversación contextual real.
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(Vector2i(46, -12), escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(ficha.coordenada_mapa, ficha)


func _probar_memoria() -> void:
	EstadoPartida.roffa_conocido = true
	EstadoPartida.prision_derrumbe_visto = true
	_comprobar(EstadoPartida.restaurar_estado_persistente({"trompo_conocido": false}) == &"" and not EstadoPartida.roffa_conocido and not EstadoPartida.prision_derrumbe_visto, "Los guardados antiguos comienzan con presentación e hitos pendientes.")
	for estado in [{"trompo_conocido": false, "roffa_conocido": "sí"}, {"trompo_conocido": false, "prision_derrumbe_visto": 1}, {"trompo_conocido": false, "desconocido": true}]:
		_comprobar(EstadoPartida.validar_estado_persistente(estado) != &"", "Se rechazan banderas narrativas inválidas.")
	EstadoPartida.roffa_conocido = true
	EstadoPartida.prision_derrumbe_visto = true
	var datos := {"nombre": "Prueba", "titulo": "Errante", "clase": "Guerrero", "origen": "Prueba", "fuerza": 3, "destreza": 3, "voluntad": 3}
	_comprobar(EstadoPartida.establecer_aventurero(datos) and not EstadoPartida.roffa_conocido and not EstadoPartida.prision_derrumbe_visto, "Crear otro aventurero reinicia la presentación y los hitos.")
	EstadoPartida.consumir_aventurero()


func _comprobar(condicion: bool, texto: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(texto)
