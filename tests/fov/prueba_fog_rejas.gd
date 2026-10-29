extends SceneTree

var fallos: Array[String] = []
var comprobaciones := 0


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	var zona := (load("res://scenes/ZonaPlantilla/zona_plantilla.tscn") as PackedScene).instantiate()
	root.add_child(zona)
	var suelo := zona.get_node("CapaSuelo") as TileMapLayer
	var decoracion := zona.get_node("CapaDecoracionNoCaminable") as TileMapLayer
	var oscuridad := zona.get_node("CapaOscuridad") as TileMapLayer
	var atlas := decoracion.tile_set.get_source(3) as TileSetAtlasSource
	var explorado := oscuridad.tile_set.get_source(18) as TileSetAtlasSource
	var oculto := oscuridad.tile_set.get_source(19) as TileSetAtlasSource
	_comprobar(explorado.texture.resource_path.ends_with("fence_isometric_explored.png"), "El atlas explorado usa la textura de rejas.")
	_comprobar(oculto.texture.resource_path.ends_with("fence_isometric_hidden.png"), "El atlas oculto usa la textura de rejas.")
	for y in range(4):
		for x in range(2):
			var coord := Vector2i(x, y)
			suelo.set_cell(coord, 0, Vector2i.ZERO)
			decoracion.set_cell(coord, 3, coord)
			var datos := atlas.get_tile_data(coord, 0)
			_comprobar(datos != null and datos.get_custom_data(&"familia_fog") == "reja", "La variante %s identifica la familia reja." % coord)
			_comprobar(explorado.has_tile(coord) and oculto.has_tile(coord), "Ambas máscaras incluyen la variante %s." % coord)
			_comprobar(explorado.get_tile_data(coord, 0).texture_origin == datos.texture_origin and oculto.get_tile_data(coord, 0).texture_origin == datos.texture_origin, "Las máscaras de %s coinciden con el origen de la reja." % coord)

	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	var fov := FOVManager.new()
	fov.inicializar(oscuridad, tablero)
	var niebla_rejas := oscuridad.get_node_or_null("NieblaRejas") as TileMapLayer
	_comprobar(niebla_rejas != null and niebla_rejas.z_index == 0 and niebla_rejas.y_sort_enabled, "La máscara de los barrotes respeta el orden de profundidad de las paredes.")
	for y in range(4):
		for x in range(2):
			var coord := Vector2i(x, y)
			var celda := tablero.obtener_celda(coord)
			_comprobar(not celda.caminable and not celda.bloquea_vision_efectiva(), "La reja %s bloquea el paso sin bloquear la visión." % coord)
			_comprobar(celda.familia_fog == &"reja" and celda.coordenada_fog == coord, "La variante %s conserva su coordenada de niebla." % coord)
			_comprobar(niebla_rejas.get_cell_source_id(coord) == 19 and niebla_rejas.get_cell_atlas_coords(coord) == coord and oscuridad.get_cell_source_id(coord) == 1, "La reja y el suelo de %s comienzan ocultos." % coord)
			fov._revelar_celda(coord)
			_comprobar(oscuridad.get_cell_source_id(coord) == -1 and niebla_rejas.get_cell_source_id(coord) == -1, "Ver %s retira ambas máscaras." % coord)
			fov._oscurecer_celda(coord, Celda.EstadoVisibilidad.EXPLORADO)
			_comprobar(niebla_rejas.get_cell_source_id(coord) == 18 and niebla_rejas.get_cell_atlas_coords(coord) == coord and oscuridad.get_cell_source_id(coord) == 0, "La reja y el suelo de %s quedan explorados." % coord)

	fov.reconstruir_niebla_restaurada()
	_comprobar(niebla_rejas.get_cell_source_id(Vector2i(1, 3)) == 18 and oscuridad.get_cell_source_id(Vector2i(1, 3)) == 0, "La reconstrucción conserva ambas máscaras exploradas.")
	fov.inicializar(oscuridad, tablero)
	_comprobar(oscuridad.get_child_count() == 1 and oscuridad.get_node("NieblaRejas") == niebla_rejas, "Reinicializar reutiliza la capa de rejas.")
	_comprobar(niebla_rejas.get_cell_source_id(Vector2i(1, 3)) == 19 and oscuridad.get_cell_source_id(Vector2i(1, 3)) == 1, "Reinicializar vuelve a ocultar reja y suelo.")

	fov.free()
	tablero.free()
	zona.free()
	for fallo in fallos:
		push_error(fallo)
	print("FogRejas: %d comprobaciones, %d fallos." % [comprobaciones, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos.append(mensaje)
