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
	tablero.registrar_efectos_superficie_desde_zona(zona, zona.get_node("CapaSuelo"))
	var piedra := load("res://assets/items/piedra/piedra.tres") as DefinicionItem
	tablero.registrar_item_suelo(
		Vector2i(2, 1), ItemSuelo.new(ItemInstancia.new(&"piedras_suelo", piedra, 2))
	)
	var superficie: Object = tablero.efectos_superficie_por_id.values()[0]
	for _paso in range(3):
		superficie.call(&"consumir_turno_superficie")
	var ficha := (load("res://scenes/ficha/ficha.tscn") as PackedScene).instantiate() as Ficha
	root.add_child(ficha)
	ficha.inicializar(Vector2i(2, 1), zona.get_node("CapaSuelo"))
	ficha.inventario.agregar(ItemInstancia.new(&"piedras_inventario", piedra, 1))
	var conocimiento := RegistroConocimiento.new()
	var persistencia := PersistenciaPartida.new()
	var snapshot := persistencia.crear_snapshot(tablero, &"zona1", ficha, conocimiento)
	var copia_json: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	_comprobar(
		persistencia.validar_restauracion(
			copia_json, tablero, &"zona1", ficha, conocimiento
		) == &"",
		"Items de suelo y superficies deben producir un snapshot JSON valido."
	)

	tablero.retirar_item_suelo(tablero.obtener_item_suelo(&"piedras_suelo"))
	var humo_extra := (load("res://scenes/efectos_superficie/Humo.tscn") as PackedScene).instantiate()
	humo_extra.call(&"configurar_id_instancia", &"humo_extra")
	zona.get_node("EfectosSuperficie").add_child(humo_extra)
	tablero.registrar_efecto_superficie(Vector2i(2, 1), humo_extra)
	superficie.call(&"consumir_turno_superficie")
	_comprobar(
		persistencia.restaurar(copia_json, tablero, &"zona1", ficha, conocimiento) == &"",
		"El contenido dinamico valido debe restaurarse."
	)
	var restaurada: Object = tablero.efectos_superficie_por_id.get(
		StringName(copia_json["superficies"][0]["id"])
	)
	_comprobar(
		tablero.obtener_item_suelo(&"piedras_suelo").item.cantidad == 2
		and not tablero.efectos_superficie_por_id.has(&"humo_extra")
		and restaurada.call(&"obtener_turnos_restantes_superficie") == 7,
		"El snapshot debe reemplazar exactamente items, superficies y duracion."
	)

	var duplicado := copia_json.duplicate(true)
	duplicado["items_suelo"][0]["id"] = "piedras_inventario"
	var cantidad_antes := tablero.items_suelo_por_id.size()
	_comprobar(
		persistencia.restaurar(duplicado, tablero, &"zona1", ficha, conocimiento)
		== &"item_suelo_guardado_invalido"
		and tablero.items_suelo_por_id.size() == cantidad_antes,
		"Un item repetido entre inventario y suelo debe rechazarse sin mutar."
	)

	for efecto in tablero.efectos_superficie_por_id.values().duplicate():
		tablero.retirar_efecto_superficie(efecto)
		(efecto as Node).queue_free()
	tablero.queue_free()
	zona.queue_free()
	ficha.queue_free()
	await process_frame
	_finalizar()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PersistenciaContenidoDinamico: 4 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
