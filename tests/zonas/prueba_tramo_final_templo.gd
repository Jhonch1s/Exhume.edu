extends SceneTree

const TEMPLO := "res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn"
const PRISION := "res://scenes/Prision/prision.tscn"
const ID_DERRUMBE := &"templo_derrumbe"
const UMBRAL := Vector2i(2, -52)

var _fallos := 0


func _init() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	# Abrir la zona directamente reproduce el arranque de F6.
	EstadoPartida.establecer_aventurero({
		"nombre": "Prueba", "titulo": "Probador", "clase": "Guerrero",
		"origen": "Prueba", "fuerza": 4, "destreza": 4, "voluntad": 4,
	})
	change_scene_to_file(TEMPLO)
	for _intento in 250:
		await process_frame
		if current_scene != null and current_scene.has_method(&"obtener_id_zona") and current_scene.escenario_preparado:
			break
	var escenario := current_scene
	if escenario == null or not escenario.has_method(&"obtener_id_zona") or not escenario.escenario_preparado:
		_comprobar(false, "F6 debe preparar el escenario del templo.")
		quit(1)
		return
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var tablero: TableroGrid = escenario.tablero
	var persistencia: PersistenciaPartida = escenario.persistencia_partida
	var zona_id: StringName = escenario.obtener_id_zona()
	var ficha: Ficha = escenario.ficha_jugador
	var conocimiento: RegistroConocimiento = escenario.registro_conocimiento
	var efectos: Array[StringName] = []
	escenario.gestor_vfx.efecto_emitido.connect(func(tipo, _pos): efectos.append(tipo))

	var placa := tablero.obtener_interactuable(&"trampa_superficie_001")
	var origen_placa := placa.coordenada_mapa + Vector2i.DOWN
	_ubicar(escenario, origen_placa)
	await _dar_paso(escenario, placa.coordenada_mapa)
	_comprobar(efectos.count(&"piedra_moviendo") == 1, "Desde F6, pisar la placa causa un temblor.")
	await create_timer(1.3).timeout
	_comprobar(efectos.count(&"piedra_encajada") == 1, "El grupo encaja con un solo golpe.")

	var rutas := PathFindingManager.new()
	rutas.inicializar(tablero.datos)
	var origen_tunel := Vector2i(0, -30)
	_comprobar(not rutas.calcular_camino(origen_tunel, UMBRAL, tablero.datos).is_empty(), "El derrumbe inicial deja llegar al umbral.")
	var derrumbe := tablero.obtener_interactuable(ID_DERRUMBE)
	var rocas := derrumbe.get_node("Rocas") as Node2D
	var reposo := rocas.position
	_comprobar(not rocas.visible, "Las rocas permanecen ocultas antes del cruce.")
	var legado := persistencia.crear_snapshot(tablero, zona_id, ficha, conocimiento)
	if legado.is_empty():
		_comprobar(false, "El mapa abierto debe poder guardarse.")
		quit(1)
		return
	legado["interactuables"] = legado["interactuables"].filter(func(datos): return datos["id"] != String(ID_DERRUMBE))
	# Las partidas previas podían explorar celdas de la roca original sin suelo.
	if [-1, -46] not in legado["celdas_exploradas"]:
		legado["celdas_exploradas"].append([-1, -46])

	_ubicar(escenario, UMBRAL)
	await _dar_paso(escenario, UMBRAL + Vector2i.DOWN)
	_comprobar(not escenario.gestor_triggers.tiene_actividad(), "Cruzar hacia +Y no dispara el derrumbe.")
	await _dar_paso(escenario, UMBRAL)
	_comprobar(escenario.gestor_triggers.tiene_actividad(), "Cruzar hacia -Y encola el derrumbe.")
	await escenario.gestor_triggers.procesar(escenario)
	_comprobar(EstadoPartida.trigger_consumido(zona_id, &"casi_trampa_fatal"), "El cruce consume el trigger tras cerrar el paso.")
	_comprobar(rocas.visible and rocas.position.y < reposo.y, "La animación arranca por encima de su posición final.")
	_comprobar(efectos.count(&"derrumbe") == 1, "El derrumbe dispara una sola sacudida en el umbral.")
	_comprobar(rutas.calcular_camino(UMBRAL, origen_tunel, tablero.datos).is_empty(), "Las rocas cortan el regreso por el túnel.")
	_comprobar(tablero.puede_entrar(UMBRAL, escenario.ficha_jugador), "El protagonista queda a salvo del otro lado.")
	var caida := derrumbe.get("_caida") as Tween
	if caida != null:
		caida.pause()
		caida.custom_step(0.2)
		_comprobar(not is_equal_approx(rocas.position.x, reposo.x), "La pieza se sacude lateralmente al caer.")
		caida.custom_step(1.1)
	_comprobar(rocas.position.is_equal_approx(reposo), "La pieza aterriza en la ubicación original.")

	var caido := persistencia.crear_snapshot(tablero, zona_id, ficha, conocimiento)
	_comprobar(persistencia.restaurar(legado, tablero, zona_id, ficha, conocimiento) == &"" and not rocas.visible, "Un guardado anterior al mecanismo recupera el corredor libre y la niebla explorada.")
	_comprobar(persistencia.restaurar(caido, tablero, zona_id, ficha, conocimiento) == &"" and rocas.visible and rocas.position.is_equal_approx(reposo), "Restaurar un derrumbe lo deja asentado sin animarlo.")
	_comprobar(not tablero.puede_entrar(Vector2i(2, -50)), "El derrumbe restaurado sigue bloqueando el paso.")
	_comprobar(ficha.coordenada_mapa == UMBRAL and EstadoPartida.trigger_consumido(zona_id, &"casi_trampa_fatal"), "La restauración conserva al jugador y el consumo del trigger.")
	rutas.free()

	_ubicar(escenario, Vector2i(0, -1))
	await _dar_paso(escenario, Vector2i.ZERO)
	await escenario.gestor_triggers.procesar(escenario)
	_comprobar(current_scene != escenario and current_scene.zona_actual.scene_file_path == PRISION, "vuelta_prision abre Prisión.")
	_comprobar(current_scene.ficha_jugador.coordenada_mapa == Vector2i(79, -26), "El viaje aterriza en entrada_prision.")
	_comprobar(not current_scene.gestor_triggers.tiene_actividad(), "El spawn de Prisión no activa otro viaje.")
	current_scene.queue_free()
	await process_frame
	print("Tramo final del templo: %d fallos." % _fallos)
	quit(0 if _fallos == 0 else 1)


func _ubicar(escenario: Node, coord: Vector2i) -> void:
	var ficha: Ficha = escenario.ficha_jugador
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(coord, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(coord, ficha)
	escenario._actualizar_luz_jugador(coord)
	escenario.centrar_camara_en_ficha()


func _dar_paso(escenario: Node, destino: Vector2i) -> void:
	var ficha: Ficha = escenario.ficha_jugador
	var camino: Array[Vector2i] = [ficha.coordenada_mapa, destino]
	await ficha.mover_por_camino(
		camino, escenario._preparar_paso_actor, escenario._confirmar_paso_actor,
		escenario._cancelar_paso_actor, escenario._procesar_salida_paso_actor,
		escenario._procesar_entrada_paso_actor, escenario._calcular_coste_paso_actor
	)
	_comprobar(ficha.coordenada_mapa == destino, "El paso llega a %s." % destino)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos += 1
		push_error(mensaje)
