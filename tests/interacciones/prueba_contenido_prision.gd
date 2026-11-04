extends SceneTree

var fallos: Array[String] = []
var comprobaciones := 0


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var catalogo_de_escena: CatalogoMensajesInteraccion = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	# El doble de render reinicia las propiedades exportadas al cambiar de script.
	escenario.catalogo_mensajes = catalogo_de_escena
	escenario.get_node("Zona").free()
	var zona = load("res://scenes/Prision/prision.tscn").instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	escenario.intervalo_exploracion_npc = 0.15
	root.add_child(escenario)
	for intento in range(300):
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	_comprobar(escenario.ficha_jugador != null, "La prisión crea la ficha.")
	var tablero: TableroGrid = escenario.tablero
	var tablero_validacion := TableroGrid.new()
	tablero_validacion.generar_desde_zona(zona)
	var errores := ValidadorContenidoZona.new().validar(zona, tablero_validacion, zona.get_node("CapaSuelo"))
	tablero_validacion.free()
	_comprobar(errores.is_empty(), "La prisión permite registrar su contenido: %s." % [errores])
	if not errores.is_empty() or escenario.ficha_jugador == null:
		for fallo in fallos:
			push_error(fallo)
		quit(1)
		return
	var luces := 0
	var catalogo := load("res://assets/interactuables/mensajes_interacciones.tres") as CatalogoMensajesInteraccion
	_comprobar(catalogo.es_valido(), "El catálogo de mensajes es válido.")
	for n in zona.find_children("*", "", true, false):
		if not n is Interactuable:
			continue
		_comprobar(tablero.obtener_interactuable(n.id_instancia) == n, "Se registra %s." % n.id_instancia)
		for f in n.obtener_fragmentos_informacion():
			_comprobar(catalogo.resolver(f.id_mensaje) != String(f.id_mensaje), "Existe el texto de %s." % f.id_mensaje)
		if n is FuenteLuzInteractuable:
			luces += 1
			_comprobar(n.obtener_opciones_accion().any(func(o): return o.id == &"examinar"), "La luz %s se puede examinar." % n.id_instancia)
	_comprobar(luces == 31, "Se conservan las 31 luces colocadas; se encontraron %d." % luces)
	_probar_hallazgos(escenario)
	var notas := tablero.obtener_interactuable(&"pista_inicial") as Interactuable
	_comprobar(notas.texto_examen.is_empty(), "El texto de notas no tapa los fragmentos.")
	var evaluador := EvaluadorInformacion.new()
	var lejos := evaluador.evaluar(notas.obtener_fragmentos_informacion(), CondicionesObservacion.new(escenario.ficha_jugador, 4.0, true, true), notas.definicion.perfil_observacion)
	var cerca := evaluador.evaluar(notas.obtener_fragmentos_informacion(), CondicionesObservacion.new(escenario.ficha_jugador, 1.0, true, true), notas.definicion.perfil_observacion)
	_comprobar(lejos.fragmentos_disponibles.size() == 1 and cerca.fragmentos_disponibles.size() == 3, "Acercarse a las notas revela transcripción y detalles.")
	_comprobar(catalogo.resolver(&"examen.prision.hojas.transcripcion").contains("Oinc oinc... OINCC!!!"), "Se conserva el chiste original.")
	var mensajes_cercanos: Array[StringName] = []
	for f in cerca.fragmentos_disponibles:
		mensajes_cercanos.append(f.id_mensaje)
	var contexto_notas := ContextoAccion.new(TiposInteraccion.TipoAccion.EXAMINAR, escenario.ficha_jugador, escenario.ficha_jugador.coordenada_mapa, notas.coordenada_mapa, notas)
	escenario._presentar_resultado_contextual("Notas garabateadas", ResultadoAccion.crear_exito(mensajes_cercanos), contexto_notas)
	_comprobar(escenario.panel_examen_ilustrado.visible and escenario.panel_examen_ilustrado.etiqueta_texto.text.contains("Oinc oinc... OINCC!!!") and escenario.panel_examen_ilustrado.etiqueta_texto.text.contains("subrayados"), "El panel del juego muestra el texto original y el nuevo fragmento.")
	escenario.panel_examen_ilustrado.ocultar()
	var a := tablero.obtener_interactuable(&"banga_peeble") as PersonajeNPC
	var b := tablero.obtener_interactuable(&"banga_peeble_001") as PersonajeNPC
	for npc in [a, b]:
		_comprobar(npc != null and npc.se_opone_al_jugador(), "El guardia es hostil.")
		_comprobar(not npc.obtener_definicion_personaje().puede_dialogar and not npc.obtener_opciones_accion(escenario.ficha_jugador).any(func(o): return o.id == &"hablar"), "El guardia no ofrece diálogo antes del combate.")
		_comprobar(npc.obtener_definicion_personaje().puede_combatir and npc.nivel_actual == 3 and npc.vida_actual == 22, "El guardia tiene nivel y vida completos.")
		_comprobar(npc.obtener_patrulla().esta_configurada(), "La patrulla del guardia está configurada.")
		_comprobar(npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) >= 0, "El guardia tiene movimiento.")
		npc.velocidad_paso = 0.02
	_comprobar(a.atributos_actuales == b.atributos_actuales and a.obtener_definicion_personaje().movimiento_fijo == b.obtener_definicion_personaje().movimiento_fijo, "Ambos guardias comparten estadísticas.")
	var inicios: Array[Vector2i] = [a.coordenada_mapa, b.coordenada_mapa]
	var indices := [0, 0]
	var vueltas := [0, 0]
	for tick in range(400):
		await create_timer(0.05).timeout
		for i in range(2):
			var npc: PersonajeNPC = [a, b][i]
			var indice: int = npc.obtener_patrulla().obtener_estado_persistente()["indice_siguiente"]
			if indice < indices[i]:
				vueltas[i] += 1
			indices[i] = indice
		if vueltas[0] >= 2 and vueltas[1] >= 2:
			break
	_comprobar(vueltas[0] >= 2 and vueltas[1] >= 2, "Ambos guardias completan al menos dos circuitos: %s." % [vueltas])
	print("Patrullas Prisión: vueltas=", vueltas, " posiciones iniciales=", inicios)
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	await create_timer(0.3).timeout
	for npc in [a, b]:
		var decisor: DecisorCombateNPC = escenario._obtener_decisor_npc(npc)
		_comprobar(decisor.behavior_tree == DecisorCombateNPC.ARBOL, "El guardia usa el árbol de IA compartido.")
		var vecino: Variant = null
		for dir in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var c: Vector2i = npc.coordenada_mapa + dir
			if tablero.puede_entrar(c, escenario.ficha_jugador) and escenario.validador_espacial.validar_linea_visual(npc.coordenada_mapa, c) == &"":
				vecino = c
				break
		_comprobar(vecino != null, "Hay una casilla adyacente para probar la detección.")
		if vecino == null:
			continue
		if escenario.en_combate:
			escenario._terminar_combate(false)
		tablero.liberar_celda(escenario.ficha_jugador.coordenada_mapa, escenario.ficha_jugador)
		escenario.ficha_jugador.inicializar(vecino, tablero.capa_referencia)
		tablero.ocupar_celda(vecino, escenario.ficha_jugador)
		escenario._actualizar_luz_jugador(vecino)
		_comprobar(npc.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial), "El guardia detecta al PJ por proximidad y visión.")
		escenario.set_process(true)
		await process_frame
		await process_frame
		escenario.set_process(false)
		_comprobar(escenario.en_combate and npc.en_oposicion_encuentro, "La detección inicia combate automáticamente, sin hablar ni agredir al guardia.")
		npc.iniciar_turno()
		var plan := decisor.elegir(npc, tablero, escenario.pathfinding, [escenario.ficha_jugador], true)
		_comprobar(plan["decision"] == &"atacar", "El árbol decide atacar al PJ adyacente.")
		var ataque := AccionAtaqueNPC.new(escenario.ficha_jugador)
		_comprobar(ataque.validar_accion(ataque.construir_contexto(npc)) == &"", "El ataque del guardia está configurado.")
	for id in [&"sirviente_eek_001", &"sirviente_eek_002"]:
		if escenario.en_combate:
			escenario._terminar_combate(false)
		escenario.ficha_jugador.retirar_estado(&"inmovilizado")
		var arana := tablero.obtener_interactuable(id) as PersonajeNPC
		_comprobar(arana != null, "La araña %s está registrada." % id)
		if arana == null:
			continue
		var perfil := arana.obtener_definicion_personaje()
		_comprobar(perfil != null and perfil.puede_combatir and perfil.estilo_combate == DefinicionPersonaje.EstiloCombate.SIRVIENTE_EEK and arana.se_opone_al_jugador(), "%s hereda IA hostil de Eek." % id)
		_comprobar(arana.vida_actual == 8 and arana.obtener_fuerza() == 2 and arana.obtener_destreza() == 3 and arana.obtener_voluntad() == 1, "%s conserva los atributos de Eek." % id)
		_comprobar(arana.get_node_or_null(arana.ruta_visual_resaltable) == arana.get_node_or_null("Sprite2D"), "%s resalta su propio sprite." % id)
		var vecino: Variant = null
		for dir in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var c: Vector2i = arana.coordenada_mapa + dir
			if tablero.puede_entrar(c, escenario.ficha_jugador) and escenario.validador_espacial.validar_linea_visual(arana.coordenada_mapa, c) == &"":
				vecino = c
				break
		_comprobar(vecino != null, "%s tiene acceso para detectar al aventurero." % id)
		if vecino == null:
			continue
		tablero.liberar_celda(escenario.ficha_jugador.coordenada_mapa, escenario.ficha_jugador)
		escenario.ficha_jugador.inicializar(vecino, tablero.capa_referencia)
		tablero.ocupar_celda(vecino, escenario.ficha_jugador)
		_comprobar(arana.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial), "%s detecta al aventurero." % id)
		escenario._evaluar_agro_npc()
		_comprobar(escenario.en_combate and arana.en_oposicion_encuentro, "%s inicia o se incorpora al combate." % id)
		arana.iniciar_turno()
		var plan: Dictionary = escenario._plan_combate_npc(arana)
		_comprobar(plan["decision"] == AccionSirvienteEek.TELARANA and plan["objetivo"] == escenario.ficha_jugador, "%s elige lanzar telaraña." % id)
		var habilidad := AccionSirvienteEek.new(escenario.ficha_jugador, escenario.gestor_rondas)
		var resultado: ResultadoAccion = escenario.gestor_acciones.procesar_accion(habilidad.construir_contexto(arana, AccionSirvienteEek.TELARANA))
		_comprobar(resultado.exitosa and resultado.tirada is ResultadoPrueba and arana.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "%s ejecuta telaraña y gasta su acción." % id)
	var terror := tablero.obtener_interactuable(&"terror_nocturno_001") as PersonajeNPC
	_comprobar(terror != null, "El terror nocturno está registrado.")
	if terror != null:
		var perfil := terror.obtener_definicion_personaje()
		_comprobar(perfil.puede_combatir and perfil.estilo_combate == DefinicionPersonaje.EstiloCombate.TERROR_NOCTURNO and terror.se_opone_al_jugador(), "El terror nocturno tiene IA hostil.")
		_comprobar(terror.vida_actual == 10 and terror.obtener_fuerza() == 2 and terror.obtener_destreza() == 4 and terror.obtener_voluntad() == 2, "El terror nocturno conserva sus atributos.")
		_comprobar(terror.get_node_or_null(terror.ruta_visual_resaltable) == terror.get_node_or_null("Sprite2D"), "El terror nocturno resalta su propio sprite.")
	if escenario.en_combate:
		escenario._terminar_combate(false)
	escenario._cancelar_exploracion_npc()
	escenario.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("ContenidoPrision: %d comprobaciones, %d fallos." % [comprobaciones, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _comprobar(correcto: bool, texto: String) -> void:
	comprobaciones += 1
	if not correcto:
		fallos.append(texto)


func _probar_hallazgos(escenario: Node) -> void:
	for id in [
		&"prision_advertencia_guardias", &"prision_registro_celdas",
		&"prision_diario_inconcluso", &"prision_cartel_advertencia",
		&"prision_estandarte_remendado",
	]:
		var guia := escenario.tablero.obtener_interactuable(id) as GuiaInteractuable
		_comprobar(guia != null, "Se registra el hallazgo %s." % id)
		if guia == null:
			continue
		var origen: Variant = null
		for dir in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var c: Vector2i = guia.coordenada_mapa + dir
			if not escenario.tablero.puede_entrar(c, escenario.ficha_jugador):
				continue
			if escenario.zona_actual.get_node("CapaPinchos").get_cell_source_id(c) >= 0:
				continue
			if escenario.validador_espacial.validar_linea_visual(c, guia.coordenada_mapa) != &"":
				continue
			var camino: Array[Vector2i] = escenario.pathfinding.calcular_camino(escenario.ficha_jugador.coordenada_mapa, c, escenario.tablero.datos, escenario.ficha_jugador)
			if not camino.is_empty():
				origen = c
				break
		_comprobar(origen != null, "Se puede llegar a una casilla segura para leer %s." % id)
		if origen == null:
			continue
		var celda: Celda = escenario.tablero.obtener_celda(guia.coordenada_mapa)
		var visibilidad_anterior := celda.visibilidad
		celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
		var opciones := guia.obtener_opciones_accion(escenario.ficha_jugador)
		var opcion: OpcionAccion
		for o in opciones:
			if o.id == &"examinar":
				opcion = o
		_comprobar(opcion != null, "El hallazgo ofrece examinar.")
		if opcion == null:
			continue
		var objetivos: Array[Object] = escenario.selector_objetivos.obtener_objetivos_perceptibles(escenario.tablero, guia.coordenada_mapa, escenario.ficha_jugador)
		_comprobar(guia in objetivos, "El selector detecta %s al pasar el cursor por la casilla visible." % id)
		var contexto := guia.construir_contexto_accion(opcion, escenario.ficha_jugador, origen, guia.coordenada_mapa)
		var resultado: ResultadoAccion = escenario.servicio_examen.resolver_examen(contexto, guia)
		_comprobar(resultado.exitosa and resultado.mensajes.size() == 2, "Se leen los dos fragmentos de %s." % id)
		escenario._presentar_resultado_contextual(guia.obtener_nombre_interaccion(), resultado, contexto)
		_comprobar(escenario.panel_examen_ilustrado.visible and escenario.panel_examen_ilustrado.etiqueta_texto.text.contains(guia.definicion.descripcion_base), "El panel muestra el contenido de %s." % id)
		escenario.panel_examen_ilustrado.ocultar()
		celda.visibilidad = visibilidad_anterior
