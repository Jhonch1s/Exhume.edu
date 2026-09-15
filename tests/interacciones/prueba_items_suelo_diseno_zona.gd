extends SceneTree


func _init() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var zona := Node2D.new()
	root.add_child(zona)
	var capa := TileMapLayer.new()
	capa.tile_set = TileSet.new()
	zona.add_child(capa)
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"antorcha"
	definicion.nombre = "Antorcha"
	var marcador := ItemSueloZona.new()
	marcador.add_to_group(&"items_suelo_zona")
	marcador.id_instancia = &"antorcha_diseno"
	marcador.definicion = definicion
	zona.add_child(marcador)
	marcador.position = capa.map_to_local(Vector2i.ZERO) + Vector2(3, 4)

	var tablero := TableroGrid.new()
	var celda := Celda.new()
	celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
	tablero.datos[Vector2i.ZERO] = celda
	tablero.configurar_transferidor_items(TransferidorItems.new(tablero))
	assert(tablero.registrar_items_suelo_desde_zona(zona, capa))
	var item: ItemSuelo = tablero.obtener_item_suelo(&"antorcha_diseno")
	assert(item != null)
	assert(item.desplazamiento_visual == Vector2(3, 4))
	var objetivos := SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(
		tablero,
		Vector2i.ZERO
	)
	assert(item in objetivos)

	var representacion := RepresentacionItemSuelo.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	var imagen := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	imagen.fill(Color.TRANSPARENT)
	imagen.set_pixel(1, 1, Color.WHITE)
	sprite.texture = ImageTexture.create_from_image(imagen)
	representacion.add_child(sprite)
	zona.add_child(representacion)
	representacion.global_position = Vector2(50, 50)
	await process_frame
	item.vincular_representacion(representacion)
	var selector := SelectorObjetivosInteraccion.new()
	assert(item in selector.obtener_objetivos_perceptibles(
		tablero, Vector2i(99, 99), null, Vector2(50, 50)
	))
	assert(selector.obtener_objetivos_perceptibles(
		tablero, Vector2i(99, 99), null, Vector2(51, 51)
	).is_empty())
	assert(item.obtener_opciones_accion()[0].tipo == TiposInteraccion.TipoAccion.RECOGER)
	print("ItemsSueloDisenoZona: prueba correcta.")
	quit()
