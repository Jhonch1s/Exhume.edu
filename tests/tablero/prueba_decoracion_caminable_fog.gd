extends SceneTree


func _init() -> void:
	var zona := Node2D.new()
	var suelo := TileMapLayer.new()
	var decoracion := TileMapLayer.new()
	suelo.name = "CapaSuelo"
	decoracion.name = "CapaDecoracion"
	suelo.tile_set = load("res://assets/tile_sets/terrain/cave_terrain.tres")
	decoracion.tile_set = load("res://assets/tile_sets/decorations/rocks_medium.tres")
	zona.add_child(suelo)
	zona.add_child(decoracion)
	suelo.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
	decoracion.set_cell(Vector2i.ZERO, 0, Vector2i(3, 1))
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	var celda := tablero.obtener_celda(Vector2i.ZERO)
	assert(celda.caminable)
	assert(celda.altura == 1)
	assert(celda.familia_fog == &"roca")
	assert(celda.coordenada_fog == Vector2i(3, 1))
	zona.free()
	print("OK: la decoración caminable aporta altura y fog sin bloquear el paso.")
	quit()
