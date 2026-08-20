extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var escena := load(
		"res://scenes/interactuables/puertas/puerta_interactuable.tscn"
	) as PackedScene
	var puerta := escena.instantiate() as PuertaInteractuable
	puerta.definicion = load(
		"res://assets/interactuables/puertas/puerta/puerta.tres"
	) as DefinicionPuerta
	puerta.id_instancia = &"puerta_prueba"
	root.add_child(puerta)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	for x in range(3):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	_comprobar(
		tablero.registrar_interactuable(Vector2i.RIGHT, puerta),
		"La puerta debe registrarse en su única celda."
	)
	var pathfinding := PathFindingManager.new()
	pathfinding.inicializar(tablero.datos)
	var cambios_presencia: Array[Vector2i] = []
	tablero.presencia_interactuable_cambiada.connect(
		func(coord: Vector2i): cambios_presencia.append(coord)
	)

	var actor := Ficha.new()
	var llave_correcta := ItemInstancia.new(
		&"llave_correcta",
		load("res://assets/items/llave_prueba/llave_prueba.tres") as DefinicionLlave
	)
	var definicion_incompatible := llave_correcta.definicion.duplicate(true) as DefinicionLlave
	definicion_incompatible.id_definicion = &"llave_incompatible"
	definicion_incompatible.patron_cerradura = &"otro_patron"
	var llave_incompatible := ItemInstancia.new(&"llave_incompatible", definicion_incompatible)
	var piedra := ItemInstancia.new(
		&"piedra_prueba",
		load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	)
	actor.inventario.agregar(llave_correcta)
	actor.inventario.agregar(llave_incompatible)
	actor.inventario.agregar(piedra)

	_probar_presencia_cerrada(tablero, pathfinding)
	_probar_apertura_bloqueada(puerta, actor)
	_probar_item_invalido(puerta, actor, piedra, &"item_no_es_llave")
	_probar_item_invalido(puerta, actor, llave_incompatible, &"llave_incompatible")
	_probar_desbloqueo(puerta, actor, llave_correcta)
	_probar_abrir_y_cerrar(
		puerta,
		actor,
		tablero,
		pathfinding,
		cambios_presencia
	)

	tablero.retirar_interactuable(puerta)
	pathfinding.free()
	actor.free()
	puerta.free()
	tablero.free()
	if _fallos.is_empty():
		print("PuertaUsarLlave: 6 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_apertura_bloqueada(puerta: PuertaInteractuable, actor: Ficha) -> void:
	var opcion := _buscar_opcion(puerta, actor, &"abrir")
	_comprobar(
		opcion != null and not opcion.habilitada and opcion.motivo_bloqueo == &"puerta_bloqueada",
		"Abrir debe mostrarse bloqueado mientras la cerradura está activa."
	)


func _probar_presencia_cerrada(
	tablero: TableroGrid,
	pathfinding: PathFindingManager
) -> void:
	var celda := tablero.obtener_celda(Vector2i.RIGHT)
	var camino := pathfinding.calcular_camino(
		Vector2i.ZERO,
		Vector2i(2, 0),
		tablero.datos
	)
	_comprobar(
		not tablero.puede_entrar(Vector2i.RIGHT)
		and celda.bloquea_vision_efectiva()
		and camino.is_empty(),
		"La puerta cerrada debe bloquear paso, visión y pathfinding."
	)


func _probar_item_invalido(
	puerta: PuertaInteractuable,
	actor: Ficha,
	item: ItemInstancia,
	motivo_esperado: StringName
) -> void:
	var resultado := _usar_item(puerta, actor, item)
	_comprobar(
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO
		and resultado.motivo == motivo_esperado
		and puerta.bloqueada,
		"Un item o patrón incompatible debe fallar sin cambiar la puerta."
	)


func _probar_desbloqueo(
	puerta: PuertaInteractuable,
	actor: Ficha,
	llave: ItemInstancia
) -> void:
	var resultado := _usar_item(puerta, actor, llave)
	_comprobar(
		resultado.exitosa
		and not puerta.bloqueada
		and not puerta.abierta
		and actor.inventario.obtener_por_id(llave.id_instancia) == llave,
		"La llave compatible debe desbloquear, conservarse y dejar la puerta cerrada."
	)
	_comprobar(
		_buscar_opcion(puerta, actor, &"usar_item") == null,
		"Una puerta desbloqueada ya no debe ofrecer Usar item."
	)


func _probar_abrir_y_cerrar(
	puerta: PuertaInteractuable,
	actor: Ficha,
	tablero: TableroGrid,
	pathfinding: PathFindingManager,
	cambios_presencia: Array[Vector2i]
) -> void:
	var apertura := _procesar_opcion(puerta, actor, _buscar_opcion(puerta, actor, &"abrir"))
	var camino_abierto := pathfinding.calcular_camino(
		Vector2i.ZERO,
		Vector2i(2, 0),
		tablero.datos
	)
	_comprobar(
		apertura.exitosa
		and puerta.abierta
		and puerta.sprite.region_rect == Rect2(64, 0, 64, 96)
		and tablero.puede_entrar(Vector2i.RIGHT)
		and not tablero.obtener_celda(Vector2i.RIGHT).bloquea_vision_efectiva()
		and Vector2i.RIGHT in camino_abierto,
		"Abrir debe cambiar la imagen y liberar paso, visión y pathfinding."
	)
	var cierre := _procesar_opcion(puerta, actor, _buscar_opcion(puerta, actor, &"cerrar"))
	var camino_cerrado := pathfinding.calcular_camino(
		Vector2i.ZERO,
		Vector2i(2, 0),
		tablero.datos
	)
	_comprobar(
		cierre.exitosa
		and not puerta.abierta
		and puerta.sprite.region_rect == Rect2(0, 0, 64, 96)
		and not tablero.puede_entrar(Vector2i.RIGHT)
		and tablero.obtener_celda(Vector2i.RIGHT).bloquea_vision_efectiva()
		and camino_cerrado.is_empty()
		and cambios_presencia == [Vector2i.RIGHT, Vector2i.RIGHT],
		"Cerrar debe restaurar presencia y notificar ambos cambios."
	)


func _usar_item(
	puerta: PuertaInteractuable,
	actor: Ficha,
	item: ItemInstancia
) -> ResultadoAccion:
	return _procesar_opcion(
		puerta,
		actor,
		_buscar_opcion(puerta, actor, &"usar_item"),
		item
	)


func _procesar_opcion(
	puerta: PuertaInteractuable,
	actor: Ficha,
	opcion: OpcionAccion,
	item: ItemInstancia = null
) -> ResultadoAccion:
	var contexto: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
		opcion,
		actor,
		Vector2i.ZERO,
		Vector2i.RIGHT,
		item
	)
	if not contexto is ContextoAccion:
		return ResultadoAccion.crear_bloqueo(contexto)
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _buscar_opcion(
	puerta: PuertaInteractuable,
	actor: Ficha,
	id: StringName
) -> OpcionAccion:
	for opcion in puerta.obtener_opciones_accion(actor):
		if opcion.id == id:
			return opcion
	return null


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
