extends "res://tests/interacciones/prueba_dialogo_tirada_npc.gd"

const RUTA_CONSECUENCIAS := "user://prueba_consecuencias_dialogo_automatica.json"
const ID_PRUEBA := &"confianza_custodio"
var _tema: DialogoNPC
var _prueba: PruebaDialogoNPC


func _ejecutar() -> void:
	_escena = load("res://tests/interacciones/escena_consecuencias_dialogo_npc.tscn").instantiate()
	_escena.tema_consecuencias = _escena.tema_consecuencias.duplicate(true)
	_escenario = _escena.get_node("Escenario")
	_escenario.set_script(PRUEBA_ACTITUD.EscenarioSinRender)
	add_child(_escena)
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if _escena._enemigos.size() == 1:
			break
	_comprobar(_escena._enemigos.size() == 1, "La escena crea al custodio configurable.")
	if _escena._enemigos.size() != 1:
		_finalizar()
		return
	_npc = _escena._enemigos[0]
	_comprobar("CONSECUENCIAS" in _escena._estado.text and _escenario.catalogo_mensajes.resolver(&"dialogo.custodio.confidencia") == "El custodio guarda una llave de repuesto en su bota.", "La escena manual termina de preparar instrucciones y texto de la consecuencia.")
	_tema = _escena.tema_consecuencias
	_prueba = _tema.obtener_prueba(ID_PRUEBA)
	_escenario.set_process(false)
	var ficha: Ficha = _escenario.ficha_jugador
	var vecino: Variant = null
	for direccion in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var candidata: Vector2i = _npc.coordenada_mapa + direccion
		if _escenario.tablero.puede_entrar(candidata, ficha):
			vecino = candidata
			break
	_comprobar(vecino != null, "Hay una casilla adyacente para hablar.")
	if vecino == null:
		_finalizar()
		return
	_escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(vecino, _escenario.tablero.capa_referencia)
	_escenario.tablero.ocupar_celda(vecino, ficha)
	ficha.vol = 3
	_escenario.panel_resultado_accion.tirada_presentada.connect(func(_resultado): _presentadas += 1)
	_comprobar(_escenario.guardar_partida(RUTA_CONSECUENCIAS) == &"", "Guardar antes de las consecuencias.")
	for dado in [2, 5, 1, 6]:
		await _probar_resultado(dado)
	await _probar_repetible()
	await _probar_configuracion_invalida()
	_probar_estado_y_capacidades()
	_escena.queue_free()
	await get_tree().process_frame
	_finalizar()


func _conoce() -> bool:
	return _escenario.registro_conocimiento.conoce_fragmento(_escenario.ficha_jugador.id_observador, _npc.id_instancia, &"confidencia")


func _terminar(globo: Node) -> void:
	globo.dialogue_label.skip_typing()
	globo.next(globo.dialogue_line.next_id)
	await get_tree().create_timer(0.05).timeout
	_comprobar(not _escenario.dialogo_npc_activo and not _escenario.prueba_dialogo_resuelta, "Finalizar libera el modal y el estado temporal.")


func _elegir(globo: Node, dado: int) -> void:
	var rng := _rng_para(dado)
	_escenario.motor_dados_dialogo = MotorDados.new(rng)
	var inicial: DialogueLine = globo.dialogue_line
	var respuesta: DialogueResponse = inicial.responses[0]
	globo._on_responses_menu_response_selected(respuesta)
	var panel: PanelResultadoAccion = _escenario.panel_resultado_accion
	for _intento in range(100):
		await get_tree().create_timer(0.01).timeout
		if panel.visible:
			break
	_comprobar(panel.visible and _escenario.ultima_prueba_dialogo != null, "La elección configurada abre una prueba visible.")
	if not panel.visible:
		return
	var estado_rng := rng.state
	var puntos := _npc.obtener_puntos_actitud()
	var conocido := _conoce()
	globo._on_responses_menu_response_selected(respuesta)
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	await get_tree().create_timer(0.15).timeout
	_comprobar(_npc.obtener_puntos_actitud() == puntos and _conoce() == conocido and not _npc.estado_personaje.resultados_pruebas_dialogo.has(ID_PRUEBA), "Esperar el panel o duplicar la elección no aplica consecuencias ni marca intentos.")
	_comprobar_modal()
	# El cierre anticipado usa el mismo resultado que la animación, ya cubierta por la prueba base.
	panel.ocultar()
	for _intento in range(100):
		await get_tree().create_timer(0.01).timeout
		if globo.dialogue_line != inicial:
			break
	_comprobar(rng.state == estado_rng, "Cerrar el panel no vuelve a tirar.")
	_comprobar_modal()


