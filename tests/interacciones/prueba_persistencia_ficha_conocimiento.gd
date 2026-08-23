extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var zona := (load("res://scenes/Zona1/zona_1.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var tablero := TableroGrid.new()
	root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	tablero.registrar_interactuables_desde_zona(zona, zona.get_node("CapaSuelo"))
	var ficha := (load("res://scenes/ficha/ficha.tscn") as PackedScene).instantiate() as Ficha
	root.add_child(ficha)
	ficha.inicializar(Vector2i(2, 1), zona.get_node("CapaSuelo"))
	ficha.pv_actual -= 2
	ficha.energia_actual -= 7
	ficha.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, 2)
	ficha.aplicar_o_renovar_estado(&"veneno", 1.0, 2, 1)
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	ficha.inventario.agregar(ItemInstancia.new(&"piedras_guardadas", piedra, 3))
	var conocimiento := RegistroConocimiento.new()
	var fragmento := FragmentoInformacion.new()
	fragmento.id_fragmento = &"identidad"
	fragmento.id_mensaje = &"examen.prueba"
	fragmento.se_recuerda = true
	conocimiento.registrar_descubrimientos(
		ficha.id_observador, &"zona1_antorcha_pie_02_01", [fragmento]
	)

	var persistencia := PersistenciaPartida.new()
	var snapshot := persistencia.crear_snapshot(tablero, &"zona1", ficha, conocimiento)
	var copia_json: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_comprobar(
		copia_json is Dictionary
		and persistencia.validar_restauracion(
			snapshot, tablero, &"zona1", ficha, conocimiento
		) == &""
		and persistencia.validar_restauracion(
			copia_json, tablero, &"zona1", ficha, conocimiento
		) == &"",
		"Ficha y conocimiento deben producir un snapshot JSON valido."
	)

	ficha.coordenada_mapa = Vector2i.ZERO
	ficha.pv_actual = ficha.pv_max
	ficha.energia_actual = ficha.energia_maxima
	ficha.iniciar_turno()
	ficha.inventario = Inventario.new()
	ficha.consumir_tick_estado(&"veneno")
	conocimiento.restaurar_estado_persistente([])
	_comprobar(
		persistencia.restaurar(copia_json, tablero, &"zona1", ficha, conocimiento) == &"",
		"La partida valida debe restaurarse."
	)
	_comprobar(
		ficha.coordenada_mapa == Vector2i(2, 1)
		and ficha.pv_actual == ficha.pv_max - 2
		and ficha.energia_actual == ficha.energia_maxima - 7
		and ficha.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 5
		and ficha.obtener_estado(&"veneno").ticks_pendientes == 1
		and ficha.inventario.obtener_por_id(&"piedras_guardadas").cantidad == 3,
		"La ficha debe recuperar posicion, recursos, estado e inventario."
	)
	_comprobar(
		conocimiento.conoce_fragmento(
			ficha.id_observador, &"zona1_antorcha_pie_02_01", &"identidad"
		),
		"El conocimiento descubierto debe recuperarse."
	)

	var invalido: Dictionary = copia_json.duplicate(true)
	invalido["ficha"]["inventario"][0]["definicion_id"] = "otra"
	var energia_antes := ficha.energia_actual
	_comprobar(
		persistencia.restaurar(invalido, tablero, &"zona1", ficha, conocimiento)
		== &"definicion_item_guardada_invalida"
		and ficha.energia_actual == energia_antes,
		"Una definicion de item incompatible debe rechazarse antes de mutar."
	)

	tablero.queue_free()
	zona.queue_free()
	ficha.queue_free()
	_finalizar()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PersistenciaFichaConocimiento: 5 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
