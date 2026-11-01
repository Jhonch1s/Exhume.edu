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
	_comprobar(luces == 31, "Se conservan las 31 luces colocadas.")
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
	var b := tablero.obtener_interactuable(&"banga_roffa") as PersonajeNPC
	for npc in [a, b]:
		_comprobar(npc != null and npc.se_opone_al_jugador(), "El guardia es hostil.")
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
		escenario._evaluar_agro_npc()
		_comprobar(escenario.en_combate, "La detección inicia combate automáticamente.")
		npc.iniciar_turno()
		var plan := decisor.elegir(npc, tablero, escenario.pathfinding, [escenario.ficha_jugador], true)
		_comprobar(plan["decision"] == &"atacar", "El árbol decide atacar al PJ adyacente.")
		var ataque := AccionAtaqueNPC.new(escenario.ficha_jugador)
		_comprobar(ataque.validar_accion(ataque.construir_contexto(npc)) == &"", "El ataque del guardia está configurado.")
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
