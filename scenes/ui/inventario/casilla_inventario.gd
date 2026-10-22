class_name CasillaInventario
extends Button

signal item_arrastrado_soltado(origen_indice: int, origen_es_equipo: bool, destino_indice: int, destino_es_equipo: bool)
signal raton_entro(casilla: CasillaInventario)
signal raton_salio

const FUENTE = preload("res://assets/ui/fonts/Amarante-Regular.ttf")

@export var icono_vacio: Texture2D

var item: ItemInstancia
var indice_ranura: int = -1
var es_ranura_equipo: bool = false
var tipo_ranura_equipo: int = -1


func _ready() -> void:
	mouse_entered.connect(func(): raton_entro.emit(self))
	mouse_exited.connect(func(): raton_salio.emit())
	configurar(item)


func _get_tooltip(_at_position: Vector2) -> String:
	# Suprimimos el tooltip nativo de Godot para que se dibuje en el CanvasLayer
	# y quede bajo el efecto del filtro CRT.
	return ""


func configurar(nuevo_item: ItemInstancia) -> void:
	item = nuevo_item
	$Cantidad.text = ""
	if item == null or not item.es_valida():
		if icono_vacio != null:
			$Icono.texture = icono_vacio
			$Icono.modulate = Color(0.42, 0.42, 0.42, 0.35)
		else:
			$Icono.texture = null
			$Icono.modulate = Color.WHITE
		return
	
	$Icono.texture = item.definicion.icono
	$Icono.modulate = Color.WHITE
	$Cantidad.text = str(item.cantidad) if item.cantidad > 1 else ""


func obtener_texto_tooltip() -> String:
	if item == null or not item.es_valida():
		return ""
	var peso_unitario: float = item.definicion.obtener_peso()
	var peso_total: float = item.obtener_peso_total()
	var texto_peso: String = "Peso: %.1f kg" % peso_total if item.cantidad == 1 else "Peso: %.1f kg (%.1f c/u)" % [peso_total, peso_unitario]
	var encabezado: String = "%s (x%d)" % [item.definicion.nombre, item.cantidad] if item.cantidad > 1 else item.definicion.nombre
	var descripcion := item.definicion.descripcion_base
	for efecto: Dictionary in item.definicion.efectos_equipo:
		descripcion += "\n" + EfectosEquipo.describir(efecto)
	return "%s\n%s\n%s" % [encabezado, texto_peso, descripcion]


func crear_cuadro_tooltip() -> PanelContainer:
	var texto := obtener_texto_tooltip()
	if texto.is_empty():
		return null
	
	var cuadro := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.075, 0.065, 0.055, 0.95)
	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1
	estilo.border_color = Color(0.35, 0.28, 0.2, 0.95)
	estilo.corner_radius_top_left = 2
	estilo.corner_radius_top_right = 2
	estilo.corner_radius_bottom_right = 2
	estilo.corner_radius_bottom_left = 2
	estilo.content_margin_left = 10.0
	estilo.content_margin_top = 8.0
	estilo.content_margin_right = 10.0
	estilo.content_margin_bottom = 8.0
	estilo.shadow_color = Color(0, 0, 0, 0.7)
	estilo.shadow_size = 4
	cuadro.add_theme_stylebox_override(&"panel", estilo)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override(&"separation", 4)
	cuadro.add_child(contenido)

	var partes := texto.split("\n", false, 2)
	var nombre_texto: String = partes[0] if partes.size() > 0 else ""
	var peso_texto: String = partes[1] if partes.size() > 1 else ""
	var desc_texto: String = partes[2] if partes.size() > 2 else ""

	var titulo := Label.new()
	titulo.text = nombre_texto
	titulo.add_theme_font_override(&"font", FUENTE)
	titulo.add_theme_font_size_override(&"font_size", 16)
	titulo.add_theme_color_override(&"font_color", Color("#d4a34b"))
	contenido.add_child(titulo)

	if not peso_texto.is_empty():
		var peso_lbl := Label.new()
		peso_lbl.text = peso_texto
		peso_lbl.add_theme_font_override(&"font", FUENTE)
		peso_lbl.add_theme_font_size_override(&"font_size", 12)
		peso_lbl.add_theme_color_override(&"font_color", Color("#968c78"))
		contenido.add_child(peso_lbl)

	if not desc_texto.is_empty():
		var desc_lbl := Label.new()
		desc_lbl.text = desc_texto
		desc_lbl.custom_minimum_size.x = 220.0
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_override(&"font", FUENTE)
		desc_lbl.add_theme_font_size_override(&"font_size", 13)
		desc_lbl.add_theme_color_override(&"font_color", Color("#d4c7ab"))
		contenido.add_child(desc_lbl)

	return cuadro


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null or not item.es_valida():
		return null
	
	raton_salio.emit()
	
	var preview := TextureRect.new()
	preview.texture = item.definicion.icono
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(40, 40)
	preview.size = Vector2(40, 40)
	preview.modulate = Color(1.0, 1.0, 1.0, 0.8)
	
	var control := Control.new()
	control.add_child(preview)
	preview.position = -0.5 * preview.custom_minimum_size
	set_drag_preview(control)
	
	return {
		"tipo": "item_inventario",
		"item": item,
		"origen_indice": indice_ranura,
		"es_equipo": es_ranura_equipo,
		"tipo_equipo": tipo_ranura_equipo,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("tipo") == "item_inventario"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_arrastrado_soltado.emit(
		int(data.get("origen_indice", -1)),
		bool(data.get("es_equipo", false)),
		indice_ranura,
		es_ranura_equipo
	)
