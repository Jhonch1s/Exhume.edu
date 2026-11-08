extends Node

const ZONA := &"res://scenes/Prision/prision.tscn"
const VENGANZA := &"roffa_venganza"
const PANTALLA_FINAL := "res://scenes/Prision/fin_demo.tscn"

var escenario: Node
var roffa: PersonajeNPC
var peeble: PersonajeNPC
var rengo: PersonajeNPC
var puerta: PuertaInteractuable
var salida: TriggerMapa
var en_curso := false


func _ready() -> void:
	escenario = get_parent()
	roffa = escenario.tablero.obtener_interactuable(&"banga_roffa") as PersonajeNPC
	peeble = escenario.tablero.obtener_interactuable(&"banga_peeble") as PersonajeNPC
	rengo = escenario.tablero.obtener_interactuable(&"banga_peeble_001") as PersonajeNPC
	puerta = escenario.tablero.obtener_interactuable(&"interactuable_001") as PuertaInteractuable
	salida = escenario.zona_actual.get_node_or_null("Triggers/Mecanismos/escape_prision") as TriggerMapa
	if roffa != null and peeble != null and rengo != null and puerta != null and salida != null:
		escenario.gestor_acciones.accion_finalizada.connect(_al_resolver_accion)
	else:
		set_process(false)


func _process(_delta: float) -> void:
	if EstadoPartida.trigger_consumido(ZONA, VENGANZA) and not en_curso and not escenario.en_combate and roffa.esta_muerto() and escenario.ficha_jugador.puede_actuar():
		set_process(false)
		get_tree().call_deferred(&"change_scene_to_file", PANTALLA_FINAL)


func _al_resolver_accion(contexto: ContextoAccion, resultado: ResultadoAccion) -> void:
	if en_curso or not resultado.exitosa or contexto.objetivo != puerta or contexto.id_accion != &"abrir":
		return
	if roffa.esta_muerto() or escenario.en_combate or EstadoPartida.trigger_consumido(ZONA, VENGANZA):
		return
	en_curso = true
	escenario.secuencia_prision_activa = true
	escenario._cancelar_exploracion_npc()
	escenario._actualizar_estado_modal_interaccion()
	_iniciar.call_deferred()


func _iniciar() -> void:
	while is_inside_tree() and (escenario._acciones_en_resolucion > 0 or escenario._turno_exploracion_en_curso or escenario._hay_actor_moviendose()):
		await get_tree().process_frame
	if not is_inside_tree():
		return
	if not await _dialogar("liberacion"):
		_terminar()
		return
	var camino_roffa := _camino_a_salida(roffa)
	if camino_roffa.is_empty():
		camino_roffa = await _despejar_camino()
	if camino_roffa.is_empty() or not await _acompanar(camino_roffa):
		_terminar()
		return
	var guardias_vivos := not peeble.esta_muerto() and not rengo.esta_muerto()
	if not await _dialogar("encuentro_guardias" if guardias_vivos else "encuentro_guardias_muertos"):
		_terminar()
		return
	if guardias_vivos:
		get_tree().call_deferred(&"change_scene_to_file", PANTALLA_FINAL)
	else:
		roffa.establecer_actitud_hacia_jugador(DefinicionPersonaje.ActitudInicialJugador.HOSTIL)
		_terminar()
		if escenario._iniciar_combate(roffa, false):
			EstadoPartida.consumir_trigger(ZONA, VENGANZA)
		else:
			push_warning("No se pudo iniciar el combate con Roffa.")


func _camino_a_salida(actor: Node2D) -> Array[Vector2i]:
	var mejor: Array[Vector2i] = []
	var ancla := salida.obtener_coordenada(escenario.tablero.capa_referencia)
	for x in salida.tamano.x:
		for y in salida.tamano.y:
			var destino := ancla + Vector2i(x, y)
			var camino: Array[Vector2i] = escenario.pathfinding.calcular_camino(actor.coordenada_mapa, destino, escenario.tablero.datos, actor)
			if not camino.is_empty() and (mejor.is_empty() or camino.size() < mejor.size()):
				mejor = camino
	return mejor


