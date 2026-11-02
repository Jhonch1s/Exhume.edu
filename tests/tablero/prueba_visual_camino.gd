extends SceneTree


func _initialize() -> void:
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	var capa := escenario.get_node("CapaCamino") as TileMapLayer
	var suelo := escenario.get_node("Zona/CapaSuelo") as TileMapLayer
	assert(capa.z_index > suelo.z_index and capa.z_index < 0)
	var buscador := PathFindingManager.new()
	var camino: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]
	buscador.dibujar_trayectoria(camino, capa, Vector2i(2, 0))
	assert(capa.get_cell_source_id(Vector2i.RIGHT) == 0)
	assert(capa.get_cell_source_id(Vector2i(2, 0)) == 0)
	assert(capa.get_cell_atlas_coords(Vector2i(2, 0)) == Vector2i(2, 3))
	buscador.dibujar_trayectoria(camino, capa, Vector2i(3, 0))
	assert(capa.get_cell_source_id(Vector2i(2, 0)) == 0)
	assert(capa.get_cell_atlas_coords(Vector2i(2, 0)) != Vector2i(2, 3))
	buscador.dibujar_trayectoria([], capa, Vector2i.ZERO)
	assert(capa.get_used_cells().is_empty())
	buscador.free()
	escenario.free()
	print("OK: capa de camino y marcador del destino")
	quit()
