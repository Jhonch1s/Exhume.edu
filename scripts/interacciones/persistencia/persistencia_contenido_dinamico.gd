class_name PersistenciaContenidoDinamico
extends RefCounted


func obtener_items_suelo(tablero: TableroGrid) -> Array[Dictionary]:
	var datos: Array[Dictionary] = []
	var ids: Array[StringName] = []
	ids.assign(tablero.items_suelo_por_id.keys())
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for id_item in ids:
		var item_suelo := tablero.obtener_item_suelo(id_item)
		var item := item_suelo.item
		datos.append({
			"id": String(item.id_instancia),
			"definicion_id": String(item.definicion.id_definicion),
			"definicion_path": item.definicion.resource_path,
			"cantidad": item.cantidad,
			"coordenada": [item_suelo.coordenada_mapa.x, item_suelo.coordenada_mapa.y],
		})
	return datos


func obtener_superficies(tablero: TableroGrid) -> Variant:
	var datos: Array[Dictionary] = []
	var ids: Array[StringName] = []
	ids.assign(tablero.efectos_superficie_por_id.keys())
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for id_superficie in ids:
		var superficie: Object = tablero.efectos_superficie_por_id[id_superficie]
		if not superficie is Node or not superficie.has_method(&"obtener_turnos_restantes_superficie"):
			return null
		datos.append({
			"id": String(id_superficie),
			"scene_path": (superficie as Node).scene_file_path,
			"coordenada": [
				superficie.call(&"obtener_coordenada_reaccion").x,
				superficie.call(&"obtener_coordenada_reaccion").y,
			],
			"turnos_restantes": superficie.call(&"obtener_turnos_restantes_superficie"),
		})
	return datos


func validar(
	items: Variant,
	superficies: Variant,
	tablero: TableroGrid,
	ids_inventario: Dictionary[String, bool]
) -> StringName:
	if not items is Array or not superficies is Array:
		return &"contenido_dinamico_guardado_invalido"
	var ids_items := ids_inventario.duplicate()
	for datos: Variant in items:
		var motivo := _validar_item(datos, tablero, ids_items)
		if motivo != &"":
			return motivo
	var ids_superficies: Dictionary[String, bool] = {}
	for datos: Variant in superficies:
		var motivo := _validar_superficie(datos, tablero, ids_superficies)
		if motivo != &"":
			return motivo
	return &""


func restaurar(items: Array, superficies: Array, tablero: TableroGrid) -> StringName:
	var items_nuevos: Array[Dictionary] = []
	for datos: Dictionary in items:
		var definicion := ResourceLoader.load(datos["definicion_path"]) as DefinicionItem
		items_nuevos.append({
			"coordenada": Vector2i(datos["coordenada"][0], datos["coordenada"][1]),
			"item": ItemSuelo.new(ItemInstancia.new(
				StringName(datos["id"]), definicion, int(datos["cantidad"])
			)),
		})
	var superficies_nuevas: Array[Dictionary] = []
	for datos: Dictionary in superficies:
		var escena := ResourceLoader.load(datos["scene_path"]) as PackedScene
		var superficie := escena.instantiate() as Node2D
		superficie.call(&"configurar_id_instancia", StringName(datos["id"]))
		superficie.call(&"restaurar_turnos_restantes_superficie", int(datos["turnos_restantes"]))
		superficies_nuevas.append({
			"coordenada": Vector2i(datos["coordenada"][0], datos["coordenada"][1]),
			"superficie": superficie,
		})

	for item_suelo in tablero.items_suelo_por_id.values().duplicate():
		tablero.retirar_item_suelo(item_suelo)
	for superficie in tablero.efectos_superficie_por_id.values().duplicate():
		tablero.retirar_efecto_superficie(superficie)
		(superficie as Node).queue_free()
	for preparado in items_nuevos:
		tablero.registrar_item_suelo(preparado["coordenada"], preparado["item"])
	var contenedor := tablero.zona_referencia.get_node("EfectosSuperficie") as Node2D
	for preparado in superficies_nuevas:
		var superficie: Node2D = preparado["superficie"]
		contenedor.add_child(superficie)
		superficie.global_position = tablero.capa_referencia.to_global(
			tablero.capa_referencia.map_to_local(preparado["coordenada"])
		)
		tablero.registrar_efecto_superficie(preparado["coordenada"], superficie)
	return &""


func _validar_item(
	datos: Variant,
	tablero: TableroGrid,
	ids: Dictionary[String, bool]
) -> StringName:
	if not datos is Dictionary:
		return &"item_suelo_guardado_invalido"
	var id_item: Variant = datos.get("id")
	var id_definicion: Variant = datos.get("definicion_id")
	var ruta: Variant = datos.get("definicion_path")
	if (
		not id_item is String or id_item.is_empty() or ids.has(id_item)
		or not id_definicion is String or id_definicion.is_empty()
		or not ruta is String or ruta.is_empty() or not ResourceLoader.exists(ruta)
		or not _es_numero_entero(datos.get("cantidad"))
		or not _coordenada_valida(datos.get("coordenada"), tablero)
	):
		return &"item_suelo_guardado_invalido"
	var definicion := ResourceLoader.load(ruta) as DefinicionItem
	var item := ItemInstancia.new(StringName(id_item), definicion, int(datos["cantidad"]))
	if definicion == null or String(definicion.id_definicion) != id_definicion or not item.es_valida():
		return &"definicion_item_guardada_invalida"
	ids[id_item] = true
	return &""


func _validar_superficie(
	datos: Variant,
	tablero: TableroGrid,
	ids: Dictionary[String, bool]
) -> StringName:
	if not datos is Dictionary:
		return &"superficie_guardada_invalida"
	var id_superficie: Variant = datos.get("id")
	var ruta: Variant = datos.get("scene_path")
	if (
		not id_superficie is String or id_superficie.is_empty() or ids.has(id_superficie)
		or not ruta is String or ruta.is_empty() or not ResourceLoader.exists(ruta, "PackedScene")
		or not _es_numero_entero(datos.get("turnos_restantes"))
		or not _coordenada_valida(datos.get("coordenada"), tablero)
	):
		return &"superficie_guardada_invalida"
	var escena := ResourceLoader.load(ruta) as PackedScene
	var superficie := escena.instantiate() if escena != null else null
	var valida: bool = (
		superficie is Node2D
		and superficie.has_method(&"configurar_id_instancia")
		and superficie.has_method(&"restaurar_turnos_restantes_superficie")
		and superficie.call(
			&"restaurar_turnos_restantes_superficie", int(datos["turnos_restantes"])
		) == &""
	)
	if superficie != null:
		superficie.free()
	if not valida:
		return &"superficie_guardada_invalida"
	ids[id_superficie] = true
	return &""


func _coordenada_valida(valor: Variant, tablero: TableroGrid) -> bool:
	return (
		valor is Array and valor.size() == 2
		and _es_numero_entero(valor[0]) and _es_numero_entero(valor[1])
		and tablero.es_celda_valida(Vector2i(valor[0], valor[1]))
	)


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))
