extends "res://tests/interacciones/prueba_facciones_npc.gd"

const RUTA_XP := "user://prueba_xp_indirecta_npc_automatica.json"


func _ejecutar() -> void:
	_escena = load("res://tests/interacciones/escena_xp_indirecta_npc.tscn").instantiate()
	_escenario = _escena.get_node("Escenario")
	_escenario.set_script(PRUEBA_ACTITUD.EscenarioSinRender)
	add_child(_escena)
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if _escena.get("_enemigos").size() == 5:
			break
	_comprobar(_escena.get("_enemigos").size() == 5, "La escena de XP crea sus cinco NPC.")
	if _escena.get("_enemigos").size() != 5:
		_finalizar()
		return
	_escenario.set_process(false)
	_npcs.assign(_escena.get("_enemigos"))
	_comprobar(_escena.agro_automatico and _npcs[0].obtener_actitud_hacia_jugador() == HOSTIL and _npcs[1].obtener_actitud_hacia_jugador() == HOSTIL, "Los dos guardias de la escena manual comienzan hostiles sin recibir golpes.")
	_escenario._evaluar_agro_npc()
	_comprobar(_escenario.en_combate and _npcs[0].bando_encuentro == OPONENTE and _npcs[1].bando_encuentro == OPONENTE, "La detección inicia el encuentro e incorpora a ambos guardias sin acciones del jugador.")
	var plan_inicial: Dictionary = _escenario._plan_combate_npc(_npcs[0])
	_comprobar(plan_inicial["decision"] == &"acercarse" and plan_inicial["camino"].size() > 1, "El guardia detecta y planea perseguir desde su posición inicial sin ser atacado.")
	for npc in _npcs:
		_perfiles.append(npc.obtener_definicion_personaje().duplicate(true))
	for x in range(94, 121):
		for y in range(94, 109):
			_escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	_escenario.pathfinding.inicializar(_escenario.tablero.datos)
	_probar_fuentes_y_estados()
	_probar_exclusion_y_bando()
	_probar_persistencia()
	_probar_archivo_con_estados_reales()
	await _probar_explosion_y_cierre()
	_probar_controles_manuales()
	_escenario._terminar_combate(false)
	_escena.queue_free()
	await get_tree().process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("XPIndirectaNPC: %d comprobaciones correctas; estados, fuentes, explosión, bandos, K/C, migración y controles manuales." % _casos)
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _preparar(encuentro: bool = true, dos_oponentes: bool = true) -> void:
	_reiniciar()
	_escenario.ficha_jugador.experiencia_acumulada = 0
	_configurar(_npcs[0], HOSTIL)
	_configurar(_npcs[1], HOSTIL if dos_oponentes else NEUTRAL)
	if encuentro:
		_comprobar(_escenario._iniciar_combate(_npcs[0], false), "Abrir encuentro sin daño previo.")
		_activar_turno(_escenario.ficha_jugador)


func _xp() -> int:
	return _escenario.ficha_jugador.experiencia_acumulada


func _probar_fuentes_y_estados() -> void:
	for fuente in [null, _npcs[1], _npcs[2], _escenario.ficha_jugador, RefCounted.new()]:
		_preparar()
		_npcs[0].recibir_danio(1, fuente)
		_comprobar(_xp() == 50, "Toda fuente mortal concede XP por un oponente participante, sin daño previo.")
		_npcs[0].recibir_danio(99, fuente)
		_comprobar(_xp() == 50, "El cadáver no vuelve a conceder XP.")
	for clave in [&"veneno", &"quemado"]:
		_preparar()
		_activar_turno(_npcs[0])
		_npcs[0].aplicar_o_renovar_estado(clave, 1, 1, 1)
		var avance: ResultadoAvanceTurno = _escenario.gestor_rondas.finalizar_turno_activo()
		_comprobar(avance.exitoso and _npcs[0].esta_muerto() and _xp() == 50, "FIN_TURNO mortal por %s entrega 50 XP sin responsable directo." % clave)
		_comprobar(_escenario.hud.experiencia_barra.value == 50.0 and _escenario.ficha_jugador.nivel == 1, "El tick actualiza el HUD sin subir nivel.")
		_escenario.servicio_turnos.avanzar_turno(_npcs[0])
		_comprobar(_xp() == 50, "Otro FIN_TURNO sobre cadáver no duplica XP.")
	_preparar()
	var aplicado: Variant = AplicadorEfectos.new().aplicar(SolicitudEfecto.new(
		&"lava", &"dano", _npcs[0], &"xp_terreno", 1.0
	))
	_comprobar(aplicado is ResultadoEfectoAplicado and _xp() == 50, "Daño ambiental sin autor usa el aplicador compartido y concede XP.")


