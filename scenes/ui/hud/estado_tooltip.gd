extends Panel

const FUENTE = preload("res://assets/ui/fonts/Amarante-Regular.ttf")


func _get_tooltip(_at_position: Vector2) -> String:
	# El popup nativo se dibuja por encima del CanvasLayer del filtro CRT.
	return ""


func _make_custom_tooltip(for_text: String) -> Object:
	var cuadro := PanelContainer.new()
	var piedra := get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	piedra.content_margin_left = 12.0
	piedra.content_margin_top = 9.0
	piedra.content_margin_right = 12.0
	piedra.content_margin_bottom = 9.0
	cuadro.add_theme_stylebox_override(&"panel", piedra)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override(&"separation", 3)
	cuadro.add_child(contenido)

	var titulo := Label.new()
	titulo.text = for_text.get_slice("\n", 0)
	titulo.add_theme_font_override(&"font", FUENTE)
	titulo.add_theme_font_size_override(&"font_size", 20)
	titulo.add_theme_color_override(&"font_color", ($Icono as Label).modulate)
	contenido.add_child(titulo)

	var descripcion := Label.new()
	descripcion.text = for_text.substr(titulo.text.length() + 1)
	descripcion.custom_minimum_size.x = 250.0
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descripcion.add_theme_font_override(&"font", FUENTE)
	descripcion.add_theme_font_size_override(&"font_size", 16)
	descripcion.add_theme_color_override(&"font_color", Color("#d4c7ab"))
	contenido.add_child(descripcion)
	return cuadro
