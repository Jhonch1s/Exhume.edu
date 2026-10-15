extends Node

const PRUEBA_ACTITUD := preload("res://tests/interacciones/prueba_actitud_npc.gd")
const NEUTRAL := DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
const AMISTOSA := DefinicionPersonaje.ActitudInicialJugador.AMISTOSA
const HOSTIL := DefinicionPersonaje.ActitudInicialJugador.HOSTIL
const FUERA := GestorRondas.Bando.NEUTRAL
const ALIADO := GestorRondas.Bando.JUGADOR
const OPONENTE := GestorRondas.Bando.OPONENTE
const RUTA := "user://prueba_facciones_npc_automatica.json"
const POSICIONES := [Vector2i(100, 100), Vector2i(100, 102), Vector2i(98, 101), Vector2i(112, 100), Vector2i(99, 102)]
var _fallos: Array[String] = []
var _casos := 0
var _escena: Node2D
var _escenario: Node2D
var _npcs: Array[PersonajeNPC] = []
var _perfiles: Array[DefinicionPersonaje] = []


func _ready() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_escena = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	_escenario = _escena.get_node("Escenario")
	_escenario.set_script(PRUEBA_ACTITUD.EscenarioSinRender)
	add_child(_escena)
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if _escena.get("_enemigos").size() == 5:
			break
	_comprobar(_escena.get("_enemigos").size() == 5, "La escena manual debe crear sus cinco NPC.")
	if _escena.get("_enemigos").size() != 5:
		_finalizar()
		return
	_escenario.set_process(false)
	_npcs.assign(_escena.get("_enemigos"))
	for npc in _npcs:
		_perfiles.append(npc.obtener_definicion_personaje().duplicate(true))
	# Suelo propio y despejado para que las pruebas no dependan de la edición de Zona1.
	for x in range(94, 121):
		for y in range(94, 109):
			_escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	_escenario.pathfinding.inicializar(_escenario.tablero.datos)
	_probar_agresiones_y_testigos()
	_probar_incorporacion_y_memoria()
	_probar_persistencia()
	_probar_carga_desde_otro_encuentro()
	await _probar_turno_aliado()
	_probar_xp()
	_probar_vision_npc()
	_probar_muerte_y_cierre()
	_escenario._terminar_combate(false)
	_escena.queue_free()
	await get_tree().process_frame
	_finalizar()


func _reiniciar() -> void:
	_escenario.ejecutar_turnos = false
	_escenario._terminar_combate(false)
	for celda: Celda in _escenario.tablero.datos.values():
		if celda.zona == &"piso_vacio":
			celda.bloquea_vision = false
	for indice in range(_npcs.size()):
		var npc := _npcs[indice]
		npc.definicion = _perfiles[indice].duplicate(true)
		npc.estado_personaje = null
		npc.bando_encuentro = FUERA
		npc._inventario = null
		_mover_npc(npc, POSICIONES[indice])
		npc._asegurar_estado()
		npc.estado_personaje.coordenada_origen = POSICIONES[indice]
	_mover_jugador(Vector2i(99, 100))
	_escenario.ficha_jugador.iniciar_turno()


func _mover_jugador(coordenada: Vector2i) -> void:
	var ficha: Ficha = _escenario.ficha_jugador
	_escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(coordenada, _escenario.tablero.capa_referencia)
	_escenario.tablero.ocupar_celda(coordenada, ficha)


func _mover_npc(npc: PersonajeNPC, coordenada: Vector2i) -> void:
	_comprobar(_escenario.tablero.reubicar_interactuable(npc, coordenada), "Reubicar NPC en suelo propio.")
	npc.actualizar_posicion_visual()


func _configurar(npc: PersonajeNPC, actitud: int, fija: bool = false) -> void:
	npc.obtener_definicion_personaje().actitud_inicial_jugador = actitud
	npc.obtener_definicion_personaje().actitud_hacia_jugador_fija = fija
	npc.estado_personaje = null
	npc._asegurar_estado()
	npc.estado_personaje.coordenada_origen = npc.coordenada_mapa


func _activar_turno(actor: Object) -> void:
	var rondas: Dictionary = _escenario.gestor_rondas.obtener_estado_persistente()
	rondas["actor_activo_id"] = String(actor.obtener_id_actor())
	_comprobar(_escenario.gestor_rondas.restaurar_estado_persistente(rondas) == &"", "Preparar actor activo sin volver a tirar.")
	actor.iniciar_turno()


