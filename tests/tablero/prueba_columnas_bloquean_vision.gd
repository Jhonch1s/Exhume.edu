extends SceneTree

const RUTA_TILESET := "res://assets/tile_sets/structures/cave_columns.tres"
const RUTA_ZONA := "res://scenes/Zona1/zona_1.tscn"

var _fallos: Array[String] = []


func _init() -> void:
	_probar_definiciones_del_tileset()
	_probar_columnas_colocadas_en_zona()

	if _fallos.is_empty():
		print("ColumnasBloqueanVision: 2 pruebas correctas.")
		quit()
		return

	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_definiciones_del_tileset() -> void:
	var tile_set: TileSet = load(RUTA_TILESET)
	_comprobar(tile_set != null, "El TileSet de columnas debe poder cargarse.")
	if tile_set == null:
		return

	var fuente := tile_set.get_source(0) as TileSetAtlasSource
	_comprobar(fuente != null, "El TileSet de columnas debe contener su atlas.")
	if fuente == null:
		return

	for coordenada_atlas in [Vector2i(0, 0), Vector2i(1, 0)]:
		var tile_data := fuente.get_tile_data(coordenada_atlas, 0)
		_comprobar(
			tile_data != null,
			"Debe existir la variante de columna %s." % coordenada_atlas
		)
		if tile_data != null:
			_comprobar(
				bool(tile_data.get_custom_data(&"bloquea_vision")),
				"La variante %s debe bloquear visión." % coordenada_atlas
			)


func _probar_columnas_colocadas_en_zona() -> void:
	var escena_zona: PackedScene = load(RUTA_ZONA)
	_comprobar(escena_zona != null, "Zona1 debe poder cargarse.")
	if escena_zona == null:
		return

	var zona := escena_zona.instantiate() as Node2D
	var capa_columnas := zona.get_node_or_null("CapaColumnas") as TileMapLayer
	_comprobar(capa_columnas != null, "Zona1 debe contener CapaColumnas.")
	if capa_columnas == null:
		zona.free()
		return

	var coordenadas := capa_columnas.get_used_cells()
	_comprobar(not coordenadas.is_empty(), "Zona1 debe contener columnas de prueba.")

	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	for coordenada in coordenadas:
		var celda := tablero.obtener_celda(coordenada)
		_comprobar(celda != null, "La columna %s debe existir en el tablero." % coordenada)
		if celda != null:
			_comprobar(
				celda.bloquea_vision,
				"La columna %s debe bloquear visión en el tablero." % coordenada
			)

	tablero.free()
	zona.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
