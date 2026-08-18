extends SceneTree

var _fallos: Array[String] = []
var _eventos: Array[StringName] = []
var _tablero := TableroGrid.new()
var _ficha := Ficha.new()


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var capa := TileMapLayer.new()
	capa.tile_set = TileSet.new()
	root.add_child(_tablero)
	root.add_child(capa)
	root.add_child(_ficha)
	_ficha.velocidad_paso = 0.001
	_ficha.inicializar(Vector2i.ZERO, capa)
	_tablero.datos[Vector2i.ZERO] = Celda.new()
	_tablero.datos[Vector2i(1, 0)] = Celda.new()
	_tablero.datos[Vector2i(2, 0)] = Celda.new()
	_tablero.ocupar_celda(Vector2i.ZERO, _ficha)

	_ficha.mover_por_camino(
		[Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)],
		_preparar_paso,
		_confirmar_paso,
		_cancelar_paso,
		_procesar_salida,
		_procesar_entrada
	)
	var interrumpido: bool = await _ficha.movimiento_terminado

	_comprobar(interrumpido, "La reacción debe interrumpir la ruta tras el paso.")
	_comprobar(
		_eventos == [&"salir", &"confirmar", &"entrar"],
		"SALIR, confirmación y ENTRAR deben ocurrir una vez y en ese orden."
	)
	_comprobar(
		_ficha.coordenada_mapa == Vector2i(1, 0),
		"La ficha debe detenerse en el primer destino confirmado."
	)
	_comprobar(_ficha.energia_actual == 199, "El coste normal debe cobrarse una vez.")
	_comprobar(
		_ficha in _tablero.obtener_celda(Vector2i(1, 0)).ocupantes,
		"El destino confirmado debe conservar la ocupación."
	)
	_comprobar(
		_ficha not in _tablero.obtener_celda(Vector2i.ZERO).ocupantes,
		"El origen debe quedar libre después de confirmar."
	)
	await process_frame
	_tablero.datos.clear()
	_ficha.queue_free()
	capa.queue_free()
	_tablero.queue_free()
	await process_frame

	if _fallos.is_empty():
		print("CicloSeguroPaso: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _preparar_paso(_origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	return _tablero.reservar_celda(destino, ficha)


func _confirmar_paso(origen: Vector2i, destino: Vector2i, ficha: Ficha) -> bool:
	_eventos.append(&"confirmar")
	return _tablero.confirmar_movimiento(origen, destino, ficha)


func _cancelar_paso(destino: Vector2i, ficha: Ficha) -> void:
	_tablero.cancelar_reserva(destino, ficha)


func _procesar_salida(origen: Vector2i, destino: Vector2i, ficha: Ficha) -> void:
	_eventos.append(&"salir")
	_comprobar(
		ficha.global_position == ficha.capa_referencia.map_to_local(destino),
		"SALIR debe ocurrir después de completar la animación."
	)
	_comprobar(
		ficha.coordenada_mapa == origen and ficha in _tablero.obtener_celda(origen).ocupantes,
		"Durante SALIR la ocupación lógica debe permanecer en el origen."
	)


func _procesar_entrada(origen: Vector2i, destino: Vector2i, ficha: Ficha) -> void:
	_eventos.append(&"entrar")
	_comprobar(
		ficha.coordenada_mapa == destino,
		"ENTRAR debe observar la coordenada de destino."
	)
	_comprobar(
		ficha in _tablero.obtener_celda(destino).ocupantes,
		"ENTRAR debe ocurrir después de confirmar la ocupación."
	)
	_comprobar(
		ficha not in _tablero.obtener_celda(origen).ocupantes,
		"ENTRAR no debe observar ocupación residual en el origen."
	)
	ficha.solicitar_interrupcion()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