func _contexto_ataque(npc: PersonajeNPC) -> ContextoAccion:
	for opcion in npc.obtener_opciones_accion(_escenario.ficha_jugador):
		if opcion.id == &"ataque_basico":
			return _escenario.constructor_contexto_accion.construir_desde_opcion(opcion, _escenario.ficha_jugador, _escenario.ficha_jugador.coordenada_mapa, npc.coordenada_mapa) as ContextoAccion
	return null


func _atacar(dados: Array) -> ResultadoAccion:
	_comprobar(_escenario._iniciar_combate(_npcs[0]), "Abrir defensa propia del objetivo.")
	_activar_turno(_escenario.ficha_jugador)
	var prueba: Node = PRUEBA_ACTITUD.new()
	_npcs[0].motor_dados = MotorDados.new(prueba._rng_para(dados))
	prueba.free()
	return _escenario._procesar_accion_contextual(_contexto_ataque(_npcs[0]))


func _probar_agresiones_y_testigos() -> void:
	_reiniciar()
	_comprobar(_npcs[0].comparte_faccion(_npcs[1]) and not _npcs[2].comparte_faccion(_npcs[4]), "Sólo un ID no vacío compartido establece facción.")
	_npcs[4].obtener_definicion_personaje().faccion_id = &"guardia_prueba"
	_mover_jugador(Vector2i(94, 100))
	var resultado: ResultadoAccion = _escenario._procesar_accion_contextual(_contexto_ataque(_npcs[0]))
	_comprobar(resultado.motivo == &"fuera_de_alcance" and not _escenario.en_combate and _npcs[1].bando_encuentro == FUERA, "Un bloqueo de alcance no convoca testigos.")
	_mover_jugador(Vector2i(99, 100))
	_escenario.ficha_jugador.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	resultado = _escenario._procesar_accion_contextual(_contexto_ataque(_npcs[0]))
	_comprobar(resultado.estado == TiposInteraccion.EstadoResolucion.BLOQUEO and not _escenario.en_combate, "Sin acción no abre encuentro ni auxilio.")
	for dados in [[6], [1, 1], [1, 6]]:
		_reiniciar()
		_npcs[4].obtener_definicion_personaje().faccion_id = &"guardia_prueba"
		resultado = _atacar(dados)
		_comprobar(resultado.tirada != null and resultado.exitosa and _npcs[0].obtener_puntos_actitud() == -2, "Fallo, esquiva y daño penalizan sólo al agredido.")
		_comprobar(_npcs[1].bando_encuentro == OPONENTE and _npcs[1].obtener_puntos_actitud() == 0 and _npcs[1].obtener_actitud_hacia_jugador() == NEUTRAL, "El testigo fijo defiende sin cambiar actitud.")
		_comprobar(_npcs[2].bando_encuentro == FUERA and _npcs[3].bando_encuentro == FUERA and _npcs[4].bando_encuentro == FUERA, "Amistoso, miembro lejano y Trompo no son convocados.")
		_comprobar(_escenario.gestor_rondas.obtener_ids_ordenados().back() == _npcs[1].obtener_id_actor(), "El testigo entra al final de la ronda.")
		var puntos := _npcs[0].obtener_puntos_actitud()
		resultado = _escenario._procesar_accion_contextual(_contexto_ataque(_npcs[0]))
		_comprobar(resultado.estado == TiposInteraccion.EstadoResolucion.BLOQUEO and _npcs[0].obtener_puntos_actitud() == puntos, "Reintentar sin recursos no repite la agresión.")
	_reiniciar()
	_configurar(_npcs[1], AMISTOSA)
	_atacar([6])
	_comprobar(_npcs[1].bando_encuentro == OPONENTE and _npcs[1].obtener_puntos_actitud() == 3, "Auxiliar al compañero agredido precede a ser amistoso con el jugador.")
	_reiniciar()
	_npcs[1].obtener_definicion_personaje().radio_agro = 2
	_comprobar(_npcs[1].puede_ver_coordenada(_npcs[0].coordenada_mapa, _escenario.validador_espacial) and not _npcs[1].puede_ver_coordenada(_escenario.ficha_jugador.coordenada_mapa, _escenario.validador_espacial), "Testigo que ve sólo al agredido.")
	_atacar([6])
	_comprobar(_npcs[1].bando_encuentro == FUERA, "Al resolver la agresión exige ver ambas partes.")
	_escenario._incorporar_npc_al_combate()
	_comprobar(_npcs[1].bando_encuentro == OPONENTE, "Más tarde basta percibir al compañero defendido dentro del alcance propio.")
	_reiniciar()
	_escenario.tablero.datos[Vector2i(100, 101)].bloquea_vision = true
	_atacar([6])
	_escenario._incorporar_npc_al_combate()
	_comprobar(_npcs[1].bando_encuentro == FUERA, "Una pared impide auxilio inmediato y posterior.")
	_reiniciar()
	_npcs[1].recibir_danio(99)
	_atacar([6])
	_comprobar(_npcs[1].bando_encuentro == FUERA, "Un cadáver de la facción no responde.")


