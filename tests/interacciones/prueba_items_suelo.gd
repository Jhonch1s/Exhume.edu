extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	_probar_registro_y_orden()
	_probar_rechazos_sin_mutacion()
	_probar_retiro_exacto()
	_probar_limpieza_del_tablero()
	_probar_celda_no_caminable_y_ocupada()

	if _fallos.is_empty():
		print("ItemsSuelo: 5 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_registro_y_orden() -> void:
	var tablero := _crear_tablero()
	var b := _crear_item_suelo(&"piedras_b")
	var a := _crear_item_suelo(&"piedras_a")
	var registrados: Array[ItemSuelo] = []
	tablero.item_suelo_registrado.connect(
		func(_coord: Vector2i, item_suelo: ItemSuelo): registrados.append(item_suelo)
	)
	_comprobar(tablero.registrar_item_suelo(Vector2i.ZERO, b), "Debe registrar un item válido.")
	_comprobar(tablero.registrar_item_suelo(Vector2i.ZERO, a), "Debe registrar otro ID.")
	_comprobar(
		tablero.obtener_celda(Vector2i.ZERO).items_suelo == [a, b],
		"La celda debe ordenar sus items por ID estable."
	)
	_comprobar(
		tablero.obtener_item_suelo(&"piedras_a") == a
		and a.coordenada_mapa == Vector2i.ZERO
		and a.esta_registrado,
		"Índice, celda y contenedor deben confirmar el mismo registro."
	)
	_comprobar(registrados == [b, a], "Cada alta debe emitir una señal al finalizar.")
	tablero.free()


func _probar_rechazos_sin_mutacion() -> void:
	var tablero := _crear_tablero()
	var original := _crear_item_suelo(&"piedra_unica")
	var duplicado := _crear_item_suelo(&"piedra_unica")
	_comprobar(
		not tablero.registrar_item_suelo(Vector2i(9, 9), original),
		"Una celda inexistente debe rechazarse."
	)
	_comprobar(tablero.items_suelo_por_id.is_empty(), "El rechazo no debe registrar parcialmente.")
	_comprobar(tablero.registrar_item_suelo(Vector2i.ZERO, original), "El primer ID debe aceptarse.")
	_comprobar(
		not tablero.registrar_item_suelo(Vector2i(1, 0), original)
		and not tablero.registrar_item_suelo(Vector2i(1, 0), duplicado),
		"Debe rechazar el mismo contenedor y otro contenedor con igual ID."
	)
	_comprobar(
		tablero.obtener_celda(Vector2i.ZERO).items_suelo == [original]
		and tablero.obtener_celda(Vector2i(1, 0)).items_suelo.is_empty(),
		"Los rechazos deben conservar una única ubicación."
	)
	var definicion_invalida := DefinicionItem.new()
	var invalido := ItemSuelo.new(ItemInstancia.new(&"invalido", definicion_invalida))
	_comprobar(
		not tablero.registrar_item_suelo(Vector2i.ZERO, invalido),
		"Una instancia inválida no debe registrarse."
	)
	tablero.free()


func _probar_retiro_exacto() -> void:
	var tablero := _crear_tablero()
	var original := _crear_item_suelo(&"piedra")
	var impostor := _crear_item_suelo(&"piedra")
	var retiros: Array[ItemSuelo] = []
	tablero.item_suelo_retirado.connect(
		func(_coord: Vector2i, item_suelo: ItemSuelo): retiros.append(item_suelo)
	)
	tablero.registrar_item_suelo(Vector2i.ZERO, original)
	_comprobar(not tablero.retirar_item_suelo(impostor), "Un impostor no debe retirar el original.")
	_comprobar(tablero.retirar_item_suelo(original), "La referencia registrada debe retirarse.")
	_comprobar(
		tablero.obtener_item_suelo(&"piedra") == null
		and tablero.obtener_celda(Vector2i.ZERO).items_suelo.is_empty()
		and not original.esta_registrado
		and original.coordenada_mapa == null,
		"Retirar debe limpiar índice, celda y estado lógico."
	)
	_comprobar(
		retiros == [original] and not tablero.retirar_item_suelo(original),
		"Debe emitir una vez e impedir un segundo retiro."
	)
	tablero.free()


func _probar_limpieza_del_tablero() -> void:
	var tablero := _crear_tablero()
	var item_suelo := _crear_item_suelo(&"piedra")
	tablero.registrar_item_suelo(Vector2i.ZERO, item_suelo)
	tablero._limpiar_items_suelo()
	_comprobar(
		tablero.items_suelo_por_id.is_empty()
		and tablero.obtener_celda(Vector2i.ZERO).items_suelo.is_empty()
		and not item_suelo.esta_registrado,
		"Reiniciar el tablero debe invalidar y retirar sus registros anteriores."
	)
	tablero.free()


func _probar_celda_no_caminable_y_ocupada() -> void:
	var tablero := _crear_tablero()
	var celda := tablero.obtener_celda(Vector2i.ZERO)
	celda.caminable = false
	celda.ocupantes.append(RefCounted.new())
	_comprobar(
		tablero.registrar_item_suelo(Vector2i.ZERO, _crear_item_suelo(&"decoracion")),
		"El contenido colocado debe requerir existencia, no caminabilidad ni desocupación."
	)
	tablero.free()


func _crear_tablero() -> TableroGrid:
	var tablero := TableroGrid.new()
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i(1, 0)] = Celda.new()
	return tablero


func _crear_item_suelo(id_instancia: StringName) -> ItemSuelo:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra"
	definicion.nombre = "Piedra"
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	return ItemSuelo.new(ItemInstancia.new(id_instancia, definicion))


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
