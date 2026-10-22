extends ConfirmationDialog

signal recompensa_elegida(id: String)

var selector := ItemList.new()
var detalle := RichTextLabel.new()
var instruccion := Label.new()
var opciones: Array[Dictionary] = []


func _ready() -> void:
	title = "Progresión"
	min_size = Vector2i(660, 480)
	exclusive = true
	get_ok_button().text = "Aprender"
	get_cancel_button().text = "Elegir después"
	var contenido := VBoxContainer.new()
	add_child(contenido)
	contenido.add_theme_constant_override(&"separation", 12)
	contenido.add_child(instruccion)
	contenido.add_child(selector)
	contenido.add_child(detalle)
	selector.custom_minimum_size = Vector2(620, 150)
	selector.add_theme_font_size_override(&"font_size", 20)
	selector.add_theme_constant_override(&"v_separation", 10)
	detalle.custom_minimum_size = Vector2(580, 180)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selector.item_selected.connect(_seleccionar)
	confirmed.connect(_confirmar)


func mostrar(nivel: int, nuevas_opciones: Array[Dictionary], resumen: String) -> void:
	opciones = nuevas_opciones
	title = "Nivel %d · Progresión" % nivel
	selector.clear()
	for opcion in opciones:
		selector.add_item("%s · %s" % [opcion["tipo"], opcion["nombre"]])
	instruccion.text = "Elige UNA de las cuatro. Conservas tu habilidad inicial." if not opciones.is_empty() else "Tus recompensas aprendidas"
	selector.visible = not opciones.is_empty()
	get_ok_button().visible = not opciones.is_empty()
	get_cancel_button().text = "Elegir después" if not opciones.is_empty() else "Cerrar"
	if opciones.is_empty():
		detalle.text = resumen
	else:
		selector.select(0)
		_seleccionar(0)
	popup_centered(Vector2i(660, 520))
	if selector.visible:
		selector.grab_focus()


func _seleccionar(indice: int) -> void:
	var opcion := opciones[indice]
	detalle.text = "%s\n\n%s\n\nCoste: %s\nLa elección es permanente." % [
		opcion["tipo"], opcion["descripcion"], opcion["coste"]
	]


func _confirmar() -> void:
	var indices := selector.get_selected_items()
	if not indices.is_empty() and indices[0] < opciones.size():
		recompensa_elegida.emit(opciones[indices[0]]["id"])
