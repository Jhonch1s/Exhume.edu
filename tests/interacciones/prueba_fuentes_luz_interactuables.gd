extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	var escena := load("res://scenes/Zona1/zona_1.tscn") as PackedScene
	_comprobar(escena != null, "La zona debe cargar con las fuentes como escenas.")
	if escena == null:
		_finalizar()
		return

	var zona := escena.instantiate() as Node2D
	root.add_child(zona)
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	var registro_valido := tablero.registrar_interactuables_desde_zona(zona, capa_suelo)

	_comprobar(registro_valido, "Todas las fuentes migradas deben registrarse.")
	_comprobar(
		tablero.interactuables_por_id.size() == 11,
		"La migracion debe conservar las once fuentes de CapaLuces."
	)

	var fuente := tablero.obtener_interactuable(&"zona1_antorcha_pie_02_01")
	_comprobar(fuente is FuenteLuzInteractuable, "La antorcha debe ser un interactuable.")
	if fuente is FuenteLuzInteractuable:
		_probar_registro_luz(tablero, fuente)
		_probar_id_duplicado(tablero, fuente)
		_probar_accion_apagar(fuente)
	_probar_sombra_logica()

	tablero.queue_free()
	zona.queue_free()
	_finalizar()


func _probar_registro_luz(
	tablero: TableroGrid,
	fuente: FuenteLuzInteractuable
) -> void:
	_comprobar(fuente.coordenada_mapa == Vector2i(2, 1), "Debe conservar su celda.")
	var celda := tablero.obtener_celda(Vector2i(2, 1))
	_comprobar(fuente in celda.interactuables, "Debe registrarse como interactuable.")
	_comprobar(fuente in celda.iluminacion, "Debe registrarse como fuente de luz.")
	_comprobar(celda.familia_fog == &"luz", "Debe conservar su mascara de fog.")
	_comprobar(
		celda.coordenada_fog == Vector2i(1, 6),
		"Debe conservar la coordenada de la sombra propia de la antorcha."
	)
	var definicion := fuente.obtener_definicion_luz()
	_comprobar(definicion.radio_luz == 1, "Debe cargar el radio desde el Resource.")
	_comprobar(definicion.radio_penumbra == 2, "Debe cargar la penumbra desde el Resource.")
	_comprobar(not definicion.atraviesa_muros, "Las paredes deben ocluir la luz.")
	_comprobar(
		definicion.desplazamiento_sprite == Vector2(0, -32),
		"Las fuentes deben heredar el anclaje isometrico predeterminado."
	)


func _probar_accion_apagar(fuente: FuenteLuzInteractuable) -> void:
	# La zona puede guardar cada instancia encendida o apagada; este caso fuerza
	# explícitamente el estado inicial que necesita probar.
	fuente.encendida = true
	var opciones := fuente.obtener_opciones_accion()
	_comprobar(
		opciones.size() == 2,
		"Una fuente examinable encendida debe publicar Examinar y Apagar."
	)
	_comprobar(opciones[0].id == &"examinar", "Examinar debe publicarse primero.")
	_comprobar(opciones[1].id == &"apagar", "La accion de estado debe ser Apagar.")
	var actor := Node.new()
	var contexto := ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		actor,
		fuente.coordenada_mapa,
		fuente.coordenada_mapa,
		fuente,
		null,
		&"apagar"
	)
	var resultado := fuente.resolver_accion(contexto)
	_comprobar(resultado.exitosa, "Apagar una fuente encendida debe tener exito.")
	_comprobar(not fuente.encendida, "El estado persistente debe quedar apagado.")
	_comprobar(
		fuente.sprite.region_rect == fuente.obtener_definicion_luz().region_apagada,
		"El sprite debe responder al estado confirmado."
	)
	_comprobar(
		fuente.obtener_opciones_accion()[1].id == &"encender",
		"Una fuente apagada debe publicar Encender."
	)
	actor.free()


func _probar_id_duplicado(
	tablero: TableroGrid,
	interactuable_original: FuenteLuzInteractuable
) -> void:
	var celda := tablero.obtener_celda(interactuable_original.coordenada_mapa)
	var cantidad_ids_anterior := tablero.interactuables_por_id.size()
	var cantidad_celda_anterior := celda.interactuables.size()
	var duplicado := Interactuable.new()
	duplicado.id_instancia = interactuable_original.id_instancia

	_comprobar(
		tablero.validar_registro_interactuable(
			interactuable_original.coordenada_mapa,
			duplicado
		) == &"id_instancia_duplicado",
		"La validacion debe identificar el ID duplicado con un motivo estable."
	)
	_comprobar(
		not tablero.registrar_interactuable(
			interactuable_original.coordenada_mapa,
			duplicado
		),
		"El tablero debe rechazar el segundo interactuable con el mismo ID."
	)
	_comprobar(
		tablero.interactuables_por_id.size() == cantidad_ids_anterior,
		"Un ID duplicado no debe modificar el indice del tablero."
	)
	_comprobar(
		tablero.obtener_interactuable(interactuable_original.id_instancia)
		== interactuable_original,
		"El ID duplicado no debe sustituir la instancia original."
	)
	_comprobar(
		celda.interactuables.size() == cantidad_celda_anterior
		and duplicado not in celda.interactuables,
		"El interactuable rechazado no debe agregarse a la celda."
	)
	duplicado.free()


func _probar_sombra_logica() -> void:
	var fuente := FuenteLuzInteractuable.new()
	var definicion := DefinicionFuenteLuz.new()
	definicion.id_definicion = &"luz_prueba"
	definicion.nombre = "Luz de prueba"
	definicion.radio_luz = 3
	definicion.radio_penumbra = 0
	definicion.atraviesa_muros = false
	fuente.definicion = definicion
	fuente.encendida = true

	var celdas: Dictionary[Vector2i, Celda] = {}
	for x in range(3):
		celdas[Vector2i(x, 0)] = Celda.new()
	celdas[Vector2i(0, 0)].iluminacion.append(fuente)
	celdas[Vector2i(1, 0)].bloquea_vision = true

	var gestor := FOVManager.new()
	gestor.datos_tablero = celdas
	gestor.capa_oscuridad = TileMapLayer.new()
	gestor._procesar_luces_mapa()

	_comprobar(
		celdas[Vector2i(1, 0)].visibilidad == Celda.EstadoVisibilidad.VISIBLE,
		"La pared que recibe la luz debe quedar visible."
	)
	_comprobar(
		celdas[Vector2i(2, 0)].visibilidad == Celda.EstadoVisibilidad.OCULTO,
		"La celda detras de la pared debe permanecer en sombra."
	)
	fuente.free()
	gestor.capa_oscuridad.free()
	gestor.free()


func _finalizar() -> void:
	if _fallos.is_empty():
		print("FuentesLuzInteractuables: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
