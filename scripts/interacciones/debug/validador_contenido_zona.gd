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
			_validar_relaciones(
				interactuable,
				interactuable.ids_receptores_mecanismo,
				ids_interactuables,
				errores
			)
		elif interactuable is TrampaSuperficie:
			var trampa := interactuable as TrampaSuperficie
			if not trampa.ids_receptores_mecanismo.is_empty():
				_validar_relaciones(
					trampa,
					trampa.ids_receptores_mecanismo,
					ids_interactuables,
					errores
				)

	var ids_superficies: Dictionary[StringName, bool] = {}
	for nodo in zona.find_children("*", "", true, false):
		if nodo.is_in_group(&"efectos_superficie"):
			_validar_superficie(nodo, tablero, capa, ids_superficies, errores)

	var ids_spawn: Dictionary[StringName, bool] = {}
	for nodo in zona.find_children("*", "", true, false):
		if nodo is PuntoSpawnZona:
			_validar_punto_spawn(nodo, tablero, capa, ids_spawn, errores)

	errores.sort()
	return errores


func _validar_punto_spawn(
	punto: PuntoSpawnZona,
	tablero: TableroGrid,
	capa: TileMapLayer,
	ids: Dictionary[StringName, bool],
	errores: Array[String]
) -> void:
	var coordenada := punto.obtener_coordenada(capa)
	if punto.id_spawn == &"":
		errores.append("id_spawn_vacio nodo=%s" % punto.get_path())
	elif ids.has(punto.id_spawn):
		errores.append("id_spawn_duplicado id=%s" % punto.id_spawn)
	else:
		ids[punto.id_spawn] = true
	if not tablero.puede_entrar(coordenada):
		errores.append("spawn_fuera_celda_caminable id=%s celda=%s" % [
			punto.id_spawn, coordenada,
		])


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
	_validar_presentacion_interactuable(interactuable, contexto, errores)
	var coordenada := _coordenada(interactuable, capa)
	if not tablero.es_celda_valida(coordenada):
		errores.append("interactuable_fuera_tablero id=%s %s" % [interactuable.id_instancia, contexto])
	else:
		for coordenada_ocupada in interactuable.obtener_coordenadas_ocupadas(coordenada):
			if not tablero.es_celda_valida(coordenada_ocupada):
				errores.append("huella_interactuable_fuera_tablero id=%s celda=%s %s" % [
					interactuable.id_instancia, coordenada_ocupada, contexto,
				])
				break


func _validar_presentacion_interactuable(
	interactuable: Interactuable,
	contexto: String,
	errores: Array[String]
) -> void:
	var visual: Sprite2D = null
	if not interactuable.ruta_visual_resaltable.is_empty():
		visual = interactuable.get_node_or_null(interactuable.ruta_visual_resaltable) as Sprite2D
	if visual == null or visual.texture == null:
		errores.append("visual_resaltable_invalido id=%s %s" % [interactuable.id_instancia, contexto])
	if interactuable.color_resaltado.a <= 0.0 or interactuable.grosor_resaltado < 1.0:
		errores.append("resaltado_invisible id=%s %s" % [interactuable.id_instancia, contexto])
	for ruta in [interactuable.ruta_fog_oculto, interactuable.ruta_fog_explorado]:
		if not ruta.is_empty() and not interactuable.get_node_or_null(ruta) is Sprite2D:
			errores.append("mascara_fog_invalida id=%s ruta=%s %s" % [interactuable.id_instancia, ruta, contexto])


func _validar_relaciones(
	emisor: Interactuable,
	ids_receptores: Array[StringName],
	interactuables: Dictionary[StringName, Interactuable],
	errores: Array[String]
) -> void:
	var vistos: Dictionary[StringName, bool] = {}
	for id_receptor in ids_receptores:
		if id_receptor == &"":
			errores.append("id_receptor_mecanismo_vacio emisor=%s" % emisor.id_instancia)
			continue
		if vistos.has(id_receptor):
			errores.append("id_receptor_mecanismo_duplicado emisor=%s receptor=%s" % [emisor.id_instancia, id_receptor])
			continue
		vistos[id_receptor] = true
		var receptor := interactuables.get(id_receptor) as Interactuable
		if receptor == null:
			errores.append("receptor_mecanismo_inexistente emisor=%s receptor=%s" % [emisor.id_instancia, id_receptor])
		elif (
			not receptor.has_method(&"validar_cambio_mecanismo")
			or not receptor.has_method(&"aplicar_cambio_mecanismo")
		):
			errores.append("receptor_mecanismo_incompatible emisor=%s receptor=%s" % [emisor.id_instancia, id_receptor])


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
