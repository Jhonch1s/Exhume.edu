extends "res://tests/interacciones/prueba_facciones_npc.gd"

const BOMBA := preload("res://assets/items/bomba_humo/bomba_humo.tres")
const RUTA_TACTICA := "user://prueba_tactica_npc_automatica.json"


class BuscadorContado:
	extends PathFindingManager
	var consultas := 0

	func calcular_camino(origen: Vector2i, destino: Vector2i, datos: Dictionary, actor: Object = null) -> Array[Vector2i]:
		consultas += 1
		return super.calcular_camino(origen, destino, datos, actor)


func _ejecutar() -> void:
	_escena = load("res://tests/interacciones/escena_tactica_npc.tscn").instantiate()
	_escenario = _escena.get_node("Escenario")
	_escenario.set_script(PRUEBA_ACTITUD.EscenarioSinRender)
	add_child(_escena)
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if _escena.get("_enemigos").size() == 5:
			break
	_comprobar(_escena.get("_enemigos").size() == 5, "La escena táctica crea los cinco NPC.")
	if _escena.get("_enemigos").size() != 5:
		_finalizar()
		return
	_escenario.set_process(false)
	_npcs.assign(_escena.get("_enemigos"))
	_comprobar(_npcs[0].vida_actual == 4 and _bombas() == 2, "La escena manual prepara herida y bombas reales.")
	for npc in _npcs:
		_perfiles.append(npc.obtener_definicion_personaje().duplicate(true))
	for x in range(94, 121):
		for y in range(94, 109):
			_escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	_escenario.pathfinding.inicializar(_escenario.tablero.datos)
	_probar_seleccion()
	_probar_prioridades_sin_huida()
	_probar_consultas_ruta()
	await _probar_turno_real_y_carga()
	_escenario._terminar_combate(false)
	_escena.queue_free()
	await get_tree().process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("TacticaNPC: %d comprobaciones correctas; objetivos, combate sin huida ni humo automático, turno real y K/C." % _casos)
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _preparar() -> void:
	_reiniciar()
	for npc in _npcs:
		npc.vida_inicial = -1
		npc.estado_personaje = null
		if npc.obtener_inventario() != null:
			for item in npc.obtener_inventario().obtener_por_definicion(&"bomba_humo"):
				npc.obtener_inventario().retirar(item.id_instancia)
	_configurar(_npcs[0], HOSTIL)
	_mover_npc(_npcs[2], Vector2i(103, 100))
	_comprobar(_escenario._iniciar_combate(_npcs[0], false), "Preparar encuentro con bandos y aliado.")
	_activar_turno(_npcs[0])


func _plan() -> Dictionary:
	return _escenario._plan_combate_npc(_npcs[0])


func _bombas() -> int:
	var cantidad := 0
	for item in _npcs[0].obtener_inventario().obtener_por_definicion(&"bomba_humo"):
		cantidad += item.cantidad
	return cantidad


func _dar_bombas(cantidad: int = 2) -> void:
	_comprobar(_npcs[0].obtener_inventario().agregar(ItemInstancia.new(&"tactica_bombas", BOMBA, cantidad)).exitosa, "Añadir bomba al inventario real.")