func _despejar_camino() -> Array[Vector2i]:
	var jugador: Ficha = escenario.ficha_jugador
	var origen := jugador.coordenada_mapa
	for radio in range(1, 5):
		for x in range(-radio, radio + 1):
			for y in range(-radio, radio + 1):
				if absi(x) + absi(y) != radio:
					continue
				var destino := origen + Vector2i(x, y)
				if not escenario.tablero.puede_entrar(destino, jugador):
					continue
				var ruta: Array[Vector2i] = escenario.pathfinding.calcular_camino(origen, destino, escenario.tablero.datos, jugador)
				if ruta.is_empty():
					continue
				escenario.tablero.liberar_celda(origen, jugador)
				escenario.tablero.ocupar_celda(destino, jugador)
				var libre := not _camino_a_salida(roffa).is_empty()
				escenario.tablero.liberar_celda(destino, jugador)
				escenario.tablero.ocupar_celda(origen, jugador)
				if libre and await _caminar(jugador, ruta):
					return _camino_a_salida(roffa)
	return []


func _acompanar(camino: Array[Vector2i]) -> bool:
	for destino in camino:
		var anterior := roffa.coordenada_mapa
		if destino == anterior:
			continue
		var paso: Array[Vector2i] = [anterior, destino]
		if not await _caminar(roffa, paso):
			return false
		var jugador: Ficha = escenario.ficha_jugador
		if jugador.coordenada_mapa == anterior:
			continue
		var camino_jugador: Array[Vector2i] = escenario.pathfinding.calcular_camino(jugador.coordenada_mapa, anterior, escenario.tablero.datos, jugador)
		if camino_jugador.is_empty() or not await _caminar(jugador, camino_jugador):
			return false
	return true


func _caminar(actor: Node2D, camino: Array[Vector2i]) -> bool:
	var capa: TileMapLayer = escenario.tablero.capa_referencia
	for destino in camino:
		var origen: Vector2i = actor.coordenada_mapa
		if destino == origen:
			continue
		if not actor.puede_actuar() or not escenario.tablero.reservar_celda(destino, actor):
			return false
		actor.orientar_paso_movimiento(origen, destino)
		var tween := actor.create_tween()
		tween.tween_property(actor, "global_position", capa.to_global(capa.map_to_local(destino)), actor.calcular_duracion_paso(1))
		await tween.finished
		if not escenario.tablero.confirmar_movimiento(origen, destino, actor):
			escenario.tablero.cancelar_reserva(destino, actor)
			actor.global_position = capa.to_global(capa.map_to_local(origen))
			return false
		actor.coordenada_mapa = destino
		if actor is Ficha:
			actor.paso_dado.emit(destino)
	return true


func _dialogar(cue: String) -> bool:
	var dialogo := load("res://dialogues/prision/roffa.dialogue") as DialogueResource
	if dialogo == null or not dialogo.cues.has(cue):
		push_warning("Falta importar el diálogo de cierre de Roffa: %s." % cue)
		return false
	var globo := DisparadorDialogoArea.mostrar(dialogo, cue, [roffa, escenario.ficha_jugador, escenario])
	if globo == null:
		return false
	if globo.has_method(&"configurar_participantes"):
		globo.configurar_participantes(escenario.ficha_jugador.nombre, escenario._obtener_ilustracion_dialogo_jugador(), roffa.obtener_nombre_interaccion(), roffa.obtener_definicion_personaje().ilustracion_dialogo)
	globo.tree_exiting.connect(escenario._on_dialogo_camara_finalizado.bind(dialogo), CONNECT_ONE_SHOT)
	await globo.tree_exited
	return true


func _terminar() -> void:
	en_curso = false
	escenario.secuencia_prision_activa = false
	escenario._actualizar_estado_modal_interaccion()
