extends SceneTree

class TableroRegistroParcialFallido extends TableroGrid:
	func registrar_item_suelo(_coord: Vector2i, _item_suelo: ItemSuelo) -> bool:
		return false


var _fallos: Array[String] = []


func _init() -> void:
	_probar_recogida_parcial()
	_probar_soltado_parcial()
	_probar_cantidades_e_ids_invalidos()
	_probar_rollback_parcial()

	if _fallos.is_empty():
		print("TransferenciasParciales: 4 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_recogida_parcial() -> void:
	var entorno := _crear_entorno_suelo()
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_recoger(
		entorno.ficha,
		entorno.item_suelo,
		Vector2i.ZERO,
		2,
		&"piedras_recogidas"
	)
	var resultado := _procesar(contexto)
	var parcial: ItemInstancia = entorno.ficha.inventario.obtener_por_id(
		&"piedras_recogidas"
	)
	_comprobar(resultado.exitosa, "Debe recoger una cantidad parcial válida.")
	_comprobar(
		entorno.item.cantidad == 3
		and parcial != null
		and parcial.cantidad == 2
		and parcial.id_instancia == &"piedras_recogidas",
		"La pila origen debe conservar su ID y la porción debe usar el nuevo."
	)
	_comprobar(
		entorno.tablero.obtener_item_suelo(&"piedras_suelo") == entorno.item_suelo,
		"Una recogida parcial debe mantener la pila restante en su celda."
	)
	_liberar(entorno)


func _probar_soltado_parcial() -> void:
	var entorno := _crear_entorno_inventario()
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_soltar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.ZERO,
		2,
		&"piedras_soltadas"
	)
	var resultado := _procesar(contexto)
	var item_suelo: ItemSuelo = entorno.tablero.obtener_item_suelo(&"piedras_soltadas")
	var cantidad_suelo := item_suelo.item.cantidad if item_suelo != null else -1
	var id_suelo := item_suelo.item.id_instancia if item_suelo != null else &""
	_comprobar(resultado.exitosa, "Debe soltar una cantidad parcial válida.")
	_comprobar(
		entorno.item.cantidad == 3
		and item_suelo != null
		and cantidad_suelo == 2
		and id_suelo == &"piedras_soltadas",
		"Estado parcial inesperado: origen=%d, suelo=%d, id=%s." % [
			entorno.item.cantidad,
			cantidad_suelo,
			id_suelo,
		]
	)
	_liberar(entorno)


func _probar_cantidades_e_ids_invalidos() -> void:
	var entorno := _crear_entorno_inventario()
	var casos: Array[Dictionary] = [
		{&"cantidad": 0, &"id": &"nueva", &"motivo": &"cantidad_invalida"},
		{&"cantidad": 6, &"id": &"nueva", &"motivo": &"cantidad_invalida"},
		{&"cantidad": 2, &"id": &"", &"motivo": &"id_item_nuevo_vacio"},
		{&"cantidad": 2, &"id": &"piedras_inventario", &"motivo": &"id_item_duplicado"},
		{&"cantidad": 5, &"id": &"innecesaria", &"motivo": &"id_item_resultante_inesperado"},
	]
	for caso in casos:
		var contexto: ContextoAccion = entorno.transferidor.construir_contexto_soltar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			Vector2i.ZERO,
			caso[&"cantidad"],
			caso[&"id"]
		)
		_comprobar(
			_procesar(contexto).motivo == caso[&"motivo"],
			"Cada transferencia inválida debe conservar su motivo estable."
		)
	_comprobar(
		entorno.item.cantidad == 5
		and entorno.ficha.inventario.obtener_contenido().size() == 1
		and entorno.tablero.items_suelo_por_id.is_empty(),
		"Los rechazos deben dejar cantidades y ubicaciones intactas."
	)
	_liberar(entorno)


func _probar_rollback_parcial() -> void:
	var entorno := _crear_entorno_inventario(TableroRegistroParcialFallido.new())
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_soltar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.ZERO,
		2,
		&"piedras_fallidas"
	)
	var resultado := _procesar(contexto)
	_comprobar(
		resultado.motivo == &"registro_item_suelo_fallido",
		"El fallo de registro parcial debe informarse."
	)
	_comprobar(
		entorno.item.cantidad == 5
		and entorno.ficha.inventario.obtener_contenido() == [entorno.item]
		and entorno.tablero.items_suelo_por_id.is_empty(),
		"El rollback parcial debe recomponer exactamente la pila original."
	)
	_liberar(entorno)


func _crear_entorno_suelo() -> Dictionary:
	var entorno := _crear_base()
	var item := _crear_item(&"piedras_suelo", 5)
	var item_suelo := ItemSuelo.new(item)
	entorno.tablero.registrar_item_suelo(Vector2i(1, 0), item_suelo)
	entorno[&"item"] = item
	entorno[&"item_suelo"] = item_suelo
	return entorno


func _crear_entorno_inventario(tablero_inicial: TableroGrid = null) -> Dictionary:
	var entorno := _crear_base(tablero_inicial)
	var item := _crear_item(&"piedras_inventario", 5)
	entorno.ficha.inventario.agregar(item)
	entorno[&"item"] = item
	return entorno


func _crear_base(tablero_inicial: TableroGrid = null) -> Dictionary:
	var tablero: TableroGrid = (
		tablero_inicial if tablero_inicial != null else TableroGrid.new()
	)
	var ficha := Ficha.new()
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i(1, 0)] = Celda.new()
	tablero.datos[Vector2i.ZERO].ocupantes.append(ficha)
	var transferidor := TransferidorItems.new(tablero)
	tablero.configurar_transferidor_items(transferidor)
	return {
		&"tablero": tablero,
		&"ficha": ficha,
		&"transferidor": transferidor,
	}


func _crear_item(id_instancia: StringName, cantidad: int) -> ItemInstancia:
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra"
	definicion.nombre = "Piedra"
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	return ItemInstancia.new(id_instancia, definicion, cantidad)


func _procesar(contexto: ContextoAccion) -> ResultadoAccion:
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _liberar(entorno: Dictionary) -> void:
	var tablero := entorno.tablero as TableroGrid
	for item_suelo in tablero.items_suelo_por_id.values():
		item_suelo.configurar_transferidor_items(null)
	tablero._limpiar_items_suelo()
	(entorno.ficha as Ficha).free()
	tablero.free()
	entorno.clear()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