func _probar_seleccion() -> void:
	_preparar()
	_npcs[2].vida_actual = 1
	_comprobar(_plan()["objetivo"] == _escenario.ficha_jugador and _plan()["decision"] == &"atacar", "Atacar al adyacente precede al débil distante y no elige compañeros.")
	_mover_jugador(Vector2i(98, 100))
	_comprobar(_plan()["objetivo"] == _npcs[2] and _plan()["decision"] == &"acercarse", "Sin adyacentes prioriza al visible de menor PV con ruta.")
	# El objetivo débil queda fuera de visión propia aunque el aliado lo recuerde.
	_npcs[0].obtener_definicion_personaje().radio_agro = 2
	_comprobar(_plan()["objetivo"] == _escenario.ficha_jugador, "No consulta PV ni persigue la posición actual de un enemigo oculto.")
	_npcs[0].obtener_definicion_personaje().radio_agro = 12
	for direccion in DecisorCombateNPC.DIRECCIONES:
		_escenario.tablero.obtener_celda(_npcs[2].coordenada_mapa + direccion).caminable = false
	_comprobar(_plan()["objetivo"] == _escenario.ficha_jugador, "Un débil inaccesible no desplaza a un objetivo alcanzable.")
	for direccion in DecisorCombateNPC.DIRECCIONES:
		_escenario.tablero.obtener_celda(_npcs[2].coordenada_mapa + direccion).caminable = true
	_npcs[2].vida_actual = _escenario.ficha_jugador.pv_actual
	_comprobar(_plan()["objetivo"] == _escenario.ficha_jugador, "Con la misma prioridad y PV se elige al visible más cercano.")
	_mover_npc(_npcs[2], Vector2i(101, 101))
	_comprobar(_plan()["objetivo"] == _npcs[2], "El desempate usa distancia euclídea, no el orden de los participantes.")
	_mover_npc(_npcs[2], Vector2i(102, 100))
	var visibles: Array[Object] = [_npcs[2], _escenario.ficha_jugador]
	var decisor: DecisorCombateNPC = _escenario._obtener_decisor_npc(_npcs[0])
	for _orden in range(2):
		_comprobar(decisor.elegir(_npcs[0], _escenario.tablero, _escenario.pathfinding, visibles, true)["objetivo"] == _escenario.ficha_jugador, "Con igual PV y distancia gana el ID menor aunque se invierta la lista visible.")
		visibles.reverse()


func _probar_prioridades_sin_huida() -> void:
	_preparar()
	var npc := _npcs[0]
	npc.vida_actual = 1
	_dar_bombas()
	_comprobar(_plan()["decision"] == &"atacar" and _bombas() == 2, "Con un PV y bombas continúa atacando, sin huida ni humo automático.")
	npc.aplicar_o_renovar_estado(&"enredado", 1, 1, 1)
	_comprobar(_plan()["decision"] == &"liberarse", "Liberarse conserva la primera prioridad.")
	npc.retirar_estado(&"enredado")
	npc.aplicar_o_renovar_estado(&"caido", 1, 1, 1)
	_comprobar(_plan()["decision"] == &"terminar_turno", "Caído no puede atacar ni acercarse.")
	npc.retirar_estado(&"caido")
	_mover_jugador(Vector2i(97, 100))
	_comprobar(_plan()["decision"] == &"acercarse", "Un herido distante se acerca normalmente al objetivo visible.")
	npc.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO))
	npc.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	_comprobar(_plan()["decision"] == &"terminar_turno" and _bombas() == 2, "Sin recursos pasa sin usar bombas ni acción adicional.")
	npc.iniciar_turno()
	npc.obtener_definicion_personaje().radio_agro = 0
	npc.recordar_posicion_jugador(Vector2i(96, 100))
	_mover_jugador(Vector2i(94, 100))
	var plan := _plan()
	_comprobar(plan["decision"] == &"acercarse" and plan["camino"].back() == Vector2i(97, 100) and not plan["objetivo_visible"], "Herido sin visión persigue sólo el recuerdo, sin consultar la posición oculta actual.")
	_mover_jugador(Vector2i(118, 106))
	_npcs[2].vida_actual = 1
	_mover_npc(_npcs[2], Vector2i(116, 104))
	var oculto := _plan()
	_comprobar(oculto["camino"] == plan["camino"] and oculto["decision"] == plan["decision"] and not oculto["objetivo_visible"], "Mover y cambiar PV de oponentes ocultos no cambia la persecución del recuerdo.")


