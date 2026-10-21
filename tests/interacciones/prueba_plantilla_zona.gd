extends SceneTree


func _init() -> void:
	var zona := (load("res://scenes/ZonaPlantilla/zona_plantilla.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	assert(zona is ZonaExplorable)
	assert(zona.has_method(&"_iniciar_prueba_individual"))
	var capas := [
		"CapaAgua", "CapaLava", "CapaSuelo", "CapaParedes", "CapaColumnas",
		"CapaDecoracionNoCaminable", "CapaDecoracion", "CapaOscuridad",
		"CapaPinchos", "CapaLodo", "CapaHielo", "CapaFuego", "CapaTelaraña",
	]
	for nombre in capas:
		var capa := zona.get_node_or_null(nombre) as TileMapLayer
		assert(capa != null and capa.tile_set != null and capa.get_used_cells().is_empty())
	assert(zona.get_node("CapaParedes") is CapaParedesOclusivas)
	for ruta in [
		"Interactuables/FuentesLuz", "Interactuables/Mecanismos",
		"Interactuables/Puertas", "Interactuables/Trampas",
		"Interactuables/Decoraciones", "Interactuables/Cofres",
		"Interactuables/Personajes", "Interactuables/Guias", "ItemsSuelo",
		"PuntosSpawn", "EfectosSuperficie",
	]:
		assert(zona.has_node(ruta))
	assert(zona.get_node("ItemsSuelo").is_in_group("items_suelo"))
	var punto := zona.get_node("PuntosSpawn/PuntoSpawnEntrada") as PuntoSpawnZona
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	punto.global_position = capa_suelo.to_global(capa_suelo.map_to_local(Vector2i(3, 2)))
	assert(punto.id_spawn == &"entrada")
	assert(punto.obtener_coordenada(capa_suelo) == Vector2i(3, 2))
	var decoracion_solida := zona.get_node("CapaDecoracionNoCaminable") as TileMapLayer
	var decoracion_caminable := zona.get_node("CapaDecoracion") as TileMapLayer
	assert(decoracion_solida.tile_set.get_source_count() == 3)
	assert(decoracion_caminable.tile_set.get_source_count() == 5)
	var coord := Vector2i(3, 2)
	capa_suelo.set_cell(coord, 0, Vector2i.ZERO)
	decoracion_solida.set_cell(coord, 0, Vector2i.ZERO)
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	assert(not tablero.datos[coord].caminable)
	decoracion_solida.erase_cell(coord)
	decoracion_caminable.set_cell(coord, 1, Vector2i.ZERO)
	tablero.generar_desde_zona(zona)
	assert(tablero.datos[coord].caminable)
	var descanso := (load("res://scenes/DescansoCuevas/DescansoCuevas.tscn") as PackedScene).instantiate()
	root.add_child(descanso)
	assert(descanso is ZonaExplorable)
	assert(descanso.get_node("CapaParedes") is CapaParedesOclusivas)
	var suelo_descanso := descanso.get_node("CapaSuelo") as TileMapLayer
	assert(not suelo_descanso.get_used_cells().is_empty())
	var entrada_descanso := descanso.get_node("PuntosSpawn/PuntoSpawnEntrada") as PuntoSpawnZona
	assert(suelo_descanso.get_cell_source_id(entrada_descanso.obtener_coordenada(suelo_descanso)) >= 0)
	assert(descanso.has_node("Interactuables/FuentesLuz/FogataDescanso"))
	assert((descanso.get_node("CapaDecoracion") as TileMapLayer).tile_set.resource_path == decoracion_caminable.tile_set.resource_path)
	assert((descanso.get_node("CapaDecoracionNoCaminable") as TileMapLayer).tile_set.resource_path == decoracion_solida.tile_set.resource_path)
	descanso.queue_free()
	zona.queue_free()
	print("PlantillaZona: prueba correcta.")
	quit()