func _probar_exclusion_y_bando() -> void:
	_preparar()
	_npcs[2].recibir_danio(1)
	_comprobar(_npcs[2].esta_muerto() and _xp() == 0, "La muerte indirecta de un aliado no entrega XP al jugador.")
	_npcs[3].recibir_danio(1, _escenario.ficha_jugador)
	_comprobar(_xp() == 0, "Un NPC ajeno al encuentro no concede XP, aunque muera por el jugador.")
	_preparar()
	_npcs[0].obtener_definicion_personaje().experiencia_recompensa_derrota = 0
	_npcs[0].recibir_danio(1)
	_comprobar(_xp() == 0, "Recompensa cero sigue siendo cero para daño sin autor.")
	_preparar()
	_escenario._terminar_combate(false)
	_npcs[0].recibir_danio(1)
	_comprobar(_xp() == 0, "Fuera de combate no premia, aun con la señal conectada de un encuentro anterior.")
	_preparar(false)
	_npcs[0].recibir_danio(1, _escenario.ficha_jugador)
	_comprobar(_xp() == 0, "Ni siquiera daño directo da XP fuera de un encuentro activo.")
	_preparar(false)
	_configurar(_npcs[0], NEUTRAL)
	_escenario._iniciar_combate(_npcs[0])
	_npcs[0].recibir_danio(1)
	_comprobar(_xp() == 50, "Un neutral que participa como oponente da XP por su bando, no por actitud.")
	_preparar()
	_escenario._asignar_bando(_npcs[0], ALIADO)
	_npcs[0].recibir_danio(1)
	_comprobar(_xp() == 0, "Una víctima hostil que está en el bando aliado no concede XP al jugador.")


