extends Node

const PRUEBA_ACTITUD = preload("res://tests/interacciones/prueba_actitud_npc.gd")
const GLOBO = preload("res://scenes/dialogue/balloon.gd")
const RUTA := "user://prueba_dialogo_tirada_npc_automatica.json"
var _fallos: Array[String] = []
var _casos := 0
var _escena: Node2D
var _escenario: Node2D
var _npc: PersonajeNPC
var _presentadas := 0


func _ready() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_escena = load("res://tests/interacciones/escena_dialogo_tirada_npc.tscn").instantiate()
	_escenario = _escena.get_node("Escenario")
	_escenario.set_script(PRUEBA_ACTITUD.EscenarioSinRender)
	add_child(_escena)
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if _escena._enemigos.size() == 1:
			break
	_comprobar(_escena._enemigos.size() == 1, "La escena crea un custodio de prueba.")
	if _escena._enemigos.size() != 1:
		_finalizar()
		return
	_npc = _escena._enemigos[0]
	_escenario.set_process(false)
	var ficha: Ficha = _escenario.ficha_jugador
	var vecino: Variant = null
	for direccion in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var candidata: Vector2i = _npc.coordenada_mapa + direccion
		if _escenario.tablero.puede_entrar(candidata, ficha):
			vecino = candidata
			break
	_comprobar(vecino != null, "Debe haber una casilla adyacente para hablar.")
	if vecino == null:
		_finalizar()
		return
	_escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(vecino, _escenario.tablero.capa_referencia)
	_escenario.tablero.ocupar_celda(vecino, ficha)
	ficha.vol = 3
	_escenario.panel_resultado_accion.tirada_presentada.connect(func(_resultado): _presentadas += 1)
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Se puede guardar antes de hablar.")
	var rng := _rng_para(2)
	_escenario.motor_dados_dialogo = MotorDados.new(rng)
	var estado_rng := rng.state
	await _escenario.realizar_prueba_dialogo("voluntad", "Fuera de diálogo")
	_comprobar(rng.state == estado_rng and _escenario.ultima_prueba_dialogo == null, "Fuera del diálogo no hay tirada.")
	await _probar_despedida(rng)
	for dado in [2, 5, 1, 6]:
		await _probar_tirada(dado)
	_escena.queue_free()
	await get_tree().process_frame
	_finalizar()


func _abrir() -> Node:
	var ficha: Ficha = _escenario.ficha_jugador
	var opcion: OpcionAccion
	for candidata in _npc.obtener_opciones_accion(ficha):
		if candidata.id == &"hablar:tirada":
			opcion = candidata
	_comprobar(opcion != null, "El custodio ofrece Hablar.")
	if opcion == null:
		return null
	var contexto := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, ficha.coordenada_mapa, _npc.coordenada_mapa) as ContextoAccion
	var resultado: ResultadoAccion = _escenario._procesar_accion_contextual(contexto)
	_comprobar(resultado.exitosa, "Hablar se resuelve por el flujo contextual real.")
	_escenario._presentar_resultado_contextual("Hablar", resultado, contexto)
	for _intento in range(100):
		await get_tree().create_timer(0.01).timeout
		for nodo in get_tree().current_scene.get_children():
			if nodo.get_script() == GLOBO and nodo.dialogue_line != null:
				nodo.dialogue_label.skip_typing()
				return nodo
	_comprobar(false, "Debe abrir el globo de diálogo.")
	return null


func _comprobar_modal() -> void:
	_comprobar(_escenario.guardar_partida(RUTA) == &"partida_interaccion_activa", "K se bloquea durante el diálogo y los dados.")
	_comprobar(_escenario.cargar_partida(RUTA) == &"partida_interaccion_activa", "C se bloquea durante el diálogo y los dados.")


func _probar_despedida(rng: RandomNumberGenerator) -> void:
	var estado_rng := rng.state
	var globo: Node = await _abrir()
	if globo == null:
		return
	_comprobar(_escenario.historial_tiradas.obtener_entradas().is_empty() and rng.state == estado_rng, "Abrir la conversación no tira dados.")
	_comprobar_modal()
	await _escenario.realizar_prueba_dialogo("invalido", "Inválida")
	_comprobar(rng.state == estado_rng, "Un atributo inválido no consume azar.")
	globo._on_responses_menu_response_selected(globo.dialogue_line.responses[1])
	await get_tree().create_timer(0.05).timeout
	_comprobar(not _escenario.dialogo_npc_activo and _presentadas == 0 and rng.state == estado_rng, "Despedirse termina sin tirar ni abrir panel.")


