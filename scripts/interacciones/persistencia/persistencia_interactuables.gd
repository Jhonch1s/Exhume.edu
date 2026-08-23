class_name PersistenciaInteractuables
extends RefCounted

const VERSION := 1


func crear_snapshot(tablero: TableroGrid, id_zona: StringName) -> Dictionary:
	if tablero == null or not is_instance_valid(tablero) or id_zona == &"":
		return {}
	var entidades: Array[Dictionary] = []
	var ids: Array[StringName] = []
	ids.assign(tablero.interactuables_por_id.keys())
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for id_entidad in ids:
		var entidad := tablero.obtener_interactuable(id_entidad)
		if entidad == null or entidad.definicion == null:
			return {}
		entidades.append({
			"id": String(entidad.id_instancia),
			"definicion_id": String(entidad.definicion.id_definicion),
			"coordenada": [entidad.coordenada_mapa.x, entidad.coordenada_mapa.y],
			"estado": entidad.obtener_estado_persistente(),
		})
	return {
		"version": VERSION,
		"zona_id": String(id_zona),
		"interactuables": entidades,
	}


func validar_restauracion(
	snapshot: Dictionary,
	tablero: TableroGrid,
	id_zona: StringName
) -> StringName:
	if tablero == null or not is_instance_valid(tablero):
		return &"tablero_persistencia_invalido"
	if snapshot.get("version") != VERSION:
		return &"version_guardado_no_admitida"
	if snapshot.get("zona_id") != String(id_zona):
		return &"zona_guardado_no_coincide"
	var datos_entidades: Variant = snapshot.get("interactuables")
	if not datos_entidades is Array:
		return &"interactuables_guardado_invalidos"
	var vistos: Dictionary[StringName, bool] = {}
	for datos: Variant in datos_entidades:
		var motivo := _validar_entidad(datos, tablero, vistos)
		if motivo != &"":
			return motivo
	if vistos.size() != tablero.interactuables_por_id.size():
		return &"interactuables_guardado_incompletos"
	return &""


func restaurar(
	snapshot: Dictionary,
	tablero: TableroGrid,
	id_zona: StringName
) -> StringName:
	var motivo := validar_restauracion(snapshot, tablero, id_zona)
	if motivo != &"":
		return motivo
	for datos: Dictionary in snapshot["interactuables"]:
		var entidad := tablero.obtener_interactuable(StringName(datos["id"]))
		motivo = entidad.restaurar_estado_persistente(datos["estado"])
		if motivo != &"":
			return motivo
	return &""


func _validar_entidad(
	datos: Variant,
	tablero: TableroGrid,
	vistos: Dictionary[StringName, bool]
) -> StringName:
	if not datos is Dictionary:
		return &"interactuable_guardado_invalido"
	if not datos.has("id") or not datos["id"] is String or datos["id"].is_empty():
		return &"id_interactuable_guardado_invalido"
	var id_entidad := StringName(datos["id"])
	if vistos.has(id_entidad):
		return &"id_interactuable_guardado_duplicado"
	vistos[id_entidad] = true
	var entidad := tablero.obtener_interactuable(id_entidad)
	if entidad == null:
		return &"interactuable_guardado_inexistente"
	if (
		not datos.has("definicion_id")
		or datos["definicion_id"] != String(entidad.definicion.id_definicion)
	):
		return &"definicion_interactuable_no_coincide"
	if (
		not datos.has("coordenada")
		or not datos["coordenada"] is Array
		or datos["coordenada"].size() != 2
		or not _es_numero_entero(datos["coordenada"][0])
		or not _es_numero_entero(datos["coordenada"][1])
		or Vector2i(datos["coordenada"][0], datos["coordenada"][1]) != entidad.coordenada_mapa
	):
		return &"coordenada_interactuable_no_coincide"
	if not datos.has("estado") or not datos["estado"] is Dictionary:
		return &"estado_interactuable_guardado_invalido"
	return entidad.validar_estado_persistente(datos["estado"])


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))
