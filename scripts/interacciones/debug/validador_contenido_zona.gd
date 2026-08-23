class_name ValidadorContenidoZona
extends RefCounted


func validar(zona: Node2D, tablero: TableroGrid, capa: TileMapLayer) -> Array[String]:
	var errores: Array[String] = []
	if zona == null or tablero == null or capa == null:
		return ["zona_tablero_o_capa_invalida"]

	var interactuables: Array[Interactuable] = []
	var ids_interactuables: Dictionary[StringName, Interactuable] = {}
	for nodo in zona.find_children("*", "", true, false):
		if nodo is Interactuable:
			interactuables.append(nodo)
			_validar_interactuable(nodo, tablero, capa, ids_interactuables, errores)

	for interactuable in interactuables:
		if interactuable is PalancaInteractuable:
			_validar_relaciones(interactuable, ids_interactuables, errores)

	var ids_superficies: Dictionary[StringName, bool] = {}
	for nodo in zona.find_children("*", "", true, false):
		if nodo.is_in_group(&"efectos_superficie"):
			_validar_superficie(nodo, tablero, capa, ids_superficies, errores)

	errores.sort()
	return errores


func _validar_interactuable(
	interactuable: Interactuable,
	tablero: TableroGrid,
	capa: TileMapLayer,
	ids: Dictionary[StringName, Interactuable],
	errores: Array[String]
) -> void:
	var contexto := _contexto_nodo(interactuable, capa)
	if interactuable.id_instancia == &"":
		errores.append("id_interactuable_vacio %s" % contexto)
	elif ids.has(interactuable.id_instancia):
		errores.append("id_interactuable_duplicado id=%s %s" % [interactuable.id_instancia, contexto])
	else:
		ids[interactuable.id_instancia] = interactuable
	if interactuable.definicion == null or not interactuable.definicion.es_valida():
		errores.append("definicion_interactuable_invalida id=%s %s" % [interactuable.id_instancia, contexto])
	if not tablero.es_celda_valida(_coordenada(interactuable, capa)):
		errores.append("interactuable_fuera_tablero id=%s %s" % [interactuable.id_instancia, contexto])


func _validar_relaciones(
	palanca: PalancaInteractuable,
	interactuables: Dictionary[StringName, Interactuable],
	errores: Array[String]
) -> void:
	var vistos: Dictionary[StringName, bool] = {}
	for id_receptor in palanca.ids_receptores_mecanismo:
		if id_receptor == &"":
			errores.append("id_receptor_mecanismo_vacio emisor=%s" % palanca.id_instancia)
			continue
		if vistos.has(id_receptor):
			errores.append("id_receptor_mecanismo_duplicado emisor=%s receptor=%s" % [palanca.id_instancia, id_receptor])
			continue
		vistos[id_receptor] = true
		var receptor := interactuables.get(id_receptor) as Interactuable
		if receptor == null:
			errores.append("receptor_mecanismo_inexistente emisor=%s receptor=%s" % [palanca.id_instancia, id_receptor])
		elif (
			not receptor.has_method(&"validar_cambio_mecanismo")
			or not receptor.has_method(&"aplicar_cambio_mecanismo")
		):
			errores.append("receptor_mecanismo_incompatible emisor=%s receptor=%s" % [palanca.id_instancia, id_receptor])


func _validar_superficie(
	superficie: Node,
	tablero: TableroGrid,
	capa: TileMapLayer,
	ids: Dictionary[StringName, bool],
	errores: Array[String]
) -> void:
	var contexto := _contexto_nodo(superficie, capa)
	if (
		not superficie.has_method(&"obtener_id_reaccion")
		or not superficie.has_method(&"configurar_registro")
	):
		errores.append("contrato_superficie_invalido %s" % contexto)
		return
	var id_superficie: Variant = superficie.call(&"obtener_id_reaccion")
	if not id_superficie is StringName or id_superficie == &"":
		errores.append("id_superficie_vacio %s" % contexto)
	elif ids.has(id_superficie):
		errores.append("id_superficie_duplicado id=%s %s" % [id_superficie, contexto])
	else:
		ids[id_superficie] = true
	if not tablero.es_celda_valida(_coordenada(superficie, capa)):
		errores.append("superficie_fuera_tablero id=%s %s" % [id_superficie, contexto])


func _coordenada(nodo: Node, capa: TileMapLayer) -> Vector2i:
	var nodo_2d := nodo as Node2D
	return capa.local_to_map(capa.to_local(nodo_2d.global_position))


func _contexto_nodo(nodo: Node, capa: TileMapLayer) -> String:
	return "nodo=%s celda=%s" % [nodo.get_path(), _coordenada(nodo, capa)]
