extends SceneTree

const RUTA := "user://prueba_campamento.json"
const ZONAS := ["res://scenes/Zona1/zona_1.tscn", "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"]
var _fallos: Array[String] = []
var _casos := 0


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _crear_escenario(ruta: String) -> Node:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.get_node("Zona").free()
	var zona = load(ruta).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	for intento in 200:
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	_comprobar(escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador, "Preparar zona: " + ruta)
	escenario.set_process(false)
	return escenario


func _snapshot(escenario: Node) -> Dictionary:
	var snapshot: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, escenario.obtener_id_zona(), escenario.ficha_jugador, escenario.registro_conocimiento, escenario.gestor_rondas)
	if snapshot.is_empty():
		_fallos.append("El snapshot del fixture debe ser válido: %s" % escenario.obtener_id_zona())
	return snapshot


func _ejecutar() -> void:
	for zona in ZONAS:
		var escenario := await _crear_escenario(zona)
		_probar_bloqueos(escenario)
		_preparar_mundo_modificado(escenario)
		await _probar_visita(escenario)
		await _probar_descanso_y_archivo(escenario, zona)
		escenario.queue_free()
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA + ".invalida"))
	for fallo in _fallos:
		push_error(fallo)
	print("Campamento: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _preparar_mundo_modificado(escenario: Node) -> void:
	var ficha: Ficha = escenario.ficha_jugador
	var coord := ficha.coordenada_mapa
	for lejana: Vector2i in escenario.tablero.datos:
		if escenario.tablero.datos[lejana].visibilidad == Celda.EstadoVisibilidad.OCULTO:
			escenario.tablero.datos[lejana].visibilidad = Celda.EstadoVisibilidad.EXPLORADO
			break
	var item := ItemSuelo.new(ItemInstancia.new(&"campamento_piedra", load("res://assets/items/piedra/piedra.tres"), 2))
	_comprobar(escenario.tablero.registrar_item_suelo(coord, item), "Preparar objeto en suelo.")
	var superficie = load("res://scenes/efectos_superficie/HumoVeneno.tscn").instantiate()
	superficie.configurar_id_instancia(&"campamento_humo")
	escenario.zona_actual.get_node("EfectosSuperficie").add_child(superficie)
	_comprobar(escenario.tablero.registrar_efecto_superficie(coord, superficie), "Preparar superficie persistente.")
	superficie.consumir_turno_superficie()
	for entidad in escenario.tablero.interactuables_por_id.values():
		if entidad is PuertaInteractuable and not entidad.bloqueada:
			entidad.abierta = not entidad.abierta
			break
	for entidad in escenario.tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC:
			entidad.recibir_danio(999)
			break
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"identidad"
	fragmento.id_mensaje = &"examen.prueba"
	fragmento.se_recuerda = true
	var fragmentos: Array[FragmentoInformacion] = [fragmento]
	escenario.registro_conocimiento.registrar_descubrimientos(ficha.id_observador, &"campamento_recuerdo", fragmentos)
	escenario._actualizar_luz_al_cargar()


func _probar_bloqueos(escenario: Node) -> void:
	var antes := _snapshot(escenario)
	escenario.en_combate = true
	_comprobar(escenario.entrar_campamento() == &"campamento_en_combate", "Bloquear en combate.")
	escenario.en_combate = false
	escenario.ficha_jugador.movimiento.esta_moviendose = true
	_comprobar(escenario.entrar_campamento() == &"partida_jugador_en_movimiento", "Bloquear durante movimiento del jugador.")
	escenario.ficha_jugador.movimiento.esta_moviendose = false
	for entidad in escenario.tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC:
			entidad.movimiento.esta_moviendose = true
			_comprobar(escenario.entrar_campamento() == &"partida_npc_en_movimiento", "Bloquear durante movimiento NPC.")
			entidad.movimiento.esta_moviendose = false
			break
	for panel in [escenario.menu_contextual, escenario.panel_resultado_accion, escenario.panel_examen_ilustrado, escenario.panel_ficha_npc, escenario.panel_inventario_cofre]:
		panel.show()
		_comprobar(escenario.entrar_campamento() == &"partida_interaccion_activa", "Bloquear modal " + panel.name)
		panel.hide()
	escenario.dialogo_npc_activo = true
	_comprobar(escenario.entrar_campamento() == &"partida_interaccion_activa", "Bloquear diálogo NPC.")
	escenario.dialogo_npc_activo = false
	escenario._dialogos_camara.append(load("res://dialogues/my_dialogue.dialogue"))
	_comprobar(escenario.entrar_campamento() == &"partida_interaccion_activa", "Bloquear otros diálogos.")
	escenario._dialogos_camara.clear()
	escenario.lanzamiento_en_vuelo = true
	_comprobar(escenario.entrar_campamento() == &"partida_interaccion_activa", "Bloquear lanzamiento en vuelo.")
	escenario.lanzamiento_en_vuelo = false
	var reentrada: Array[StringName] = []
	var observar := func(_contexto): reentrada.append(escenario.entrar_campamento())
	escenario.gestor_acciones.accion_iniciada.connect(observar)
	escenario.gestor_acciones.procesar_accion(ContextoAccion.new(TiposInteraccion.TipoAccion.EXAMINAR))
	escenario.gestor_acciones.accion_iniciada.disconnect(observar)
	_comprobar(reentrada == [&"campamento_accion_en_curso"] and escenario._acciones_en_resolucion == 0, "Una acción real bloquea reentrada y libera el bloqueo al finalizar.")
	_comprobar(_snapshot(escenario) == antes and not is_instance_valid(escenario.campamento), "Intentos bloqueados conservan el mundo y los recursos.")
	for entidad in escenario.tablero.interactuables_por_id.values():
		if entidad is PersonajeNPC and entidad.puede_actuar() and entidad.obtener_definicion_personaje().puede_combatir:
			_comprobar(escenario._iniciar_combate(entidad), "Preparar encuentro real.")
			var encuentro := _snapshot(escenario)
			_comprobar(escenario.entrar_campamento() == &"campamento_en_combate" and _snapshot(escenario) == encuentro, "Bloquear conserva iniciativa, recursos y bandos del encuentro real.")
			escenario._terminar_combate(false)
			break


func _probar_visita(escenario: Node) -> void:
	var antes := _snapshot(escenario)
	var mundo: Node = escenario.zona_actual
	var ficha: Ficha = escenario.ficha_jugador
	var posicion := ficha.global_position
	var niebla := _niebla(escenario)
	var revision: int = escenario.gestor_vision.revision_vision
	var reloj: float = escenario._tiempo_exploracion_npc
	var modo: Node.ProcessMode = escenario.process_mode
	var ficha_visible := ficha.visible
	for visita in 3:
		_comprobar(escenario.entrar_campamento() == &"", "Entrar sin límite de visitas.")
		_comprobar(escenario.process_mode == Node.PROCESS_MODE_DISABLED and escenario.campamento.can_process(), "Mundo suspendido y campamento activo.")
		await create_timer(0.1).timeout
		_comprobar(_snapshot(escenario) == antes and _niebla(escenario) == niebla and escenario._tiempo_exploracion_npc == reloj, "Visitar no consume ni avanza estados, superficies, NPC o conocimiento.")
		_comprobar(escenario.salir_campamento() == &"", "Regresar sin descansar.")
		await process_frame
		_comprobar(escenario.zona_actual == mundo and escenario.ficha_jugador == ficha and ficha.global_position == posicion and ficha.visible == ficha_visible and escenario.process_mode == modo and escenario.gestor_vision.revision_vision == revision, "Regresar conserva nodos, posición, visibilidad, proceso y percepción.")


func _probar_descanso_y_archivo(escenario: Node, zona: String) -> void:
	var ficha: Ficha = escenario.ficha_jugador
	ficha.raciones = 3
	ficha.pv_actual -= 2
	ficha.energia_actual = 37
	ficha.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	ficha.aplicar_o_renovar_estado(&"veneno", 1.0, 2, 1)
	_comprobar(escenario.entrar_campamento() == &"", "Visitar con PV/energía gastados y estado activo.")
	var campamento = escenario.campamento
	for intento in 200:
		await process_frame
		if is_instance_valid(campamento.escenario_descanso) and campamento.escenario_descanso.hud.ficha != null:
			break
	_comprobar(is_instance_valid(campamento.escenario_descanso) and campamento.escenario_descanso.zona_actual.scene_file_path == "res://scenes/DescansoCuevas/DescansoCuevas.tscn", "Campamento carga DescansoCuevas como escenario jugable.")
	var fichas_en_descanso: Array = campamento.escenario_descanso.zona_actual.get_children().filter(func(nodo): return nodo is Ficha)
	_comprobar(fichas_en_descanso.size() == 1 and not campamento.escenario_descanso.ficha_jugador.get_node("Sprite2D").visible and campamento.escenario_descanso.ficha_jugador.sprite_render.visible, "DescansoCuevas muestra una sola ficha con el modelo direccional activo.")
	if is_instance_valid(campamento.escenario_descanso.ficha_jugador):
		_comprobar(campamento.escenario_descanso.ficha_jugador.pv_actual == ficha.pv_actual and campamento.escenario_descanso.ficha_jugador.energia_actual == ficha.energia_actual, "Ficha del escenario de descanso refleja los recursos de origen.")
	var zona_descanso = campamento.escenario_descanso
	var mundos_modelos: Array[World3D] = []
	for vista in ["KnightViewPort/KnightSubViewport", "WizardViewPort/WizardSubViewport", "ThiefViewPort/ThiefSubViewport"]:
		for instancia in [escenario, zona_descanso]:
			var mundo_modelo: World3D = instancia.get_node(vista).find_world_3d()
			_comprobar(not mundos_modelos.has(mundo_modelo), "La captura de %s usa un mundo 3D aislado del origen y los demás modelos." % vista)
			mundos_modelos.append(mundo_modelo)
	zona_descanso.estado_seleccion_objetivos.iniciar(campamento.fogata.coordenada_mapa, [campamento.fogata])
	zona_descanso._abrir_menu_contextual(Vector2(320, 240))
	var textos_menu: Array[String] = []
	for boton in zona_descanso.menu_contextual.obtener_botones():
		textos_menu.append(boton.text)
	_comprobar(zona_descanso.menu_contextual.visible and textos_menu.any(func(texto): return texto.begins_with("Descansar")), "La fogata despliega Descansar desde su menú contextual.")
	_comprobar(textos_menu.any(func(texto): return texto.begins_with("Volver")) and textos_menu.any(func(texto): return texto.begins_with("Guardar")) and textos_menu.any(func(texto): return texto.begins_with("Cargar")), "La fogata reúne salida y archivos en el mismo menú.")
	_comprobar(textos_menu.any(func(texto): return texto.contains("Apagar")) or textos_menu.any(func(texto): return texto.contains("Encender")), "La fogata conserva su acción de luz.")
	zona_descanso._cerrar_menu_contextual()
	var antes := _snapshot(escenario)
	campamento.solicitar_descanso()
	_comprobar(_snapshot(escenario) == antes, "Abrir confirmación no gasta ni cura.")
	_comprobar(escenario.guardar_partida(RUTA) == &"partida_interaccion_activa" and escenario.cargar_partida(RUTA) == &"partida_interaccion_activa" and escenario.salir_campamento() == &"partida_interaccion_activa", "Confirmación bloquea guardar, cargar y regresar.")
	campamento.escenario_descanso.menu_contextual.cancelado.emit()
	campamento.escenario_descanso.menu_contextual.ocultar()
	_comprobar(campamento.confirmar_descanso() == &"descanso_sin_confirmacion" and _snapshot(escenario) == antes, "Cancelar no gasta ni permite una confirmación tardía.")
	campamento.solicitar_descanso()
	_comprobar(campamento.confirmar_descanso() == &"" and ficha.raciones == 2 and ficha.pv_actual == ficha.pv_max and ficha.energia_actual == ficha.energia_maxima, "Confirmar consume exactamente una ración y repone PV y energía completos.")
	_comprobar(campamento.escenario_descanso.ficha_jugador.pv_actual == ficha.pv_actual and campamento.escenario_descanso.ficha_jugador.raciones == 2, "El descanso actualiza también la ficha visible en DescansoCuevas.")
	_comprobar(campamento.confirmar_descanso() == &"descanso_sin_confirmacion" and ficha.raciones == 2, "Confirmar dos veces no cobra dos veces.")
	_comprobar(ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0 and ficha.obtener_estado(&"veneno").ticks_pendientes == 1, "Descansar conserva recursos por turno y estados.")
	var resultado_guardar: StringName = escenario.guardar_partida(RUTA)
	_comprobar(resultado_guardar == &"", "Guardar campamento con mundo de origen: %s." % resultado_guardar)
	if resultado_guardar != &"":
		return
	var guardado := _snapshot(escenario)
	var archivo: Dictionary = escenario.persistencia_partida.archivos.cargar(RUTA)
	_comprobar(archivo.en_campamento and archivo.escena_zona == zona and archivo.zona_id == String(escenario.obtener_id_zona()), "Archivo identifica origen real y estancia en campamento.")
	escenario.salir_campamento()
	await process_frame
	ficha.raciones = 0
	ficha.energia_actual = 5
	_comprobar(escenario.cargar_partida(RUTA) == &"" and is_instance_valid(escenario.campamento) and _snapshot(escenario) == guardado, "Cargar desde exploración vuelve al campamento sin repetir el descanso.")
	_comprobar(escenario.cargar_partida(RUTA) == &"" and _snapshot(escenario) == guardado, "Cargar desde campamento es idempotente.")
	var exploracion := archivo.duplicate(true)
	exploracion.en_campamento = false
	escenario.persistencia_partida.archivos.guardar(RUTA + ".invalida", exploracion)
	_comprobar(escenario.cargar_partida(RUTA + ".invalida") == &"" and not is_instance_valid(escenario.campamento) and _snapshot(escenario) == guardado, "Cargar exploración desde campamento devuelve al mundo sin perder estado.")
	await process_frame
	_comprobar(escenario.cargar_partida(RUTA) == &"", "Reabrir campamento guardado.")
	var nuevo := await _crear_escenario(zona)
	_comprobar(nuevo.cargar_partida(RUTA) == &"" and is_instance_valid(nuevo.campamento) and _snapshot(nuevo) == guardado, "Nueva instancia recupera campamento y estado completo del origen.")
	_comprobar(_niebla(nuevo) == _niebla(escenario), "Nueva instancia conserva también niebla y terreno explorado lejano.")
	_comprobar(nuevo.salir_campamento() == &"" and nuevo.ficha_jugador.coordenada_mapa == ficha.coordenada_mapa, "Nueva instancia regresa al punto guardado.")
	nuevo.queue_free()
	await process_frame
	for valor in [-1, 1.5, "3", null]:
		var corrupto := archivo.duplicate(true)
		corrupto.ficha.raciones = valor
		_probar_rechazo(escenario, corrupto, guardado, "raciones inválidas")
	var corrupto := archivo.duplicate(true)
	corrupto.en_campamento = "sí"
	_probar_rechazo(escenario, corrupto, guardado, "campamento inválido")
	for explorado in [null, [[999999, 999999]], [[1.5, 0]], [[0]], [[0, 0], [0, 0]]]:
		corrupto = archivo.duplicate(true)
		corrupto.celdas_exploradas = explorado
		_probar_rechazo(escenario, corrupto, guardado, "exploración inválida")
	corrupto = archivo.duplicate(true)
	corrupto.escena_zona = ZONAS[1] if zona == ZONAS[0] else ZONAS[0]
	_probar_rechazo(escenario, corrupto, guardado, "zona distinta")
	ficha.raciones = 0
	var sin_provisiones := _snapshot(escenario)
	escenario.campamento.solicitar_descanso()
	_comprobar(not escenario.campamento.descanso_pendiente and ficha.descansar_en_campamento() == &"descanso_sin_provisiones" and _snapshot(escenario) == sin_provisiones, "Sin provisiones no descansa ni cambia estado.")
	escenario.salir_campamento()
	await process_frame
	_comprobar(escenario.entrar_campamento() == &"" and escenario.salir_campamento() == &"", "Cero raciones permite visitar y regresar.")
	await process_frame
	var anterior := archivo.duplicate(true)
	anterior.erase("en_campamento")
	anterior.erase("escena_zona")
	anterior.erase("celdas_exploradas")
	anterior.ficha.erase("raciones")
	anterior.zona_id = "zona1"
	escenario.persistencia_partida.archivos.guardar(RUTA, anterior)
	_comprobar(escenario.cargar_partida(RUTA) == &"" and ficha.raciones == 3 and not is_instance_valid(escenario.campamento), "Migrar guardado anterior: tres raciones iniciales, origen validado y exploración.")


func _probar_rechazo(escenario: Node, corrupto: Dictionary, antes: Dictionary, caso: String) -> void:
	escenario.persistencia_partida.archivos.guardar(RUTA + ".invalida", corrupto)
	_comprobar(escenario.cargar_partida(RUTA + ".invalida") != &"" and _snapshot(escenario) == antes and is_instance_valid(escenario.campamento), "Rechazo atómico: " + caso)


func _niebla(escenario: Node) -> Dictionary:
	var resultado := {}
	for coord: Vector2i in escenario.tablero.datos:
		resultado[coord] = escenario.tablero.datos[coord].visibilidad
	return resultado


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