func _probar_resultado(dado: int) -> void:
	_comprobar(_escenario.cargar_partida(RUTA_CONSECUENCIAS) == &"", "Rebobinar antes del intento.")
	_comprobar(_npc.obtener_puntos_actitud() == 0 and not _conoce() and _npc.estado_personaje.resultados_pruebas_dialogo.is_empty(), "El snapshot anterior restaura relación, información e intento juntos.")
	var historial_inicial: int = _escenario.historial_tiradas.obtener_entradas().size()
	var registro_inicial: int = _escenario.registro_narrativo.obtener_entradas_visibles().size()
	var presentadas_inicial := _presentadas
	var ficha_inicial: Dictionary = _escenario.ficha_jugador.obtener_estado_persistente()
	var globo: Node = await _abrir()
	if globo == null:
		return
	await _elegir(globo, dado)
	var exito := dado <= 3
	var puntos := 3 if exito else -1
	_comprobar(_npc.obtener_puntos_actitud() == puntos and _conoce() == exito, "La rama selecciona actitud e información correctas para dado %d." % dado)
	_comprobar(_npc.estado_personaje.resultados_pruebas_dialogo.get(ID_PRUEBA) == exito, "Se recuerda también el fallo, sin confundirlo con ausencia.")
	_comprobar(_escenario.prueba_dialogo_exitosa == exito and _escenario.prueba_dialogo_resuelta, "La condición del diálogo corresponde a la prueba real.")
	_comprobar(("Has logrado convencerme" if exito else "No me has convencido") in globo.dialogue_line.text, "La conversación continúa por la rama correcta.")
	_comprobar(_escenario.historial_tiradas.obtener_entradas().size() == historial_inicial + 1 and _presentadas == presentadas_inicial + 1, "Hay una sola prueba por elección.")
	_comprobar(_escenario.registro_narrativo.obtener_entradas_visibles().size() == registro_inicial + (3 if exito else 2), "El registro muestra sólo la tirada y las consecuencias aplicadas.")
	if exito:
		_comprobar(_escenario.registro_narrativo.obtener_entradas_visibles().back().mensaje == "El custodio guarda una llave de repuesto en su bota.", "La información se presenta traducida y no como un ID interno.")
	_comprobar(_escenario.ficha_jugador.obtener_estado_persistente() == ficha_inicial, "Las consecuencias no cambian XP, PV ni recursos del jugador.")
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_comprobar(_npc.obtener_puntos_actitud() == puntos and _presentadas == presentadas_inicial + 1 and not _escenario.panel_resultado_accion.visible, "Un segundo pedido reutiliza el resultado sin aplicar otra vez.")
	await _terminar(globo)
	_comprobar(_escenario.guardar_partida(RUTA_CONSECUENCIAS + ".despues") == &"", "Guardar después de aplicar las consecuencias.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA_CONSECUENCIAS + ".despues") == &"" and _npc.obtener_puntos_actitud() == puntos and _conoce() == exito and _npc.estado_personaje.resultados_pruebas_dialogo.get(ID_PRUEBA) == exito, "K/C repetida conserva consecuencias e intento sin reaplicarlos.")
	globo = await _abrir()
	if globo == null:
		return
	_comprobar(("Ya te confié mi secreto" in globo.dialogue_line.text) == exito, "Otra conversación puede consultar la información descubierta.")
	var rng := _rng_para(6 if exito else 1)
	_escenario.motor_dados_dialogo = MotorDados.new(rng)
	var estado_rng := rng.state
	globo._on_responses_menu_response_selected(globo.dialogue_line.responses[0])
	await get_tree().create_timer(0.05).timeout
	_comprobar(rng.state == estado_rng and _escenario.ultima_prueba_dialogo == null and _escenario.prueba_dialogo_exitosa == exito and _npc.obtener_puntos_actitud() == puntos, "Volver a hablar conserva el resultado anterior y no consume azar.")
	_comprobar(_presentadas == presentadas_inicial + 1 and _escenario.registro_narrativo.obtener_entradas_visibles().size() == registro_inicial + (3 if exito else 2), "Revisitar no abre dados ni duplica registros.")
	await _terminar(globo)


func _probar_repetible() -> void:
	_comprobar(_escenario.cargar_partida(RUTA_CONSECUENCIAS) == &"", "Preparar la opción repetible sin intentos anteriores.")
	_prueba.una_sola_vez = false
	for dado in [2, 5]:
		var globo: Node = await _abrir()
		if globo == null:
			return
		await _elegir(globo, dado)
		await _terminar(globo)
	_comprobar(_npc.obtener_puntos_actitud() == 2 and _conoce() and _npc.estado_personaje.resultados_pruebas_dialogo.is_empty(), "Desactivar intento único permite nuevas tiradas y consecuencias por elección.")
	_prueba.una_sola_vez = true


func _probar_configuracion_invalida() -> void:
	_comprobar(_escenario.cargar_partida(RUTA_CONSECUENCIAS) == &"", "Preparar el rechazo de configuración.")
	var globo: Node = await _abrir()
	if globo == null:
		return
	var rng := _rng_para(2)
	_escenario.motor_dados_dialogo = MotorDados.new(rng)
	var estado_rng := rng.state
	var estado_npc := _npc.obtener_estado_persistente()
	var historial: int = _escenario.historial_tiradas.obtener_entradas().size()
	var consecuencias_fallo := _prueba.consecuencias_fallo.duplicate()
	_prueba.consecuencias_fallo.append(null)
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_prueba.consecuencias_fallo = consecuencias_fallo.duplicate()
	var informacion_invalida := ConsecuenciaDialogoNPC.new()
	informacion_invalida.tipo = ConsecuenciaDialogoNPC.Tipo.REVELAR_INFORMACION
	informacion_invalida.id_fragmento = &"inexistente"
	_prueba.consecuencias_fallo.append(informacion_invalida)
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_prueba.consecuencias_fallo = consecuencias_fallo.duplicate()
	_tema.pruebas.append(_prueba)
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_tema.pruebas.pop_back()
	var otro_tema := _tema.duplicate()
	_npc.obtener_definicion_personaje().dialogos.append(otro_tema)
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_npc.obtener_definicion_personaje().dialogos.pop_back()
	_prueba.atributo = "carisma"
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_prueba.atributo = "voluntad"
	await _escenario.realizar_prueba_dialogo_configurada(&"inexistente")
	_comprobar(rng.state == estado_rng and _npc.obtener_estado_persistente() == estado_npc and not _conoce() and _escenario.historial_tiradas.obtener_entradas().size() == historial, "Configuraciones inválidas de cualquiera de las ramas se rechazan antes de tirar o mutar.")
	_comprobar(not _escenario.prueba_dialogo_resuelta and not _escenario.prueba_dialogo_exitosa and not _escenario.panel_resultado_accion.visible, "Una configuración inválida no reutiliza el éxito de una tirada previa.")
	globo._on_responses_menu_response_selected(globo.dialogue_line.responses[1])
	await get_tree().create_timer(0.05).timeout
	await _escenario.realizar_prueba_dialogo_configurada(ID_PRUEBA)
	_comprobar(rng.state == estado_rng, "Fuera del diálogo no se aplican consecuencias configuradas.")


func _probar_estado_y_capacidades() -> void:
	var perfil := _npc.obtener_definicion_personaje()
	var estado := EstadoPersonajeNPC.new(perfil)
	estado.resultados_pruebas_dialogo[ID_PRUEBA] = false
	var datos: Dictionary = JSON.parse_string(JSON.stringify(estado.obtener_estado_persistente()))
	var otro := EstadoPersonajeNPC.new(perfil)
	_comprobar(otro.resultados_pruebas_dialogo.is_empty(), "Otra instancia con la misma definición no hereda el intento.")
	_comprobar(otro.restaurar_estado_persistente(datos) == &"" and otro.resultados_pruebas_dialogo.has(ID_PRUEBA) and not otro.resultados_pruebas_dialogo[ID_PRUEBA], "El fallo sobrevive a JSON y restauración.")
	for invalido in [null, [], {"": true}, {"id": 1}, {"id": "false"}, {1: true}]:
		var corrupto := datos.duplicate(true)
		corrupto["pruebas_dialogo"] = invalido
		_comprobar(otro.restaurar_estado_persistente(corrupto) == &"pruebas_dialogo_guardadas_invalidas" and otro.resultados_pruebas_dialogo == estado.resultados_pruebas_dialogo, "Rechazar memoria inválida sin mutación parcial: %s." % str(invalido))
	datos.erase("pruebas_dialogo")
	_comprobar(otro.restaurar_estado_persistente(datos) == &"" and otro.resultados_pruebas_dialogo.is_empty(), "Un snapshot anterior limpia la memoria del intento.")
	perfil.actitud_hacia_jugador_fija = true
	var cambio := ConsecuenciaDialogoNPC.new()
	cambio.puntos_actitud = 3
	_comprobar(cambio.aplicar(_npc, _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.catalogo_mensajes) == "" and _npc.obtener_puntos_actitud() == 0, "Las consecuencias respetan una actitud fija.")
	perfil.actitud_hacia_jugador_fija = false
	_npc.modificar_actitud_hacia_jugador(10)
	_comprobar(cambio.aplicar(_npc, _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.catalogo_mensajes) == "" and _npc.obtener_puntos_actitud() == 10, "Se respetan los límites de actitud sin registrar un cambio ficticio.")
	_npc.recibir_danio(99)
	_comprobar(cambio.validar(_npc, _escenario.ficha_jugador, _escenario.registro_conocimiento) != &"", "Un cadáver no recibe consecuencias de diálogo.")


func _finalizar() -> void:
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("ConsecuenciasDialogoNPC: %d comprobaciones correctas; configuración, ramas, efectos, intento único/repetible, K/C y migración." % _casos)
	get_tree().quit(0 if _fallos.is_empty() else 1)
