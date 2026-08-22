extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	await _probar_ruta_encadena_turnos()
	await _probar_combate_no_encadena()
	_probar_proyeccion_por_coste()
	if _fallos.is_empty():
		print("RecursosTurnoMovimiento: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_ruta_encadena_turnos() -> void:
	var entorno := _crear_entorno(9)
	var ficha: Ficha = entorno.ficha
	var aplicador := AplicadorEfectos.new()
	aplicador.aplicar(SolicitudEfecto.new(
		&"veneno", &"estado", ficha, &"veneno_ruta", 1.0, 2
	))
	var vida_inicial := ficha.pv_actual
	var avances := [0]
	ficha.mover_por_camino(
		entorno.camino,
		entorno.preparar,
		entorno.confirmar,
		entorno.cancelar,
		Callable(),
		Callable(),
		entorno.calcular_coste,
		func(actor):
			avances[0] += 1
			var resultado: ResultadoAccion = entorno.servicio_turnos.avanzar_turno(actor)
			if resultado.exitosa:
				actor.iniciar_turno()
			return resultado.exitosa
	)
	var interrumpido: bool = await ficha.movimiento_terminado
	_comprobar(not interrumpido and avances[0] == 1, "Exploración debe encadenar un turno.")
	_comprobar(ficha.coordenada_mapa == Vector2i(9, 0), "Debe completar la ruta larga.")
	_comprobar(
		ficha.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 5,
		"El nuevo turno debe conservar cinco puntos."
	)
	_comprobar(
		ficha.pv_actual == vida_inicial - 1
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 1,
		"La ruta larga debe producir exactamente un tick de veneno."
	)
	(entorno.liberar as Callable).call()
	await process_frame


func _probar_combate_no_encadena() -> void:
	var entorno := _crear_entorno(9)
	var ficha: Ficha = entorno.ficha
	AplicadorEfectos.new().aplicar(SolicitudEfecto.new(
		&"veneno", &"estado", ficha, &"veneno_combate", 1.0, 2
	))
	var vida_inicial := ficha.pv_actual
	var avances := [0]
	ficha.mover_por_camino(
		entorno.camino,
		entorno.preparar,
		entorno.confirmar,
		entorno.cancelar,
		Callable(),
		Callable(),
		entorno.calcular_coste,
		func(actor):
			avances[0] += 1
			return entorno.servicio_turnos.avanzar_turno(actor).exitosa,
		true
	)
	var interrumpido: bool = await ficha.movimiento_terminado
	_comprobar(interrumpido, "Combate debe detenerse al agotar movimiento.")
	_comprobar(ficha.coordenada_mapa == Vector2i(7, 0), "Debe detenerse tras siete pasos.")
	_comprobar(
		avances[0] == 0
		and ficha.pv_actual == vida_inicial
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 2,
		"Combate no debe finalizar turno ni avanzar veneno automáticamente."
	)
	(entorno.liberar as Callable).call()
	await process_frame


func _probar_proyeccion_por_coste() -> void:
	var tablero: Dictionary[Vector2i, Celda] = {}
	var camino: Array[Vector2i] = []
	for x in range(5):
		camino.append(Vector2i(x, 0))
		tablero[Vector2i(x, 0)] = Celda.new()
	tablero[Vector2i(2, 0)].coste_movimiento_adicional = 2
	var pathfinding := PathFindingManager.new()
	var limitado := pathfinding.limitar_camino_por_movimiento(
		camino, tablero, null, 4
	)
	_comprobar(limitado == camino.slice(0, 3), "La proyección debe usar el coste real.")
	pathfinding.free()


func _crear_entorno(pasos: int) -> Dictionary:
	var tablero := TableroGrid.new()
	var capa := TileMapLayer.new()
	capa.tile_set = TileSet.new()
	var ficha := Ficha.new()
	var gestor := GestorAcciones.new()
	root.add_child(tablero)
	root.add_child(capa)
	root.add_child(ficha)
	root.add_child(gestor)
	ficha.velocidad_paso = 0.001
	ficha.inicializar(Vector2i.ZERO, capa)
	var camino: Array[Vector2i] = []
	for x in range(pasos + 1):
		var coord := Vector2i(x, 0)
		camino.append(coord)
		tablero.datos[coord] = Celda.new()
	tablero.ocupar_celda(Vector2i.ZERO, ficha)
	return {
		"tablero": tablero,
		"capa": capa,
		"ficha": ficha,
		"servicio_turnos": ServicioTurnos.new(gestor),
		"camino": camino,
		"preparar": func(_origen, coord, actor): return tablero.reservar_celda(coord, actor),
		"confirmar": func(origen, coord, actor): return tablero.confirmar_movimiento(origen, coord, actor),
		"cancelar": func(coord, actor): tablero.cancelar_reserva(coord, actor),
		"calcular_coste": func(_origen, coord, actor): return tablero.obtener_celda(coord).calcular_coste_movimiento(actor),
		"liberar": func():
			tablero.datos.clear()
			ficha.queue_free()
			gestor.queue_free()
			capa.queue_free()
			tablero.queue_free(),
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