func _probar_tirada(dado: int) -> void:
	var rng := _rng_para(dado)
	_escenario.motor_dados_dialogo = MotorDados.new(rng)
	var historial_inicial: int = _escenario.historial_tiradas.obtener_entradas().size()
	var registro_inicial: int = _entradas_tirada().size()
	var presentadas_inicial := _presentadas
	var estado_npc := _npc.obtener_estado_persistente()
	var estado_ficha: Dictionary = _escenario.ficha_jugador.obtener_estado_persistente()
	var globo: Node = await _abrir()
	if globo == null:
		return
	var respuesta: DialogueResponse = globo.dialogue_line.responses[0]
	var linea_inicial: DialogueLine = globo.dialogue_line
	globo._on_responses_menu_response_selected(respuesta)
	var panel: PanelResultadoAccion = _escenario.panel_resultado_accion
	for _intento in range(100):
		await get_tree().create_timer(0.01).timeout
		if panel.visible:
			break
	var prueba: ResultadoPrueba = _escenario.ultima_prueba_dialogo
	_comprobar(panel.visible and prueba != null, "Elegir convencer abre una prueba visible.")
	if prueba == null:
		return
	_comprobar(prueba.dado_seleccionado == dado and prueba.atributo == 3 and prueba.exitosa == (dado <= 3), "La rama respeta VOL y el dado determinista %d." % dado)
	var estado_rng := rng.state
	globo._on_responses_menu_response_selected(respuesta)
	await _escenario.realizar_prueba_dialogo("voluntad", "Duplicada")
	await get_tree().create_timer(0.15).timeout
	_comprobar(globo.dialogue_line == linea_inicial and globo._resolviendo_linea, "La rama espera al cierre del panel y el doble clic no avanza.")
	_comprobar_modal()
	panel._al_presionar_dado(0)
	panel._al_presionar_dado(0)
	for _intento in range(200):
		await get_tree().create_timer(0.01).timeout
		if panel._prueba_pendiente == null:
			break
	_comprobar(panel._prueba_pendiente == null and panel.etiqueta_veredicto.text.begins_with(str(dado)), "El dado revela el valor resuelto.")
	panel._revelar_tirada()
	_comprobar(rng.state == estado_rng and _escenario.ultima_prueba_dialogo == prueba, "Animar y repetir clics no consumen azar ni reemplazan el resultado.")
	_comprobar(_presentadas == presentadas_inicial + 1 and _escenario.historial_tiradas.obtener_entradas().size() == historial_inicial + 1 and _entradas_tirada().size() == registro_inicial + 1, "Cada elección registra y presenta exactamente una tirada.")
	var entrada: EntradaRegistroNarrativo = _entradas_tirada().back()
	_comprobar("VOL" in " ".join(entrada.detalles), "El registro identifica el atributo VOL.")
	panel.ocultar()
	for _intento in range(100):
		await get_tree().create_timer(0.01).timeout
		if globo.dialogue_line != linea_inicial:
			break
	var texto_esperado := "Has logrado convencerme" if prueba.exitosa else "No me has convencido"
	_comprobar(texto_esperado in globo.dialogue_line.text, "El diálogo muestra la rama del resultado real.")
	_comprobar_modal()
	globo.dialogue_label.skip_typing()
	globo.next(globo.dialogue_line.next_id)
	await get_tree().create_timer(0.05).timeout
	_comprobar(not _escenario.dialogo_npc_activo and _escenario.ultima_prueba_dialogo == null, "Finalizar libera el modal y limpia el resultado temporal.")
	_comprobar(_npc.obtener_estado_persistente() == estado_npc and _escenario.ficha_jugador.obtener_estado_persistente() == estado_ficha, "El diálogo de prueba no cambia relación, vida, XP ni recursos.")
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Se puede guardar tras terminar el diálogo.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA) == &"" and rng.state == estado_rng and _presentadas == presentadas_inicial + 1 and _escenario.ultima_prueba_dialogo == null, "Repetir carga no reabre ni repite la tirada.")


func _entradas_tirada() -> Array[EntradaRegistroNarrativo]:
	return _escenario.registro_narrativo.obtener_entradas_visibles().filter(func(entrada): return entrada.categoria == EntradaRegistroNarrativo.Categoria.TIRADA)


func _rng_para(dado: int) -> RandomNumberGenerator:
	var auxiliar := PRUEBA_ACTITUD.new()
	var rng: RandomNumberGenerator = auxiliar._rng_para([dado])
	auxiliar.free()
	return rng


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("DialogoTiradaNPC: %d comprobaciones correctas; ramas, presentación única, registro, doble clic y K/C." % _casos)
	get_tree().quit(0 if _fallos.is_empty() else 1)
