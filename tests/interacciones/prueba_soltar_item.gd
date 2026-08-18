extends SceneTree

class TableroRegistroFallido extends TableroGrid:
	func registrar_item_suelo(_coord: Vector2i, _item_suelo: ItemSuelo) -> bool:
		return false


var _fallos: Array[String] = []


func _init() -> void:
	_probar_soltar_mediante_gestor()
	_probar_celdas_invalidas()
	_probar_propiedad_y_segundo_intento()
	_probar_rollback()

	if _fallos.is_empty():
		print("SoltarItem: 4 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_soltar_mediante_gestor() -> void:
	var entorno := _crear_entorno()
	var ficha: Ficha = entorno.ficha
	var item: ItemInstancia = entorno.item
	var transferidor: TransferidorItems = entorno.transferidor
	var contexto := transferidor.construir_contexto_soltar(
		ficha,
		item,
		Vector2i.ZERO,
		Vector2i.ZERO
	)
	var resultado := _procesar(contexto)
	var item_suelo := entorno.tablero.obtener_item_suelo(item.id_instancia) as ItemSuelo
	_comprobar(resultado.exitosa, "Una pila propia debe poder soltarse en una celda válida.")
	_comprobar(
		ficha.inventario.obtener_por_id(item.id_instancia) == null
		and item_suelo != null
		and item_suelo.item == item,
		"La instancia debe pasar exactamente una vez del inventario al suelo."
	)
	_comprobar(
		item.id_instancia == &"piedras_prueba" and item.cantidad == 3,
		"Soltar debe conservar identidad y cantidad."
	)
	_comprobar(
		resultado.mensajes == [&"item.soltado"]
		and resultado.cambios_estado[0][&"coordenada_destino"] == Vector2i.ZERO,
		"El resultado debe describir el destino confirmado."
	)
	_liberar_entorno(entorno)


func _probar_celdas_invalidas() -> void:
	var casos: Array[Dictionary] = [
		{&"coord": Vector2i(-1, 0), &"motivo": &"celda_invalida"},
		{&"coord": Vector2i(1, 0), &"motivo": &"celda_no_caminable"},
		{&"coord": Vector2i(0, 1), &"motivo": &"celda_ocupada"},
		{&"coord": Vector2i(0, -1), &"motivo": &"celda_reservada"},
	]
	for caso in casos:
		var entorno := _crear_entorno()
		var resultado := _procesar(entorno.transferidor.construir_contexto_soltar(
			entorno.ficha,
			entorno.item,
			Vector2i.ZERO,
			caso[&"coord"]
		))
		_comprobar(resultado.motivo == caso[&"motivo"], "La celda debe bloquearse por su motivo exacto.")
		_comprobar(
			entorno.ficha.inventario.obtener_por_id(entorno.item.id_instancia) == entorno.item
			and entorno.tablero.items_suelo_por_id.is_empty(),
			"Una celda rechazada no debe perder ni duplicar el item."
		)
		_liberar_entorno(entorno)


func _probar_propiedad_y_segundo_intento() -> void:
	var entorno := _crear_entorno()
	var otro_item := ItemInstancia.new(
		&"piedras_otras",
		entorno.item.definicion,
		1
	)
	var ajeno: ContextoAccion = entorno.transferidor.construir_contexto_soltar(
		entorno.ficha,
		otro_item,
		Vector2i.ZERO,
		Vector2i.ZERO
	)
	_comprobar(
		_procesar(ajeno).motivo == &"item_no_pertenece_inventario",
		"No debe poder soltarse una instancia que no pertenece al inventario."
	)
	var contexto: ContextoAccion = entorno.transferidor.construir_contexto_soltar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.ZERO
	)
	_comprobar(_procesar(contexto).exitosa, "El primer intento válido debe completarse.")
	_comprobar(
		_procesar(contexto).motivo == &"item_no_pertenece_inventario",
		"La misma pila no debe soltarse dos veces."
	)
	_liberar_entorno(entorno)


func _probar_rollback() -> void:
	var entorno := _crear_entorno(TableroRegistroFallido.new())
	var resultado := _procesar(entorno.transferidor.construir_contexto_soltar(
		entorno.ficha,
		entorno.item,
		Vector2i.ZERO,
		Vector2i.ZERO
	))
	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO
		and resultado.motivo == &"registro_item_suelo_fallido",
		"Un fallo inesperado del registro debe informar FALLO."
	)
	_comprobar(
		entorno.ficha.inventario.obtener_por_id(entorno.item.id_instancia) == entorno.item
		and entorno.tablero.items_suelo_por_id.is_empty(),
		"El rollback debe devolver la misma instancia al inventario."
	)
	_liberar_entorno(entorno)


func _crear_entorno(tablero_inicial: TableroGrid = null) -> Dictionary:
	var tablero: TableroGrid = (
		tablero_inicial if tablero_inicial != null else TableroGrid.new()
	)
	var ficha := Ficha.new()
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra"
	definicion.nombre = "Piedra"
	definicion.apilable = true
	definicion.cantidad_maxima = 10
	var item := ItemInstancia.new(&"piedras_prueba", definicion, 3)
	ficha.inventario.agregar(item)
	for coord in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		tablero.datos[coord] = Celda.new()
	tablero.datos[Vector2i(1, 0)].caminable = false
	tablero.datos[Vector2i(0, 1)].ocupantes.append(RefCounted.new())
	tablero.datos[Vector2i(0, -1)].reservas.append(RefCounted.new())
	tablero.datos[Vector2i.ZERO].ocupantes.append(ficha)
	var transferidor := TransferidorItems.new(tablero)
	tablero.configurar_transferidor_items(transferidor)
	return {
		"tablero": tablero,
		"ficha": ficha,
		"item": item,
		"transferidor": transferidor,
	}


func _procesar(contexto: ContextoAccion) -> ResultadoAccion:
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _liberar_entorno(entorno: Dictionary) -> void:
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
