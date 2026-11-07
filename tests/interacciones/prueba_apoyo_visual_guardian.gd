extends SceneTree


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var capa := TileMapLayer.new()
	capa.tile_set = load("res://assets/tile_sets/terrain/cave_terrain.tres")
	root.add_child(capa)
	var guardian: PersonajeNPC = load("res://scenes/personajes/guardian.tscn").instantiate()
	root.add_child(guardian)
	var correcto := true
	for origen in [Vector2i.ZERO, Vector2i(4, -3)]:
		guardian.coordenada_mapa = origen
		guardian.position = capa.map_to_local(origen)
		var centro := Vector2.ZERO
		var huella := guardian.obtener_coordenadas_ocupadas()
		for celda in huella:
			centro += capa.to_global(capa.map_to_local(celda))
		centro /= huella.size()
		for frame in range(4):
			var sprite := guardian.sprite_personaje
			sprite.frame = frame
			# El render coloca el apoyo a 64 píxeles debajo del centro de cada cuadro.
			var apoyo := sprite.to_global(sprite.offset + Vector2(0, 64))
			correcto = correcto and apoyo.distance_to(centro) < 0.01
	print("ApoyoVisualGuardian: ", "correcto" if correcto else "fallo")
	guardian.queue_free()
	capa.queue_free()
	await process_frame
	quit(0 if correcto else 1)