func _probar_incorporacion_y_memoria() -> void:
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_configurar(_npcs[1], HOSTIL)
	_configurar(_npcs[3], HOSTIL)
	_npcs[1].obtener_definicion_personaje().faccion_id = &""
	_mover_npc(_npcs[3], Vector2i(107, 102))
	_npcs[0].obtener_definicion_personaje().radio_agro = 1
	_npcs[1].obtener_definicion_personaje().radio_agro = 1
	_comprobar(_escenario._iniciar_combate(_npcs[0]), "Inicio aislado para probar incorporación sin cadena.")
	_npcs[1].obtener_definicion_personaje().radio_agro = 7
	_npcs[3].obtener_definicion_personaje().radio_agro = 7
	var turno: Object = _escenario.gestor_rondas.actor_activo
	var reservas: Dictionary = _escenario.ficha_jugador.obtener_estado_persistente()["recursos_turno"]
	_escenario._incorporar_npc_al_combate()
	_comprobar(_npcs[1].bando_encuentro == OPONENTE and _npcs[3].bando_encuentro == FUERA, "La misma evaluación no usa un recién incorporado para reclutar a otro.")
	_comprobar(_escenario.gestor_rondas.actor_activo == turno and _escenario.ficha_jugador.obtener_estado_persistente()["recursos_turno"] == reservas and _escenario.gestor_rondas.obtener_iniciativa_ronda(_npcs[1].id_instancia).is_empty(), "Incorporar no cambia turno, recursos ni iniciativa; el nuevo aún no tiró.")
	_escenario._incorporar_npc_al_combate()
	_comprobar(_npcs[3].bando_encuentro == OPONENTE, "Una evaluación posterior puede percibir al participante incorporado.")
	var ronda: int = _escenario.gestor_rondas.ronda_actual
	for _turno in range(10):
		_escenario._finalizar_turno_combate()
		if _escenario.gestor_rondas.ronda_actual > ronda:
			break
	_comprobar(_escenario.gestor_rondas.ronda_actual == ronda + 1 and not _escenario.gestor_rondas.obtener_iniciativa_ronda(_npcs[3].id_instancia).is_empty(), "Los incorporados tiran iniciativa al comenzar la siguiente ronda.")
	_reiniciar()
	_atacar([6])
	_npcs[0].obtener_definicion_personaje().radio_agro = 1
	_npcs[1].obtener_definicion_personaje().radio_agro = 0
	_comprobar(_escenario._actualizar_memoria_combate(), "Un detector mantiene el agro del grupo.")
	var recuerdo: Variant = _npcs[1].obtener_ultima_posicion_conocida()
	_comprobar(recuerdo == _escenario.ficha_jugador.coordenada_mapa, "El compañero ciego recibe sólo la posición observada por su aliado.")
	_mover_jugador(Vector2i(98, 100))
	_comprobar(not _escenario._actualizar_memoria_combate() and _npcs[1].obtener_ultima_posicion_conocida() == recuerdo, "Sin detectores no obtiene la nueva posición oculta.")
	_comprobar(_escenario._resolver_perdida_agro() and not _escenario.en_combate and _npcs[1].bando_encuentro == FUERA and _npcs[1].obtener_ultima_posicion_conocida() == null, "La huida limpia defensa temporal y memoria del neutral.")
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	_escenario._actualizar_memoria_combate()
	_comprobar(_npcs[2].bando_encuentro == ALIADO and not _npcs[2].se_opone_al_jugador(), "El amistoso ayuda ante amenaza hostil.")
	_comprobar(_npcs[2].obtener_id_objetivo_recordado() == _npcs[0].obtener_id_actor() and _npcs[2].obtener_ultima_posicion_conocida() == _npcs[0].coordenada_mapa, "La memoria aliada apunta al enemigo, no a la posición del jugador.")
	var recuerdo_oponente: Variant = _npcs[0].obtener_ultima_posicion_conocida()
	_npcs[0].obtener_definicion_personaje().radio_agro = 0
	_mover_jugador(Vector2i(98, 100))
	_escenario._actualizar_memoria_combate()
	_comprobar(_npcs[0].obtener_ultima_posicion_conocida() == recuerdo_oponente, "Lo observado por un aliado del jugador no se filtra al bando oponente.")
	_npcs[2].modificar_actitud_hacia_jugador(-10)
	_comprobar(_npcs[2].bando_encuentro == ALIADO and not _npcs[2].se_opone_al_jugador(), "Cambiar puntos no cambia de lado durante el encuentro.")
	var prohibido := AccionAtaqueNPC.new(_escenario.ficha_jugador, _escenario.gestor_rondas)
	_comprobar(prohibido.validar_accion(prohibido.construir_contexto(_npcs[2])) == &"npc_no_hostil", "Un aliado no puede usar ataque automático contra su propio bando.")
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_mover_npc(_npcs[2], Vector2i(99, 99))
	_escenario._iniciar_combate(_npcs[0], false)
	_activar_turno(_escenario.ficha_jugador)
	var agresion: ResultadoAccion = _escenario._procesar_accion_contextual(_contexto_ataque(_npcs[2]))
	_comprobar(agresion.tirada != null and _npcs[2].bando_encuentro == OPONENTE and _escenario.gestor_rondas.obtener_bando(_npcs[2]) == OPONENTE and _npcs[2].obtener_puntos_actitud() == 1, "Agredir a un aliado establece su defensa propia antes que su relación amistosa.")


