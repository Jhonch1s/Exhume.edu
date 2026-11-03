extends SceneTree

func _initialize() -> void:
	call_deferred(&"probar")

func probar() -> void:
	var zona := (load("res://scenes/ZonaPlantilla/zona_plantilla.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo: TileMapLayer = zona.get_node("CapaSuelo")
	var caminable: TileMapLayer = zona.get_node("CapaDecoracion")
	var solida: TileMapLayer = zona.get_node("CapaDecoracionNoCaminable")
	var oscuridad: TileMapLayer = zona.get_node("CapaOscuridad")
	for y in range(2):
		for x in range(20):
			var coord := Vector2i(x, y)
			suelo.set_cell(coord, 0, Vector2i.ZERO)
			if y == 0:
				caminable.set_cell(coord, 5, coord)
			else:
				solida.set_cell(coord, 4, coord)
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	var fov := FOVManager.new()
	fov.inicializar(oscuridad, tablero)
	var mascara: TileMapLayer = oscuridad.get_node("NieblaRejas")
	assert(mascara.z_index == 0 and mascara.y_sort_enabled)
	for y in range(2):
		for x in range(20):
			var coord := Vector2i(x, y)
			assert(tablero.obtener_celda(coord).familia_fog == &"jail")
			assert(mascara.get_cell_source_id(coord) == 21 and mascara.get_cell_atlas_coords(coord) == coord)
			fov._oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)
			assert(mascara.get_cell_source_id(coord) == 20 and mascara.get_cell_atlas_coords(coord) == coord)
			fov._revelar_celda(coord)
			assert(mascara.get_cell_source_id(coord) == -1)
	fov.free()
	tablero.free()
	zona.free()
	print("OK: máscaras de prisión y orden de profundidad")
	quit()
