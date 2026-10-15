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
		for y in range(2):
			tablero.datos[Vector2i(x, y)] = Celda.new()

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
	var npc := (load("res://scenes/personajes/npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	npc.id_instancia = &"fov_npc_prueba"
	root.add_child(npc)
	var revision := fov.revision_vision
	_comprobar(tablero.registrar_interactuable(Vector2i(2, 0), npc) and tablero.reubicar_interactuable(npc, Vector2i.ZERO), "Registrar y trasladar un NPC que no bloquea visión.")
	npc.recibir_danio(99)
	_comprobar(fov.revision_vision == revision and npc.visible, "Traslado y muerte del NPC actualizan su presentación sin recalcular FOV.")
	var puerta := (load("res://scenes/interactuables/puertas/puerta_interactuable.tscn") as PackedScene).instantiate() as PuertaInteractuable
	puerta.id_instancia = &"fov_puerta_prueba"
	puerta.definicion = load("res://assets/interactuables/puertas/puerta/puerta.tres")
	root.add_child(puerta)
	_comprobar(tablero.registrar_interactuable(Vector2i(1, 0), puerta) and tablero.obtener_celda(Vector2i(2, 0)).visibilidad != Celda.EstadoVisibilidad.VISIBLE, "Registrar una puerta opaca oculta inmediatamente lo que hay detrás.")
	puerta.abierta = true
	puerta.presencia_cambiada.emit()
	_comprobar(tablero.obtener_celda(Vector2i(2, 0)).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Abrir una puerta vuelve a proyectar visión.")
	puerta.abierta = false
	puerta.presencia_cambiada.emit()
	_comprobar(tablero.obtener_celda(Vector2i(2, 0)).visibilidad != Celda.EstadoVisibilidad.VISIBLE, "Cerrar una puerta vuelve a ocultar el fondo.")
	tablero.retirar_interactuable(puerta)
	_comprobar(tablero.obtener_celda(Vector2i(2, 0)).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Retirar una puerta opaca restaura visión.")
	puerta.huella_celdas = [Vector2i.ZERO, Vector2i.DOWN]
	fov.actualizar_vision(Vector2i(0, 1), 3)
	revision = fov.revision_vision
	tablero.registrar_interactuable(Vector2i(1, 0), puerta)
	_comprobar(fov.revision_vision == revision + 1 and tablero.obtener_celda(Vector2i(2, 1)).visibilidad != Celda.EstadoVisibilidad.VISIBLE, "Registrar un bloqueador de dos casillas actualiza visión una sola vez.")
	var solapada := (load("res://scenes/interactuables/puertas/puerta_interactuable.tscn") as PackedScene).instantiate() as PuertaInteractuable
	solapada.id_instancia = &"fov_puerta_solapada"
	root.add_child(solapada)
	tablero.registrar_interactuable(Vector2i(1, 0), solapada)
	revision = fov.revision_vision
	tablero.retirar_interactuable(puerta)
	_comprobar(fov.revision_vision == revision + 1 and tablero.obtener_celda(Vector2i(2, 1)).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Retirar una huella recalcula también su segunda casilla aunque el origen siga opaco.")
	tablero.retirar_interactuable(solapada)
	solapada.queue_free()
	tablero.retirar_interactuable(npc)
	npc.queue_free()
	puerta.queue_free()

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
