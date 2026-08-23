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
	_comprobar(
		tablero.registrar_interactuables_desde_zona(zona, zona.get_node("CapaSuelo")),
		"Zona1 debe registrar todos sus interactuables."
	)
	var persistencia := PersistenciaInteractuables.new()
	var snapshot := persistencia.crear_snapshot(tablero, &"zona1")
	var copia_json: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_comprobar(copia_json is Dictionary, "El snapshot debe ser compatible con JSON.")
	_comprobar(
		persistencia.validar_restauracion(snapshot, tablero, &"zona1") == &""
		and persistencia.validar_restauracion(copia_json, tablero, &"zona1") == &"",
		"El snapshot en memoria y su copia JSON deben cumplir el mismo contrato."
	)

	var puerta := tablero.obtener_interactuable(&"zona1_puerta_04_m03") as PuertaInteractuable
	var palanca := tablero.obtener_interactuable(&"zona1_palanca_03_m03") as PalancaInteractuable
	var trampa := tablero.obtener_interactuable(&"zona1_trampa_humo_04_03") as TrampaSuperficie
	var luz := tablero.obtener_interactuable(&"zona1_antorcha_pie_02_01") as FuenteLuzInteractuable
	puerta.abierta = true
	puerta.bloqueada = false
	palanca.activada = true
	trampa.activada = true
	trampa.presentacion = TrampaSuperficie.Presentacion.VISIBLE
	luz.encendida = not luz.encendida

	var invalido: Dictionary = copia_json.duplicate(true)
	invalido["interactuables"][0]["definicion_id"] = "otra_definicion"
	var estado_antes := puerta.obtener_estado_persistente()
	_comprobar(
		persistencia.restaurar(invalido, tablero, &"zona1")
		== &"definicion_interactuable_no_coincide"
		and puerta.obtener_estado_persistente() == estado_antes,
		"Un snapshot invalido debe rechazarse sin restauracion parcial."
	)

	_comprobar(
		persistencia.restaurar(copia_json, tablero, &"zona1") == &"",
		"El snapshot valido debe restaurarse."
	)
	_comprobar(
		puerta.obtener_estado_persistente() == _estado(snapshot, puerta.id_instancia)
		and palanca.obtener_estado_persistente() == _estado(snapshot, palanca.id_instancia)
		and trampa.obtener_estado_persistente() == _estado(snapshot, trampa.id_instancia)
		and luz.obtener_estado_persistente() == _estado(snapshot, luz.id_instancia),
		"Puerta, palanca, trampa y luz deben recuperar su estado original."
	)

	tablero.queue_free()
	zona.queue_free()
	_finalizar()


func _estado(snapshot: Dictionary, id_entidad: StringName) -> Dictionary:
	for datos: Dictionary in snapshot["interactuables"]:
		if datos["id"] == String(id_entidad):
			return datos["estado"]
	return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("PersistenciaInteractuables: 5 grupos correctos.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)