func _probar_consultas_ruta() -> void:
	_preparar()
	_mover_jugador(Vector2i(97, 100))
	_escenario._asignar_bando(_npcs[2], OPONENTE)
	var anterior: PathFindingManager = _escenario.pathfinding
	var contador := BuscadorContado.new()
	add_child(contador)
	contador.inicializar(_escenario.tablero.datos)
	_escenario.pathfinding = contador
	_comprobar(_plan()["decision"] == &"acercarse" and contador.consultas == 4, "Una decisión con un visible distante consulta sus cuatro vecinos una sola vez.")
	contador.consultas = 0
	_npcs[0].aplicar_o_renovar_estado(&"enredado", 1, 1, 0)
	_comprobar(_plan()["decision"] == &"liberarse" and contador.consultas == 0, "Liberarse no calcula caminos de ataque.")
	_npcs[0].retirar_estado(&"enredado")
	_npcs[0].aplicar_o_renovar_estado(&"caido", 1, 1, 1)
	_comprobar(_plan()["decision"] == &"terminar_turno" and contador.consultas == 0, "Caído pasa sin calcular rutas.")
	_npcs[0].retirar_estado(&"caido")
	_npcs[0].consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, _npcs[0].obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO))
	_comprobar(_plan()["decision"] == &"terminar_turno" and contador.consultas == 0, "Sin movimiento no se buscan caminos que no se pueden pagar.")
	_escenario.pathfinding = anterior
	contador.queue_free()


func _probar_turno_real_y_carga() -> void:
	_preparar()
	var npc := _npcs[0]
	npc.vida_actual = 1
	_dar_bombas()
	var origen := npc.coordenada_mapa
	_comprobar(_escenario.guardar_partida(RUTA_TACTICA) == &"", "Guardar al herido con dos bombas antes del turno.")
	var intentos := {"ataques": 0, "lanzamientos": 0}
	var contar := func(contexto: ContextoAccion) -> void:
		if contexto.tipo == TiposInteraccion.TipoAccion.LANZAR_ITEM:
			intentos["lanzamientos"] += 1
		elif contexto.id_accion == &"ataque_basico_npc":
			intentos["ataques"] += 1
	_escenario.gestor_acciones.accion_iniciada.connect(contar)
	_escenario.ejecutar_turnos = true
	_escenario._programar_turno_npc()
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		if intentos["ataques"] > 0:
			break
	_escenario.ejecutar_turnos = false
	_escenario._secuencia_turno_npc += 1
	await get_tree().create_timer(0.65).timeout
	_escenario.gestor_acciones.accion_iniciada.disconnect(contar)
	_comprobar(intentos["ataques"] == 1 and intentos["lanzamientos"] == 0, "El turno real del herido ataca una vez y no lanza humo.")
	_comprobar(npc.coordenada_mapa == origen and _bombas() == 2 and npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "No se retira ni consume bombas; cobra la acción del ataque.")
	_comprobar(not _escenario.lanzamiento_en_vuelo and not _escenario.interaccion_modal_activa, "El combate no deja un lanzamiento ni modal pendiente.")
	_comprobar(_escenario.guardar_partida(RUTA_TACTICA + ".despues") == &"", "Guardar después del ataque conserva recursos gastados e inventario.")
	for _carga in range(2):
		_comprobar(_escenario.cargar_partida(RUTA_TACTICA) == &"" and _bombas() == 2 and npc.vida_actual == 1 and npc.coordenada_mapa == origen and npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1, "K/C anterior restaura al herido y sus bombas sin ejecutar acciones.")
		_comprobar(_escenario.cargar_partida(RUTA_TACTICA + ".despues") == &"" and _bombas() == 2 and npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "K/C posterior no repite el ataque ni gasta bombas.")
	npc.recibir_danio(99)
	_comprobar(npc.esta_muerto() and _bombas() == 2 and npc.permite_caminar_interactuable(), "El cadáver conserva las bombas sin usar como botín.")
