extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var escena := load(
		"res://scenes/interactuables/mecanismos/palanca_interactuable.tscn"
	) as PackedScene
	var palanca := escena.instantiate() as PalancaInteractuable
	palanca.definicion = load(
		"res://assets/interactuables/mecanismos/palanca/palanca.tres"
	) as DefinicionPalanca
	palanca.id_instancia = &"palanca_prueba"
	palanca.coordenada_mapa = Vector2i.RIGHT
	root.add_child(palanca)
	await process_frame
	var actor := Ficha.new()
	var piedra := ItemInstancia.new(
		&"piedra_prueba",
		load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	)
	actor.inventario.agregar(piedra)
	var opciones := palanca.obtener_opciones_accion(actor)
	var opcion := _buscar_accionar(opciones)
	_comprobar(
		opcion != null and not opciones.any(
			func(candidata): return candidata.tipo == TiposInteraccion.TipoAccion.USAR_ITEM
		),
		"La palanca debe ofrecer Accionar y no Usar item, incluso con una piedra."
	)
	var contexto: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
		opcion,
		actor,
		Vector2i.ZERO,
		Vector2i.RIGHT
	)
	var resultado := _procesar(contexto)
	_comprobar(
		resultado.exitosa and palanca.activada and contexto.item == null,
		"Cualquier actor adyacente debe accionar la palanca sin item."
	)
	_comprobar(
		palanca.sprite.region_rect == Rect2(64, 0, 64, 64),
		"El estado activado debe mostrar el segundo frame de 64×64."
	)
	var contexto_lejano: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
		opcion,
		actor,
		Vector2i(-2, 0),
		Vector2i.RIGHT
	)
	var bloqueo := _procesar(contexto_lejano)
	_comprobar(
		bloqueo.motivo == &"fuera_de_alcance" and palanca.activada,
		"Accionar desde lejos debe bloquearse sin cambiar el estado."
	)

	actor.free()
	palanca.free()
	_finalizar()


func _buscar_accionar(opciones: Array[OpcionAccion]) -> OpcionAccion:
	for opcion in opciones:
		if opcion.id == &"accionar":
			return opcion
	return null


func _procesar(contexto: ContextoAccion) -> ResultadoAccion:
	var gestor := GestorAcciones.new()
	var resultado := gestor.procesar_accion(contexto)
	gestor.free()
	return resultado


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PalancaInteractuar: 4 pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
