extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var tablero := TableroGrid.new()
	var capa_oscuridad := TileMapLayer.new()
	capa_oscuridad.tile_set = TileSet.new()
	root.add_child(tablero)
	root.add_child(capa_oscuridad)
	for x in range(3):
		tablero.datos[Vector2i(x, 0)] = Celda.new()

	var fov := FOVManager.new()
	root.add_child(fov)
	fov.inicializar(capa_oscuridad, tablero)
	fov.actualizar_vision(Vector2i.ZERO, 3)
	_comprobar(
		tablero.obtener_celda(Vector2i(2, 0)).visibilidad == Celda.EstadoVisibilidad.VISIBLE,
		"Sin humo, la celda posterior debe ser visible."
	)
	var veneno := HumoVeneno.new()
	veneno.configurar_id_instancia(&"veneno")
	root.add_child(veneno)
	_comprobar(
		tablero.registrar_efecto_superficie(Vector2i(1, 0), veneno),
		"La nube venenosa debe registrarse como superficie."
	)
	_comprobar(
		not tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision_efectiva(),
		"La nube venenosa no debe bloquear visión."
	)
	_comprobar(
		tablero.obtener_celda(Vector2i(2, 0)).visibilidad == Celda.EstadoVisibilidad.VISIBLE,
		"El veneno debe conservar visible la celda posterior."
	)
	tablero.retirar_efecto_superficie(veneno)

	var humo_a := _crear_humo(&"humo_a")
	var humo_b := _crear_humo(&"humo_b")
	root.add_child(humo_a)
	root.add_child(humo_b)
	_comprobar(tablero.registrar_efecto_superficie(Vector2i(1, 0), humo_a), "Debe registrar el primer humo.")
	_comprobar(tablero.registrar_efecto_superficie(Vector2i(1, 0), humo_b), "Debe registrar el humo superpuesto.")
	_comprobar(humo_a.obtener_duracion_superficie() == 10, "El humo debe declarar duración diez.")
	_comprobar(
		tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision_efectiva(),
		"El humo debe volver opaca su celda."
	)
	_comprobar(
		tablero.obtener_celda(Vector2i(2, 0)).visibilidad != Celda.EstadoVisibilidad.VISIBLE,
		"El registro debe recalcular FOV y ocultar la celda posterior."
	)
	var validador := ValidadorEspacialTablero.new(tablero)
	_comprobar(
		validador.validar_linea_efecto(_crear_contexto_visual()) == &"linea_de_efecto_bloqueada",
		"El humo debe bloquear también la validación visual."
	)

	_comprobar(tablero.retirar_efecto_superficie(humo_a), "Debe retirar la primera nube.")
	_comprobar(
		tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision_efectiva(),
		"La nube restante debe conservar el bloqueo lógico."
	)
	_comprobar(tablero.retirar_efecto_superficie(humo_b), "Debe retirar la última nube.")
	_comprobar(
		not tablero.obtener_celda(Vector2i(1, 0)).bloquea_vision_efectiva(),
		"Sin nubes, la celda debe recuperar su opacidad base."
	)
	_comprobar(
		tablero.obtener_celda(Vector2i(2, 0)).visibilidad == Celda.EstadoVisibilidad.VISIBLE,
		"Retirar el último humo debe recalcular y restaurar visión."
	)

	humo_a.queue_free()
	humo_b.queue_free()
	veneno.queue_free()
	fov.queue_free()
	capa_oscuridad.queue_free()
	tablero.queue_free()
	await process_frame
	if _fallos.is_empty():
		print("HumoBloqueaVision: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _crear_humo(id: StringName) -> Humo:
	var humo := Humo.new()
	humo.configurar_id_instancia(id)
	return humo


func _crear_contexto_visual() -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.EXAMINAR,
		RefCounted.new(),
		Vector2i.ZERO,
		Vector2i(2, 0),
		RefCounted.new(),
		null,
		&"",
		[],
		{},
		3.0,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
