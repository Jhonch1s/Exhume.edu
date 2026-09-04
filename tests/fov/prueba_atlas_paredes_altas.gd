extends SceneTree


func _init() -> void:
	var paredes := load("res://assets/tile_sets/structures/walls_cave.tres") as TileSet
	var niebla := load("res://assets/tile_sets/fog/cave_fog.tres") as TileSet
	assert(paredes.has_source(0) and paredes.has_source(1) and paredes.has_source(2))
	var atlas := paredes.get_source(1) as TileSetAtlasSource
	for coordenada in [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
	]:
		assert(atlas.has_tile(coordenada))
		assert(atlas.get_tile_data(coordenada, 0).get_custom_data(&"altura") == 3)
	assert((paredes.get_source(2) as TileSetAtlasSource).has_tile(Vector2i.ZERO))
	for source_id in [10, 11, 12, 13]:
		assert(niebla.has_source(source_id))
	print("OK: atlas de paredes altas y sus máscaras cargan correctamente.")
	quit()
