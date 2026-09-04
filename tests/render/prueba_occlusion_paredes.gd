extends SceneTree

const CAPA_PAREDES_OCLUSIVAS := preload("res://scripts/render/capa_paredes_oclusivas.gd")


func _init() -> void:
	var capa := CAPA_PAREDES_OCLUSIVAS.new()
	var tiles := TileSet.new()
	tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tiles.tile_size = Vector2i(64, 32)
	var fuente := TileSetAtlasSource.new()
	var imagen := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	fuente.texture = ImageTexture.create_from_image(imagen)
	fuente.texture_region_size = Vector2i(64, 128)
	fuente.create_tile(Vector2i.ZERO)
	var fuente_id := tiles.add_source(fuente)
	capa.tile_set = tiles
	var delante := Vector2i(0, 1)
	var detras := Vector2i(0, -1)
	var lateral := Vector2i(1, -1)
	capa.set_cell(delante, fuente_id, Vector2i.ZERO)
	capa.set_cell(detras, fuente_id, Vector2i.ZERO)
	capa.set_cell(lateral, fuente_id, Vector2i.ZERO)
	capa.actualizar_occlusion(Vector2.ZERO)
	if not _comprobar(capa._use_tile_data_runtime_update(delante), "La pared frontal no recibió oclusión"):
		return
	if not _comprobar(not capa._use_tile_data_runtime_update(detras), "La pared trasera recibió oclusión"):
		return
	if not _comprobar(not capa._use_tile_data_runtime_update(lateral), "La pared lateral recibió oclusión"):
		return

	capa.actualizar_occlusion(Vector2(0.0, 48.0))
	if not _comprobar(not capa._celdas_con_recorte.has(delante), "La pared siguió activa al retroceder"):
		return
	if not _comprobar(capa._use_tile_data_runtime_update(delante), "La pared retirada no pidió limpiar su material"):
		return

	print("OK: la oclusion solo toma el frente y se retira al retroceder.")
	capa.free()
	quit()


func _comprobar(condicion: bool, mensaje: String) -> bool:
	if condicion:
		return true
	push_error(mensaje)
	quit(1)
	return false