func _probar_persistencia() -> void:
	_preparar()
	_npcs[0].aplicar_o_renovar_estado(&"veneno", 1, 1, 1)
	var motivo_guardado: StringName = _escenario.guardar_partida(RUTA_XP)
	_comprobar(motivo_guardado == &"", "Guardar antes del tick mortal con XP cero: %s." % motivo_guardado)
	_escenario.servicio_turnos.avanzar_turno(_npcs[0])
	_comprobar(_xp() == 50 and _npcs[0].esta_muerto(), "La primera muerte indirecta entrega XP.")
	_comprobar(_escenario.guardar_partida(RUTA_XP + ".despues") == &"", "Guardar cadáver y premio juntos.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA_XP) == &"" and _xp() == 0 and not _npcs[0].esta_muerto() and _npcs[0].obtener_estado(&"veneno") != null, "K/C anterior restaura vida, veneno pendiente y XP anterior.")
		_escenario.servicio_turnos.avanzar_turno(_npcs[0])
		_comprobar(_xp() == 50, "Revivir por carga permite una nueva muerte de esa línea temporal, una sola vez.")
		_comprobar(_escenario.cargar_partida(RUTA_XP + ".despues") == &"" and _xp() == 50 and _npcs[0].esta_muerto(), "K/C posterior conserva el cadáver sin otorgar XP otra vez.")
		_npcs[0].recibir_danio(99)
		_comprobar(_xp() == 50, "Repetir daño después de cargar el cadáver no duplica XP.")
	var antiguo: Dictionary = _escenario.persistencia_partida.crear_snapshot(
		_escenario.tablero, &"zona1", _escenario.ficha_jugador, _escenario.registro_conocimiento, _escenario.gestor_rondas
	)
	antiguo["ficha"].erase("experiencia_acumulada")
	antiguo["rondas"].erase("bandos")
	antiguo["rondas"].erase("defendidos")
	_comprobar(_escenario.persistencia_partida.archivos.guardar(RUTA_XP + ".antiguo", antiguo) == &"", "Preparar snapshot anterior sin XP ni bandos.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA_XP + ".antiguo") == &"" and _xp() == 0 and _npcs[0].esta_muerto(), "Migrar un cadáver antiguo no concede XP retroactiva y conserva la ficha sin XP en cero.")
	_npcs[1].recibir_danio(1)
	_comprobar(_xp() == 50, "Una nueva muerte indirecta sí premia tras migrar el encuentro antiguo.")


func _probar_archivo_con_estados_reales() -> void:
	for clave in [&"quemado", &"veneno"]:
		_preparar()
		var ficha: Ficha = _escenario.ficha_jugador
		var recursos: Dictionary = ficha.obtener_estado_persistente()["recursos_turno"]
		var prueba: Node = PRUEBA_ACTITUD.new()
		var superficie: Node2D = Fuego.new() if clave == &"quemado" else HumoVeneno.new()
		for actor in [_npcs[0], ficha]:
			var solicitud: SolicitudEfecto
			if superficie is Fuego:
				superficie.ticks_quemado = 1
				solicitud = superficie.crear_solicitud_quemado(actor, &"archivo_estado_real")
			else:
				superficie.ticks_veneno = 1
				superficie.coordenada_mapa = actor.coordenada_mapa
				superficie.motor_dados = MotorDados.new(prueba._rng_para([6]))
				var resultado: ResultadoAccion = superficie.resolver_accion(ContextoAccion.new(TiposInteraccion.TipoAccion.ENTRAR, actor, actor.coordenada_mapa, actor.coordenada_mapa, superficie, null, &"", [], {}, -1.0, {}, TiposInteraccion.TipoLineaEfecto.NINGUNA, {}, TiposInteraccion.PoliticaCobro.SOLO_EXITO, null, &"archivo_estado_real"))
				solicitud = resultado.solicitudes_efecto[0]
			_comprobar(AplicadorEfectos.new().aplicar(solicitud) is ResultadoEfectoAplicado, "Aplicar %s desde la superficie real al NPC y a la ficha." % clave)
		prueba.free()
		superficie.free()
		var vida := ficha.pv_actual
		_comprobar(_escenario.guardar_partida(RUTA_XP + ".dados") == &"", "Guardar estados con dados reales en el archivo.")
		_npcs[0].retirar_estado(clave)
		ficha.retirar_estado(clave)
		var cargado: StringName = _escenario.cargar_partida(RUTA_XP + ".dados")
		_comprobar(cargado == &"", "Cargar JSON con términos de dados: %s." % cargado)
		if cargado != &"":
			continue
		for actor in [_npcs[0], ficha]:
			var terminos: Array[Dictionary] = actor.obtener_estado(clave).terminos_dano_tick
			_comprobar(terminos[0][&"cantidad"] is int and terminos[0][&"caras"] is int and terminos[0][&"signo"] is int, "Restaurar términos canónicos que el motor de dados pueda ejecutar.")
			_comprobar(_escenario.servicio_turnos.avanzar_turno(actor).exitosa and actor.obtener_estado(clave) == null, "FIN_TURNO restaurado consume el último tick de %s." % clave)
		_comprobar(_npcs[0].esta_muerto() and _xp() == 50 and ficha.pv_actual < vida and ficha.obtener_estado_persistente()["recursos_turno"] == recursos, "El tick cargado causa daño y XP una sola vez sin reponer recursos.")
		_escenario.servicio_turnos.avanzar_turno(_npcs[0])
		_comprobar(_xp() == 50, "Repetir FIN_TURNO no duplica la recompensa del estado restaurado.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_XP + ".dados"))


func _probar_explosion_y_cierre() -> void:
	_preparar()
	var celda: Celda = _escenario.tablero.obtener_celda(_npcs[0].coordenada_mapa)
	celda.ocupantes.append(_npcs[0])
	var solicitudes := Explosion.crear_solicitudes(_escenario.tablero, Vector2i(100, 101), 1, 1, &"xp_explosion_multiple")
	celda.ocupantes.erase(_npcs[0])
	_comprobar(solicitudes.size() == 2, "La explosión alcanza a los dos NPC interactuables sin duplicar uno presente también como ocupante.")
	for solicitud in solicitudes:
		_comprobar(AplicadorEfectos.new().aplicar(solicitud) is ResultadoEfectoAplicado, "Resolver daño real de la explosión sin autor.")
	_comprobar(_xp() == 100 and _npcs[0].esta_muerto() and _npcs[1].esta_muerto(), "Una explosión entrega 50 XP por cada oponente, incluido el último.")
	await get_tree().process_frame
	_comprobar(not _escenario.en_combate and _xp() == 100, "El cierre diferido ocurre después de entregar la última recompensa.")
	_comprobar(_escenario.guardar_partida(RUTA_XP + ".cierre") == &"", "Guardar después de cerrar por explosión.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA_XP + ".cierre") == &"" and _xp() == 100 and not _escenario.en_combate, "K/C con encuentro cerrado no vuelve a entregar las recompensas.")


func _tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	_escena._input(evento)


func _probar_controles_manuales() -> void:
	for codigo in [KEY_1, KEY_2]:
		_preparar(false)
		_tecla(KEY_B)
		_tecla(codigo)
		_escenario.servicio_turnos.avanzar_turno(_npcs[0])
		_comprobar(_xp() == 50, "Los controles manuales abren encuentro y aplican un estado mortal real.")
	for codigo in [KEY_3, KEY_4]:
		_preparar(false)
		_tecla(codigo)
		_comprobar(_xp() == 0 and _npcs[0].esta_muerto(), "El control manual mata fuera de combate sin conceder XP.")
		_preparar(false)
		_tecla(KEY_B)
		_tecla(codigo)
		_tecla(codigo)
		_comprobar(_xp() == 50 and _npcs[0].esta_muerto(), "El control manual concede una sola recompensa dentro del encuentro.")
