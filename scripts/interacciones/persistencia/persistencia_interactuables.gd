class_name PersistenciaInteractuables
extends RefCounted

const VERSION := 2
const VERSION_ANTERIOR := 1


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
	if snapshot.get("version") != VERSION and snapshot.get("version") != VERSION_ANTERIOR:
		return &"version_guardado_no_admitida"
	if snapshot.get("zona_id") != String(id_zona):
		return &"zona_guardado_no_coincide"
	var datos_entidades: Variant = snapshot.get("interactuables")
	if not datos_entidades is Array:
		return &"interactuables_guardado_invalidos"
	var vistos: Dictionary[StringName, bool] = {}
	for datos: Variant in datos_entidades:
		var motivo := _validar_entidad(
			datos, tablero, vistos, snapshot["version"] == VERSION_ANTERIOR
		)
		if motivo != &"":
			return motivo
	if vistos.size() != tablero.interactuables_por_id.size():
		return &"interactuables_guardado_incompletos"
	return validar_posiciones(snapshot, tablero)


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
	for datos: Dictionary in snapshot["interactuables"]:
		var entidad := tablero.obtener_interactuable(StringName(datos["id"]))
		if entidad.admite_restaurar_posicion():
			var coord := Vector2i(datos["coordenada"][0], datos["coordenada"][1])
			if not tablero.reubicar_interactuable(entidad, coord):
				return &"posicion_interactuable_no_restaurada"
			entidad.actualizar_posicion_visual()
	return &""


## Todas las ubicaciones se comparan con el estado guardado, no con el estado vivo.
func validar_posiciones(
	snapshot: Dictionary, tablero: TableroGrid, posicion_jugador: Variant = null
) -> StringName:
	var bloqueadas: Dictionary[Vector2i, Array] = {}
	for datos: Dictionary in snapshot["interactuables"]:
		var entidad := tablero.obtener_interactuable(StringName(datos["id"]))
		var destino := Vector2i(datos["coordenada"][0], datos["coordenada"][1])
		if not entidad.permite_caminar_estado_guardado(datos["estado"]):
			for coord in entidad.obtener_coordenadas_ocupadas(destino):
				if not bloqueadas.has(coord):
					bloqueadas[coord] = []
				bloqueadas[coord].append(entidad.id_instancia)
	for datos: Dictionary in snapshot["interactuables"]:
		var entidad := tablero.obtener_interactuable(StringName(datos["id"]))
		if not entidad.admite_restaurar_posicion():
			continue
		var destino := Vector2i(datos["coordenada"][0], datos["coordenada"][1])
		for coord in entidad.obtener_coordenadas_ocupadas(destino):
			var celda := tablero.obtener_celda(coord)
			if celda == null or not celda.caminable:
				return &"posicion_movil_guardada_invalida"
			for id_bloqueo: StringName in bloqueadas.get(coord, []):
				if id_bloqueo != entidad.id_instancia:
					return &"posiciones_guardadas_superpuestas"
			if posicion_jugador == coord and not entidad.permite_caminar_estado_guardado(datos["estado"]):
				return &"posiciones_guardadas_superpuestas"
	if posicion_jugador != null and bloqueadas.has(posicion_jugador):
		return &"posicion_ficha_guardada_bloqueada"
	return &""


func _validar_entidad(
	datos: Variant,
	tablero: TableroGrid,
	vistos: Dictionary[StringName, bool],
	es_version_anterior: bool
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
	):
		return &"coordenada_interactuable_no_coincide"
	var destino := Vector2i(datos["coordenada"][0], datos["coordenada"][1])
	if not entidad.admite_restaurar_posicion() and destino != entidad.coordenada_mapa:
		return &"coordenada_interactuable_no_coincide"
	for coord in entidad.obtener_coordenadas_ocupadas(destino):
		if not tablero.es_celda_valida(coord):
			return &"posicion_movil_guardada_invalida"
	if not datos.has("estado") or not datos["estado"] is Dictionary:
		return &"estado_interactuable_guardado_invalido"
	if es_version_anterior and entidad is PersonajeNPC and datos["estado"].is_empty():
		return &""
	return entidad.validar_estado_persistente(datos["estado"])


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))
