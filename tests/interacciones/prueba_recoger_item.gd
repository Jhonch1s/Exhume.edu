extends SceneTree

class TableroRetiroFallido extends TableroGrid:
	func retirar_item_suelo(_item_suelo: ItemSuelo) -> bool:
		return false


var _fallos: Array[String] = []


func _init() -> void:
	_probar_opcion_y_contexto()
	_probar_recogida_mediante_gestor()
	_probar_bloqueos_sin_mutacion()
	_probar_rollback()

	if _fallos.is_empty():
		print("RecogerItem: 4 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_opcion_y_contexto() -> void:
	var entorno := _crear_entorno()
	var item_suelo: ItemSuelo = entorno.item_suelo
	var ficha: Ficha = entorno.ficha
	var opciones := item_suelo.obtener_opciones_accion(ficha)
	_comprobar(
		opciones.size() == 1
		and opciones[0].tipo == TiposInteraccion.TipoAccion.RECOGER,
		"Un item registrado debe publicar RECOGER."
	)
	var construccion: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
		opciones[0],
		ficha,
		Vector2i.ZERO,
		Vector2i(1, 0)
	)
	_comprobar(
		construccion is ContextoAccion
		and construccion.objetivo == item_suelo
		and construccion.item == item_suelo.item
		and construccion.alcance_maximo == 1.0,
		"La opción debe construir un contexto coherente y adyacente."
	)
	_liberar_entorno(entorno)


func _probar_recogida_mediante_gestor() -> void:
	var entorno := _crear_entorno()
	var tablero: TableroGrid = entorno.tablero
	var ficha: Ficha = entorno.ficha
	var item_suelo: ItemSuelo = entorno.item_suelo
	var contexto := _crear_contexto(ficha, item_suelo, Vector2i.ZERO)
	var resultado := _procesar(contexto)
	_comprobar(resultado.exitosa, "GestorAcciones debe resolver una recogida válida.")
	_comprobar(
		ficha.inventario.obtener_por_id(item_suelo.item.id_instancia) == item_suelo.item
		and tablero.obtener_item_suelo(item_suelo.item.id_instancia) == null
		and tablero.obtener_celda(Vector2i(1, 0)).items_suelo.is_empty(),
		"La instancia debe pasar exactamente una vez del suelo al inventario."
	)
	_comprobar(
		item_suelo.item.id_instancia == &"piedras_prueba"
		and item_suelo.item.cantidad == 3,
		"Recoger debe conservar identidad y cantidad."
	)
	_comprobar(
		resultado.mensajes == [&"item.recogido"]
		and resultado.cambios_estado.size() == 1
		and resultado.cambios_estado[0][&"cantidad"] == 3,
		"El resultado debe describir la transferencia confirmada."
	)
	_comprobar(
		_procesar(contexto).motivo
		== &"item_suelo_no_registrado",
		"La misma instancia no debe poder recogerse dos veces."
	)
	_liberar_entorno(entorno)


func _probar_bloqueos_sin_mutacion() -> void:
	var entorno := _crear_entorno()
	var tablero: TableroGrid = entorno.tablero
	var ficha: Ficha = entorno.ficha
	var item_suelo: ItemSuelo = entorno.item_suelo
	var lejano := _crear_contexto(ficha, item_suelo, Vector2i(-2, 0))
	var resultado_lejano := _procesar(lejano)
	_comprobar(
		resultado_lejano.motivo == &"fuera_de_alcance",
		"El gestor debe bloquear una recogida fuera de alcance."
	)
	var actor_sin_inventario := RefCounted.new()
	var contexto_actor := _crear_contexto(actor_sin_inventario, item_suelo, Vector2i.ZERO)
	var resultado_actor := _procesar(contexto_actor)
	_comprobar(
		resultado_actor.motivo == &"actor_sin_inventario",
		"Un actor sin inventario debe bloquearse."
	)
	_comprobar(
		tablero.obtener_item_suelo(item_suelo.item.id_instancia) == item_suelo
		and ficha.inventario.obtener_contenido().is_empty(),
		"Los bloqueos no deben modificar ninguno de los extremos."
	)
	_liberar_entorno(entorno)


func _probar_rollback() -> void:
	var tablero := TableroRetiroFallido.new()
	var entorno := _crear_entorno(tablero)
	var ficha: Ficha = entorno.ficha
	var item_suelo: ItemSuelo = entorno.item_suelo
	var resultado := _procesar(
		_crear_contexto(ficha, item_suelo, Vector2i.ZERO)
	)
	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO
		and resultado.motivo == &"retiro_item_suelo_fallido",
		"Un fallo inesperado del retiro debe informar FALLO."
	)
	_comprobar(
		ficha.inventario.obtener_contenido().is_empty()
		and tablero.obtener_item_suelo(item_suelo.item.id_instancia) == item_suelo,
		"El rollback debe dejar el item únicamente en el suelo."
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
	var item_suelo := ItemSuelo.new(
		ItemInstancia.new(&"piedras_prueba", definicion, 3)
	)
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.datos[Vector2i(1, 0)] = Celda.new()
	var transferidor := TransferidorItems.new(tablero)
	tablero.configurar_transferidor_items(transferidor)
	tablero.registrar_item_suelo(Vector2i(1, 0), item_suelo)
	return {
		"tablero": tablero,
		"ficha": ficha,
		"item_suelo": item_suelo,
		"transferidor": transferidor,
	}


func _crear_contexto(
	actor: Object,
	item_suelo: ItemSuelo,
	origen: Vector2i
) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.RECOGER,
		actor,
		origen,
		Vector2i(1, 0),
		item_suelo,
		item_suelo.item,
		&"",
		[],
		{},
		1.0
	)


func _liberar_entorno(entorno: Dictionary) -> void:
	(entorno.item_suelo as ItemSuelo).configurar_transferidor_items(null)
	(entorno.tablero as TableroGrid)._limpiar_items_suelo()
	(entorno.ficha as Ficha).free()
	(entorno.tablero as TableroGrid).free()
	entorno.clear()


func _procesar(contexto: ContextoAccion) -> ResultadoAccion:
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
