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
	for ruta in [
		"Interactuables/FuentesLuz", "Interactuables/Mecanismos",
		"Interactuables/Puertas", "Interactuables/Trampas", "PuntosSpawn",
		"EfectosSuperficie",
	]:
		assert(zona.has_node(ruta))
	var punto := (load(
		"res://scenes/zonas/PuntoSpawnZona.tscn"
	) as PackedScene).instantiate() as PuntoSpawnZona
	zona.get_node("PuntosSpawn").add_child(punto)
	var capa_suelo := zona.get_node("CapaSuelo") as TileMapLayer
	punto.global_position = capa_suelo.to_global(capa_suelo.map_to_local(Vector2i(3, 2)))
	assert(punto.id_spawn == &"entrada")
	assert(punto.obtener_coordenada(capa_suelo) == Vector2i(3, 2))
	zona.queue_free()
	print("PlantillaZona: prueba correcta.")
	quit()
