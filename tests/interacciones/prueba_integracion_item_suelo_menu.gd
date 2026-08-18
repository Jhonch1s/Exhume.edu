extends SceneTree


func _init() -> void:
	var tablero := TableroGrid.new()
	var celda := Celda.new()
	celda.visibilidad = Celda.EstadoVisibilidad.VISIBLE
	tablero.datos[Vector2i.ZERO] = celda
	var definicion := DefinicionItem.new()
	definicion.id_definicion = &"piedra"
	definicion.nombre = "Piedra"
	var item_suelo := ItemSuelo.new(ItemInstancia.new(&"piedra_prueba", definicion))
	item_suelo.configurar_transferidor_items(TransferidorItems.new(tablero))
	assert(tablero.registrar_item_suelo(Vector2i.ZERO, item_suelo))

	var objetivos := SelectorObjetivosInteraccion.new().obtener_objetivos_perceptibles(
		tablero, Vector2i.ZERO
	)
	assert(objetivos == [item_suelo])
	assert(objetivos[0].obtener_opciones_accion()[0].tipo == TiposInteraccion.TipoAccion.RECOGER)
	print("IntegracionItemSueloMenu: prueba correcta.")
	quit()
