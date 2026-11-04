extends SceneTree

var fallos: Array[String] = []
var comprobaciones := 0


func _initialize() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_probar("4x8", 29)
	_probar("5x8", 42)
	for fallo in fallos:
		push_error(fallo)
	print("RocasDerrumbadas: %d comprobaciones, %d fallos." % [comprobaciones, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func _probar(tamano: String, cantidad: int) -> void:
	var zona := Node2D.new()
	zona.y_sort_enabled = true
	var suelo := TileMapLayer.new()
	suelo.name = "CapaSuelo"
	suelo.tile_set = load("res://assets/tile_sets/terrain/cave_terrain.tres")
	zona.add_child(suelo)
	var capa := TileMapLayer.new()
	capa.name = "CapaDecoracionNoCaminable"
	capa.y_sort_enabled = true
	capa.tile_set = load("res://assets/tile_sets/decorations/cave_decorations_solid.tres")
	zona.add_child(capa)
	for x in range(-12, 13):
		for y in range(-12, 13):
			suelo.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	var origen := Vector2i(2, 1)
	capa.set_cell(origen, 5, Vector2i.ZERO, 0 if tamano == "4x8" else 1)
	var tablero := TableroGrid.new()
	tablero.generar_desde_zona(zona)
	_comprobar(not tablero.puede_entrar(origen), "%s: base bloqueada incluso sin entrar al árbol" % tamano)
	suelo.owner = zona
	capa.owner = zona
	var guardada := PackedScene.new()
	_comprobar(guardada.pack(zona) == OK, "%s: guardar la zona con la decoración pintada" % tamano)
	var recuperada := guardada.instantiate() as Node2D
	var tablero_recuperado := TableroGrid.new()
	tablero_recuperado.generar_desde_zona(recuperada)
	_comprobar(not tablero_recuperado.puede_entrar(origen) and tablero_recuperado.interactuables_por_id.is_empty(), "%s: recuperar el tile y su ocupación sin guardar interactuables" % tamano)
	recuperada.free()
	tablero_recuperado.free()
	root.add_child(zona)
	var fov := FOVManager.new()
	fov.tablero = tablero
	fov.datos_tablero = tablero.datos
	fov._actualizar_presentacion_interactuables()
	var rocas := capa.get_child(0) as Node2D
	var ocupadas: Array[Vector2i] = rocas.obtener_coordenadas_ocupadas(capa)
	_comprobar(not rocas is Interactuable, "%s: decoración de TileMap, sin contrato de interacción" % tamano)
	_comprobar(rocas.position == capa.map_to_local(origen), "%s: ancla en la celda pintada" % tamano)
	var errores := ValidadorContenidoZona.new().validar(zona, tablero, suelo)
	_comprobar(errores.is_empty(), "%s: contenido válido: %s" % [tamano, errores])
	_comprobar(tablero.registrar_interactuables_desde_zona(zona, suelo) and tablero.interactuables_por_id.is_empty(), "%s: no se registra como interactuable ni necesita ID" % tamano)
	_comprobar(ocupadas.size() == cantidad and origen in ocupadas, "%s: huella completa y ancla en la base" % tamano)
	var sprite := rocas.get_node("Sprite2D") as Sprite2D
	var mascara := Image.load_from_file(ProjectSettings.globalize_path("res://assets/tiles/decorations/custom/%s_rocas_derrumbadas_ocupacion.png" % tamano))
	var esquina := sprite.position - sprite.texture.get_size() / 2.0
	_comprobar(Vector2(mascara.get_size()) == sprite.texture.get_size(), "%s: escala original" % tamano)
	# Compara cada celda con el PNG pintado, independientemente de la lista de huella.
	for coord: Vector2i in tablero.datos:
		var pixel := Vector2i(suelo.map_to_local(coord) - rocas.position - esquina)
		var roja := false
		if Rect2i(Vector2i.ZERO, mascara.get_size()).has_point(pixel):
			var color := mascara.get_pixelv(pixel)
			roja = color.a > 0.5 and color.r > 0.8 and color.g < 0.3 and color.b < 0.3
		_comprobar((coord in ocupadas) == roja and tablero.puede_entrar(coord) == not roja, "%s: ocupación y paso según máscara en %s" % [tamano, coord])
		if roja:
			var celda := tablero.obtener_celda(coord)
			_comprobar(not celda.bloquea_vision_efectiva() and celda.bloquea_proyectiles_efectiva() and celda.interactuables.is_empty(), "%s: obstrucción estática sin interacción en %s" % [tamano, coord])
	var desde := suelo.local_to_map(rocas.position + esquina + Vector2(64, 32))
	var hasta := suelo.local_to_map(rocas.position + esquina + Vector2(sprite.texture.get_width() - 64, 32))
	var rutas := PathFindingManager.new()
	rutas.inicializar(tablero.datos)
	var camino := rutas.calcular_camino(desde, hasta, tablero.datos)
	_comprobar(not camino.is_empty() and camino.all(func(c): return c not in ocupadas), "%s: recorrido libre detrás de la parte alta" % tamano)
	for nombre in ["FogOculto", "FogExplorado"]:
		var fog := rocas.get_node(nombre) as Sprite2D
		_comprobar(fog.position == sprite.position and fog.texture.get_size() == sprite.texture.get_size(), "%s: máscara %s alineada" % [tamano, nombre])
	for estado in [Celda.EstadoVisibilidad.OCULTO, Celda.EstadoVisibilidad.EXPLORADO, Celda.EstadoVisibilidad.VISIBLE]:
		for coord in ocupadas:
			tablero.obtener_celda(coord).visibilidad = estado
		fov._actualizar_presentacion_interactuables()
		_comprobar(rocas.visible and rocas.get_node("FogOculto").visible == (estado == Celda.EstadoVisibilidad.OCULTO) and rocas.get_node("FogExplorado").visible == (estado == Celda.EstadoVisibilidad.EXPLORADO), "%s: niebla en estado %s" % [tamano, estado])
	for coord in ocupadas:
		tablero.obtener_celda(coord).visibilidad = Celda.EstadoVisibilidad.OCULTO
	tablero.obtener_celda(ocupadas[0]).visibilidad = Celda.EstadoVisibilidad.VISIBLE
	fov._actualizar_presentacion_interactuables()
	_comprobar(not rocas.get_node("FogOculto").visible, "%s: ver otra celda de la base revela la decoración aunque el ancla esté oculta" % tamano)
	capa.erase_cell(origen)
	capa.update_internals()
	tablero.generar_desde_zona(zona)
	_comprobar(ocupadas.all(func(c): return tablero.puede_entrar(c)), "%s: borrar el tile libera toda la base al generar el mapa" % tamano)
	zona.free()
	tablero.free()
	rutas.free()
	fov.free()


func _comprobar(correcto: bool, texto: String) -> void:
	comprobaciones += 1
	if not correcto:
		fallos.append(texto)
