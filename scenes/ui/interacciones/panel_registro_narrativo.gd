class_name PanelRegistroNarrativo
extends PanelContainer

const MAXIMO_COMPACTO := 3

@onready var boton_expandir: Button = $Margen/Contenido/Cabecera/Expandir
@onready var cabecera: HBoxContainer = $Margen/Contenido/Cabecera
@onready var desplazamiento: ScrollContainer = $Margen/Contenido/Desplazamiento
@onready var tarjetas: VBoxContainer = $Margen/Contenido/Desplazamiento/Tarjetas

var registro: RegistroNarrativoSesion
var expandido := false
var arrastrando := false
var _desplazamiento_arrastre := Vector2.ZERO


func _ready() -> void:
	boton_expandir.pressed.connect(alternar)
	cabecera.gui_input.connect(_procesar_arrastre)


func observar(nuevo_registro: RegistroNarrativoSesion) -> void:
	if registro != null and registro.entrada_agregada.is_connected(_al_agregar_entrada):
		registro.entrada_agregada.disconnect(_al_agregar_entrada)
	registro = nuevo_registro
	if registro != null:
		registro.entrada_agregada.connect(_al_agregar_entrada)
	_actualizar()


func alternar() -> void:
	expandido = not expandido
	boton_expandir.text = "Contraer" if expandido else "Expandir"
	custom_maximum_size.y = -1.0 if expandido else 90.0
	custom_minimum_size.y = 240.0 if expandido else 0.0
	_actualizar()


func _al_agregar_entrada(_entrada: EntradaRegistroNarrativo) -> void:
	var barra := desplazamiento.get_v_scroll_bar()
	var seguir_final := not expandido or barra.value >= barra.max_value - barra.page - 2.0
	_actualizar()
	if seguir_final:
		await get_tree().process_frame
		desplazamiento.scroll_vertical = int(desplazamiento.get_v_scroll_bar().max_value)


func _actualizar() -> void:
	for tarjeta in tarjetas.get_children():
		tarjeta.queue_free()
	if registro == null:
		return
	var entradas := registro.obtener_entradas_visibles()
	if not expandido and entradas.size() > MAXIMO_COMPACTO:
		entradas = entradas.slice(entradas.size() - MAXIMO_COMPACTO)
	for entrada in entradas:
		var etiqueta := RichTextLabel.new()
		etiqueta.bbcode_enabled = true
		etiqueta.fit_content = true
		etiqueta.scroll_active = false
		etiqueta.mouse_filter = Control.MOUSE_FILTER_STOP
		etiqueta.add_theme_font_size_override(&"normal_font_size", 11 if not expandido else 14)
		etiqueta.add_theme_color_override(&"default_color", Color("#B8B3AA"))
		etiqueta.text = _componer_texto_entrada(entrada)
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tarjetas.add_child(etiqueta)


func _componer_texto_entrada(entrada: EntradaRegistroNarrativo) -> String:
	if not expandido:
		return "[%s] %s" % [entrada.titulo, entrada.mensaje.replace("\n", " ")]
	return "[%s]\n%s%s" % [
		entrada.titulo,
		("\n".join(entrada.detalles) + "\n") if not entrada.detalles.is_empty() else "",
		entrada.mensaje,
	]


func _procesar_arrastre(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		arrastrando = evento.pressed
		if arrastrando:
			_desplazamiento_arrastre = get_global_mouse_position() - global_position
			cabecera.accept_event()
	elif evento is InputEventMouseMotion and arrastrando:
		var limite := get_viewport_rect().size - size
		global_position = Vector2(
			clampf(get_global_mouse_position().x - _desplazamiento_arrastre.x, 0.0, maxf(0.0, limite.x)),
			clampf(get_global_mouse_position().y - _desplazamiento_arrastre.y, 0.0, maxf(0.0, limite.y)),
		)
		cabecera.accept_event()
