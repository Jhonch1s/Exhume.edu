extends SceneTree

class SuperficieCostosaPrueba extends RefCounted:
	var coste: int
	var familia: StringName

	func _init(coste_inicial: int, familia_inicial: StringName = &"") -> void:
		coste = coste_inicial
		familia = familia_inicial

	func obtener_coste_movimiento_adicional(_actor: Object = null) -> int:
		return coste

	func obtener_familia_superficie() -> StringName:
		return familia


var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	_probar_calculo_compuesto()
	_probar_familias_superpuestas()
	_probar_pathfinding_prefiere_coste_menor()
	await _probar_movimiento_costoso()
	await _probar_energia_insuficiente()
	if _fallos.is_empty():
		print("CostesMovimiento: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_calculo_compuesto() -> void:
	var celda := Celda.new()
	celda.coste_movimiento_adicional = 1
	celda.penalizacion_peligro_ruta = 4.0
	celda.efectos_superficie.append(SuperficieCostosaPrueba.new(2))
	_comprobar(celda.calcular_coste_movimiento() == 4, "Debe sumar base, terreno y superficie.")
	_comprobar(celda.calcular_peso_ruta() == 8.0, "El peligro solo debe aumentar el peso de ruta.")


func _probar_familias_superpuestas() -> void:
	var celda := Celda.new()
	celda.coste_movimiento_adicional = 1
	celda.efectos_superficie.assign([
		SuperficieCostosaPrueba.new(2, &"humo"),
		SuperficieCostosaPrueba.new(3, &"humo"),
		SuperficieCostosaPrueba.new(4, &"fuego"),
	])
	_comprobar(
		celda.calcular_coste_movimiento() == 9,
		"Debe tomar el mayor aporte de cada familia y sumar familias distintas."
	)


func _probar_pathfinding_prefiere_coste_menor() -> void:
	var tablero: Dictionary[Vector2i, Celda] = {}
	for coord in [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	]:
		tablero[coord] = Celda.new()
	tablero[Vector2i(1, 0)].efectos_superficie.append(SuperficieCostosaPrueba.new(9))
	var pathfinding := PathFindingManager.new()
	pathfinding.inicializar(tablero)
	var camino := pathfinding.calcular_camino(Vector2i.ZERO, Vector2i(2, 0), tablero)
	_comprobar(
		Vector2i(1, 0) not in camino,
		"El pathfinding debe evitar una superficie cara si existe un desvio barato."
	)
	pathfinding.free()


func _probar_movimiento_costoso() -> void:
	var entorno := _crear_entorno(2, 2)
	var ficha: Ficha = entorno.ficha
	_comprobar(
		is_equal_approx(ficha.calcular_duracion_paso(2), ficha.velocidad_paso * 2.0),
		"Un paso costoso debe durar el doble."
	)
	ficha.mover_por_camino(
		[Vector2i.ZERO, Vector2i(1, 0)],
		entorno.preparar,
		entorno.confirmar,
		entorno.cancelar,
		Callable(),
		Callable(),
		entorno.calcular_coste
	)
	var interrumpido: bool = await ficha.movimiento_terminado
	_comprobar(not interrumpido, "Un paso costeable debe completarse.")
	_comprobar(ficha.energia_actual == 0, "Debe cobrar el coste total confirmado.")
	_comprobar(ficha.coordenada_mapa == Vector2i(1, 0), "Debe confirmar el destino.")
	await process_frame
	(entorno.liberar as Callable).call()
	await process_frame


func _probar_energia_insuficiente() -> void:
	var entorno := _crear_entorno(1, 2)
	var ficha: Ficha = entorno.ficha
	var termino := [false]
	ficha.movimiento_terminado.connect(func(_interrumpido: bool): termino[0] = true)
	ficha.mover_por_camino(
		[Vector2i.ZERO, Vector2i(1, 0)],
		entorno.preparar,
		entorno.confirmar,
		entorno.cancelar,
		Callable(),
		Callable(),
		entorno.calcular_coste
	)
	await process_frame
	_comprobar(termino[0], "La ruta insuficiente debe finalizar.")
	_comprobar(ficha.coordenada_mapa == Vector2i.ZERO, "No debe iniciar el tween.")
	_comprobar(ficha.energia_actual == 1, "No debe cobrar un paso no realizado.")
	_comprobar(
		entorno.tablero.obtener_celda(Vector2i(1, 0)).reservas.is_empty(),
		"No debe reservar el destino sin energía."
	)
	(entorno.liberar as Callable).call()
	await process_frame


func _crear_entorno(energia: int, coste_destino: int) -> Dictionary:
	var tablero := TableroGrid.new()
	var capa := TileMapLayer.new()
	capa.tile_set = TileSet.new()
	var ficha := Ficha.new()
	root.add_child(tablero)
	root.add_child(capa)
	root.add_child(ficha)
	ficha.velocidad_paso = 0.001
	ficha.energia_actual = energia
	ficha.inicializar(Vector2i.ZERO, capa)
	tablero.datos[Vector2i.ZERO] = Celda.new()
	var destino := Celda.new()
	destino.coste_movimiento_adicional = coste_destino - 1
	tablero.datos[Vector2i(1, 0)] = destino
	tablero.ocupar_celda(Vector2i.ZERO, ficha)
	return {
		"tablero": tablero,
		"capa": capa,
		"ficha": ficha,
		"preparar": func(_origen, coord, actor): return tablero.reservar_celda(coord, actor),
		"confirmar": func(origen, coord, actor): return tablero.confirmar_movimiento(origen, coord, actor),
		"cancelar": func(coord, actor): tablero.cancelar_reserva(coord, actor),
		"calcular_coste": func(_origen, coord, actor): return tablero.obtener_celda(coord).calcular_coste_movimiento(actor),
		"liberar": func():
			tablero.datos.clear()
			ficha.queue_free()
			capa.queue_free()
			tablero.queue_free(),
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