func _probar_persistencia() -> void:
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	_escenario._actualizar_memoria_combate()
	_activar_turno(_escenario.ficha_jugador)
	_npcs[2].consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	var rondas: Dictionary = _escenario.gestor_rondas.obtener_estado_persistente()
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar bandos, objetivos e iniciativa.")
	for _carga in range(2):
		_npcs[2].bando_encuentro = OPONENTE
		_npcs[2].modificar_actitud_hacia_jugador(-2)
		_comprobar(_escenario.cargar_partida(RUTA) == &"" and _npcs[2].bando_encuentro == ALIADO and _npcs[2].obtener_puntos_actitud() == 3 and _npcs[2].obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0 and _escenario.gestor_rondas.obtener_estado_persistente() == rondas, "K/C repetida restaura bandos sin consecuencias ni recursos nuevos.")
	var snapshot: Dictionary = _escenario.persistencia_partida.crear_snapshot(_escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas)
	for invalido in [0, 3, -1, 1.5, true, "1", null]:
		var corrupto := snapshot.duplicate(true)
		corrupto["rondas"]["bandos"][String(_npcs[2].id_instancia)] = invalido
		_comprobar(_escenario.persistencia_partida.restaurar(corrupto, _escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas) != &"" and _npcs[2].bando_encuentro == ALIADO and _escenario.gestor_rondas.obtener_estado_persistente() == rondas, "Un bando inválido debe rechazarse sin mutar: %s." % str(invalido))
	for ids in [["desconocido"], [String(_npcs[0].id_instancia), String(_npcs[0].id_instancia)]]:
		var corrupto := snapshot.duplicate(true)
		corrupto["rondas"]["defendidos"] = ids
		_comprobar(_escenario.persistencia_partida.validar_restauracion(corrupto, _escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas) == &"bandos_guardados_invalidos", "Rechazar defendidos desconocidos o repetidos.")
	var corrupto := snapshot.duplicate(true)
	corrupto["rondas"]["bandos"][String(_escenario.ficha_jugador.obtener_id_actor())] = OPONENTE
	_comprobar(_escenario.persistencia_partida.validar_restauracion(corrupto, _escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas) == &"bandos_guardados_invalidos", "El jugador no puede migrar al bando contrario.")
	for entrada: Dictionary in corrupto["interactuables"]:
		if entrada["id"] == String(_npcs[2].id_instancia):
			entrada["estado"]["objetivo_recordado_id"] = "desconocido"
	_comprobar(_escenario.persistencia_partida.validar_restauracion(corrupto, _escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas) == &"memoria_npc_guardada_invalida", "No se restauran referencias de objetivo desconocidas.")
	var anterior := snapshot.duplicate(true)
	anterior["rondas"].erase("bandos")
	anterior["rondas"].erase("defendidos")
	for entrada: Dictionary in anterior["interactuables"]:
		entrada["estado"].erase("objetivo_recordado_id")
	_comprobar(_escenario.persistencia_partida.archivos.guardar(RUTA, anterior) == &"" and _escenario.cargar_partida(RUTA) == &"" and _npcs[2].bando_encuentro == OPONENTE and _npcs[0].bando_encuentro == OPONENTE and _npcs[2].obtener_puntos_actitud() == 3, "Un encuentro anterior interpreta todos sus NPC como oponentes sin cambiar puntos.")
	_escenario._terminar_combate(false)
	_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar exploración sin bandos transitorios.")
	_escenario._iniciar_combate(_npcs[0], false)
	_comprobar(_escenario.cargar_partida(RUTA) == &"" and not _escenario.en_combate and _npcs[2].bando_encuentro == FUERA, "Cargar exploración limpia ambos bandos del encuentro previo.")


