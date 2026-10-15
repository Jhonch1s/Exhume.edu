extends Node

var _fallos: Array[String] = []


func _ready() -> void:
	# Usa el mismo receptor de registro que la escena jugable, sin renderizar 3D.
	var escenario: Node2D = load("res://scenes/escenario_base/escenario_base.gd").new()
	# Estos servicios normalmente se unen en _ready(), que aquí no se ejecuta.
	escenario.add_child(escenario.tablero)
	escenario.add_child(escenario.pathfinding)
	escenario.add_child(escenario.gestor_acciones)
	var zona := Node2D.new()
	add_child(zona)
	var suelo := TileMapLayer.new()
	suelo.name = "CapaSuelo"
	suelo.tile_set = TileSet.new()
	zona.add_child(suelo)
	var efectos := Node2D.new()
	efectos.name = "EfectosSuperficie"
	zona.add_child(efectos)
	escenario.zona_actual = zona
	var tablero := TableroGrid.new()
	add_child(tablero)
	tablero.datos[Vector2i.ZERO] = Celda.new()
	tablero.zona_referencia = zona
	tablero.capa_referencia = suelo
	tablero.item_suelo_registrado.connect(escenario._on_item_suelo_registrado)
	tablero.item_suelo_retirado.connect(escenario._on_item_suelo_retirado)
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	var item := ItemSuelo.new(ItemInstancia.new(&"piedra_prueba", piedra, 2))
	item.configurar_desplazamiento_visual(Vector2(3.5, -2.0))
	_comprobar(tablero.registrar_item_suelo(Vector2i.ZERO, item), "La piedra debe registrarse.")
	var persistencia := PersistenciaContenidoDinamico.new()
	var guardado: Array = JSON.parse_string(JSON.stringify(persistencia.obtener_items_suelo(tablero)))
	_comprobar(
		guardado[0]["variante_visual"] == item.obtener_representacion().sprite.frame,
		"El JSON debe guardar la variante visible inicial."
	)
	var variante_inicial: int = int(guardado[0]["variante_visual"])
	for carga in range(3):
		seed(100 + carga)
		_comprobar(persistencia.validar(guardado, [], tablero, {}) == &"", "El guardado debe ser válido.")
		persistencia.restaurar(guardado, [], tablero)
		var restaurado := tablero.obtener_item_suelo(&"piedra_prueba")
		_comprobar(
			restaurado.variante_visual == variante_inicial
			and restaurado.obtener_representacion().sprite.frame == variante_inicial
			and restaurado.item.cantidad == 2
			and restaurado.coordenada_mapa == Vector2i.ZERO
			and restaurado.desplazamiento_visual == Vector2(3.5, -2.0)
			and restaurado.obtener_representacion().global_position
				== suelo.to_global(suelo.map_to_local(Vector2i.ZERO) + Vector2(3.5, -2.0)),
			"Cargar repetidamente debe mantener apariencia, identidad, cantidad y posición."
		)
	for variante in range(3):
		var explicito := guardado.duplicate(true)
		explicito[0]["variante_visual"] = variante
		_comprobar(persistencia.validar(explicito, [], tablero, {}) == &"", "Toda variante de piedra debe admitirse.")
		persistencia.restaurar(explicito, [], tablero)
		_comprobar(
			tablero.obtener_item_suelo(&"piedra_prueba").obtener_representacion().sprite.frame == variante,
			"Debe aplicarse la variante solicitada, sin volver a sortearla."
		)
	var anterior := guardado.duplicate(true)
	anterior[0].erase("variante_visual")
	_comprobar(persistencia.validar(anterior, [], tablero, {}) == &"", "Los guardados anteriores deben admitirse.")
	persistencia.restaurar(anterior, [], tablero)
	var migrado := persistencia.obtener_items_suelo(tablero)
	_comprobar(migrado[0].has("variante_visual"), "Una carga anterior debe elegir una variante para el próximo guardado.")
	persistencia.restaurar(migrado, [], tablero)
	_comprobar(
		tablero.obtener_item_suelo(&"piedra_prueba").variante_visual == migrado[0]["variante_visual"],
		"La variante elegida para un guardado anterior debe conservarse al volver a cargar."
	)
	for valor_invalido in [-1, 3, 1.5, "2"]:
		var invalido := guardado.duplicate(true)
		invalido[0]["variante_visual"] = valor_invalido
		_comprobar(
			persistencia.validar(invalido, [], tablero, {}) == &"variante_visual_item_guardada_invalida",
			"Deben rechazarse variantes inválidas antes de restaurar."
		)
	escenario.free()
	tablero.queue_free()
	zona.queue_free()
	await get_tree().process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("VarianteItemSuelo: cargas repetidas, tres variantes, guardado anterior y validación correctos.")
	get_tree().call_deferred(&"quit", 0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