func _probar_carga_desde_otro_encuentro() -> void:
	for fija in [false, true]:
		for actitud in [HOSTIL, NEUTRAL]:
			for bando in [ALIADO, OPONENTE]:
				_reiniciar()
				var npc := _npcs[0]
				_configurar(npc, actitud, fija)
				npc.recordar_posicion_jugador(Vector2i(96, 100))
				npc.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, 1)
				var guardado := npc.obtener_estado_persistente()
				_comprobar(_escenario.guardar_partida(RUTA) == &"", "Guardar exploración con memoria y recursos gastados.")
				_escenario._iniciar_combate(_npcs[1], false)
				_escenario._incorporar_con_bando(npc, bando)
				var vigente: Dictionary = _escenario.persistencia_partida.crear_snapshot(_escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas)
				var corrupto := vigente.duplicate(true)
				corrupto["memoria_narrativa"]["trompo_conocido"] = "invalido"
				_comprobar(_escenario.persistencia_partida.archivos.guardar(RUTA + ".invalida", corrupto) == &"", "Preparar archivo inválido para comprobar rechazo atómico.")
				_comprobar(_escenario.cargar_partida(RUTA + ".invalida") != &"" and _escenario.en_combate and npc.bando_encuentro == bando and _escenario.persistencia_partida.crear_snapshot(_escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas) == vigente, "Rechazar la carga conserva el encuentro y el estado completos.")
				_comprobar(_escenario.cargar_partida(RUTA) == &"" and not _escenario.en_combate and npc.bando_encuentro == FUERA and npc.obtener_estado_persistente() == guardado, "Cargar exploración desde otro bando conserva memoria y recursos, con actitud fija o dinámica.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA + ".invalida"))


func _probar_turno_aliado() -> void:
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_mover_npc(_npcs[2], Vector2i(100, 99))
	_escenario._iniciar_combate(_npcs[0], false)
	_escenario._actualizar_memoria_combate()
	_activar_turno(_npcs[2])
	var respuestas: Array[ResultadoAccion] = []
	var callback := func(contexto: ContextoAccion, resultado: ResultadoAccion):
		if contexto.id_accion == &"ataque_basico_npc" and contexto.actor == _npcs[2]:
			_comprobar(contexto.objetivo.objetivo == _npcs[0], "El turno real del aliado debe atacar al NPC enemigo.")
			respuestas.append(resultado)
	_escenario.gestor_acciones.accion_finalizada.connect(callback)
	_escenario.ejecutar_turnos = true
	_escenario._programar_turno_npc()
	for _espera in range(60):
		await get_tree().create_timer(0.05).timeout
		if not respuestas.is_empty():
			break
	_escenario.ejecutar_turnos = false
	_escenario.gestor_acciones.accion_finalizada.disconnect(callback)
	_comprobar(not respuestas.is_empty() and respuestas[0].exitosa and respuestas[0].tirada != null and _npcs[0].obtener_puntos_actitud() == -3 and _npcs[2].obtener_puntos_actitud() == 3, "El árbol y ataque reales funcionan entre NPC sin cambiar relación con el jugador.")
	_escenario._terminar_combate(false)
	await get_tree().create_timer(0.7).timeout


func _probar_muerte_y_cierre() -> void:
	_reiniciar()
	_configurar(_npcs[0], HOSTIL)
	_configurar(_npcs[1], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	_npcs[0].recibir_danio(99)
	_comprobar(not _escenario._resolver_fin_combate() and _npcs[2].bando_encuentro == ALIADO and _npcs[0].obtener_inventario().obtener_estado_persistente().size() == 1, "La muerte conserva el cuerpo y botín; otro oponente mantiene el encuentro.")
	_comprobar(_escenario.guardar_partida(RUTA) == &"" and _escenario.cargar_partida(RUTA) == &"" and _npcs[0].esta_muerto() and _npcs[0].curar(99) == 0, "K/C conserva cadáver con bandos activos y no lo revive.")
	var inventario := _npcs[0].obtener_inventario()
	var item: ItemInstancia = inventario.obtener_contenido()[0]
	_comprobar(inventario.transferir_a(_escenario.ficha_jugador.obtener_inventario(), item.id_instancia).exitosa and _escenario.guardar_partida(RUTA) == &"" and _escenario.cargar_partida(RUTA) == &"" and _npcs[0].obtener_inventario().obtener_contenido().is_empty(), "Recoger y cargar conserva el cadáver vacío sin duplicar botín.")
	_npcs[1].recibir_danio(99)
	_comprobar(_escenario._resolver_fin_combate() and not _escenario.en_combate and _npcs[2].bando_encuentro == FUERA, "Derrotar al último oponente termina aunque queden aliados vivos.")


func _probar_xp() -> void:
	_reiniciar()
	var ficha: Ficha = _escenario.ficha_jugador
	ficha.experiencia_acumulada = 0
	_npcs[0].vida_actual = 1
	var resultado := _atacar([1, 6])
	_comprobar(resultado.exitosa and _npcs[0].esta_muerto() and ficha.experiencia_acumulada == 50, "Un golpe mortal del jugador entrega la recompensa completa declarada.")
	_comprobar(ficha.nivel == 1 and _escenario.hud.experiencia_barra.value == 50.0 and _escenario.hud.experiencia_barra.max_value == 100.0, "La barra muestra XP real sin subir nivel antes de implementar progresión.")
	_npcs[0].recibir_danio(99, ficha)
	_comprobar(ficha.experiencia_acumulada == 50, "Dañar otra vez el cadáver no duplica XP.")
	var guardado: StringName = _escenario.guardar_partida(RUTA)
	var carga: StringName = _escenario.cargar_partida(RUTA) if guardado == &"" else guardado
	_comprobar(guardado == &"" and carga == &"" and ficha.experiencia_acumulada == 50 and _npcs[0].esta_muerto(), "K/C conserva XP y cadáver sin entregar otra recompensa: guardar=%s, cargar=%s, XP=%d." % [guardado, carga, ficha.experiencia_acumulada])
	_npcs[1].recibir_danio(99, ficha)
	_comprobar(ficha.experiencia_acumulada == 100 and ficha.nivel == 1 and _escenario.hud.experiencia_barra.value == 100.0, "Cada baja elegible da XP íntegra; alcanzar el umbral no implementa niveles.")
	_reiniciar()
	ficha.experiencia_acumulada = 0
	_configurar(_npcs[0], HOSTIL)
	_comprobar(_escenario._iniciar_combate(_npcs[0], false) and _npcs[2].bando_encuentro == ALIADO, "El amistoso participa en el encuentro para probar su baja.")
	_npcs[0].recibir_danio(99, _npcs[2])
	_comprobar(ficha.experiencia_acumulada == 50, "La baja de un aliado del encuentro concede toda la XP al jugador.")
	_reiniciar()
	ficha.experiencia_acumulada = 0
	_configurar(_npcs[0], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	_npcs[2].recibir_danio(99, _npcs[0])
	_comprobar(ficha.experiencia_acumulada == 0, "La muerte de un aliado a manos de un oponente no concede XP.")
	_npcs[0].recibir_danio(99)
	_comprobar(ficha.experiencia_acumulada == 50, "Un oponente muerto sin responsable durante el encuentro concede XP.")
	_reiniciar()
	ficha.experiencia_acumulada = 0
	_configurar(_npcs[0], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	_npcs[0].obtener_definicion_personaje().experiencia_recompensa_derrota = 0
	_npcs[0].recibir_danio(99, ficha)
	_comprobar(ficha.experiencia_acumulada == 0, "Una recompensa declarada de cero no crea XP.")
	_reiniciar()
	ficha.experiencia_acumulada = 0
	_configurar(_npcs[0], HOSTIL)
	_escenario._iniciar_combate(_npcs[0], false)
	var antes_de_matar: StringName = _escenario.guardar_partida(RUTA)
	_npcs[0].recibir_danio(99, ficha)
	var ganada := ficha.experiencia_acumulada == 50
	var volver_atras: StringName = _escenario.cargar_partida(RUTA) if antes_de_matar == &"" else antes_de_matar
	_comprobar(ganada and volver_atras == &"" and not _npcs[0].esta_muerto() and ficha.experiencia_acumulada == 0, "Cargar antes de la baja rebobina cadáver y XP juntos.")
	_npcs[0].recibir_danio(99, ficha)
	_comprobar(ficha.experiencia_acumulada == 50, "Tras volver a un momento vivo, una nueva baja entrega XP una sola vez.")
	var ficha_antigua: Dictionary = ficha.obtener_estado_persistente()
	ficha_antigua.erase("experiencia_acumulada")
	_comprobar(ficha.restaurar_estado_persistente(ficha_antigua) == &"" and ficha.experiencia_acumulada == 0, "Una ficha anterior sin campo XP carga con cero y no cobra cadáveres antiguos.")


func _probar_vision_npc() -> void:
	_reiniciar()
	var capa: CapaVisionNPC = _escenario.capa_vision_npc
	var guardia := _npcs[0].obtener_id_actor()
	var amistoso := _npcs[2].obtener_id_actor()
	var lejano := _npcs[3].obtener_id_actor()
	_escenario.tablero.obtener_celda(_npcs[3].coordenada_mapa).visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	var tecla_v := InputEventKey.new()
	tecla_v.keycode = KEY_V
	tecla_v.pressed = true
	_escenario._unhandled_input(tecla_v)
	_comprobar(capa.visible and capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == guardia and c["coordenada"] == Vector2i(100, 102) and c["color"] == CapaVisionNPC.COLOR_NEUTRAL), "V muestra casillas visibles del neutral en gris.")
	_comprobar(capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == amistoso and c["color"] == CapaVisionNPC.COLOR_AMISTOSO), "El amistoso aporta campo verde.")
	_comprobar(not capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == lejano), "Un NPC no visible no revela su ubicación ni su campo.")
	_comprobar(capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == _npcs[4].obtener_id_actor() and c["color"] == CapaVisionNPC.COLOR_NEUTRAL), "Trompo visible conserva su campo neutral aunque no combate.")
	_escenario.tablero.obtener_celda(Vector2i(100, 101)).bloquea_vision = true
	capa.actualizar(null, true)
	_comprobar(not capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == guardia and c["coordenada"] == Vector2i(100, 102)), "La pared recorta el campo con la misma línea visual del NPC.")
	_escenario.tablero.obtener_celda(Vector2i(100, 101)).bloquea_vision = false
	_escenario.tablero.obtener_celda(Vector2i(100, 102)).visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	capa.actualizar(null, true)
	_comprobar(not capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == guardia and c["coordenada"] == Vector2i(100, 102)), "El campo no descubre una casilla fuera de la visibilidad actual.")
	_escenario.tablero.obtener_celda(Vector2i(100, 102)).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	_comprobar(_escenario._iniciar_combate(_npcs[0]), "Abrir encuentro para el color temporal.")
	capa.actualizar(_escenario.gestor_rondas)
	_comprobar(capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == guardia and c["color"] == CapaVisionNPC.COLOR_HOSTIL) and _npcs[0].obtener_puntos_actitud() == 0, "Un neutral que se defiende se pinta rojo por bando sin alterar su relación.")
	_npcs[0].recibir_danio(99)
	capa.actualizar(_escenario.gestor_rondas)
	_comprobar(not capa.campos.any(func(c: Dictionary) -> bool: return c["npc_id"] == guardia), "Un cadáver deja de mostrar campo.")
	_escenario._unhandled_input(tecla_v)
	_comprobar(not capa.visible and capa.campos.is_empty(), "V oculta y limpia la superposición.")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("FaccionesNPC: %d comprobaciones correctas, auxilio local, bandos, XP, visión, memoria, turno aliado, migración, K/C y cadáver." % _casos)
	get_tree().quit(0 if _fallos.is_empty() else 1)
