class_name PanelOrdenCombate
extends PanelContainer

signal retrato_pulsado(id_actor: StringName)

const MAXIMO_VISIBLE := 6
const SEPARACION := 8.0
const ANCHO_SEPARADOR := 14.0
const DURACION_DESLIZAMIENTO := 0.35

@onready var etiqueta_ronda: Label = $Margen/Contenido/Ronda
@onready var secuencia: Control = $Margen/Contenido/Secuencia

var _tarjetas: Dictionary[String, Button] = {}
var _animaciones: Dictionary[String, Tween] = {}
var _claves_visibles: Array[String] = []
var _entradas: Array[Dictionary] = []
var _ronda := 0
var _ancho_tarjeta := 88.0
var _alto_tarjeta := 128.0
var _separador: ColorRect


func _ready() -> void:
	_separador = ColorRect.new()
	_separador.color = Color("#d6cab6")
	_separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	secuencia.add_child(_separador)
	get_viewport().size_changed.connect(_ajustar_ancho)
	_ajustar_ancho()


func mostrar(ronda: int, entradas: Array[Dictionary], _id_activo: StringName) -> void:
	_ronda = ronda
	_entradas = entradas.slice(0, MAXIMO_VISIBLE)
	etiqueta_ronda.text = "RONDA %d" % ronda
	_dibujar(true)
	visible = true


func ocultar() -> void:
	visible = false
	for animacion in _animaciones.values():
		animacion.kill()
	_animaciones.clear()
	for tarjeta in _tarjetas.values():
		tarjeta.queue_free()
	_tarjetas.clear()
	_claves_visibles.clear()
	_entradas.clear()


func _ajustar_ancho() -> void:
	var ancho_logico := get_viewport_rect().size.x
	var ancho_ventana := maxf(1.0, get_window().size.x)
	_ancho_tarjeta = clampf(ancho_ventana * 0.065, 52.0, 100.0) * ancho_logico / ancho_ventana
	_alto_tarjeta = _ancho_tarjeta * 1.4
	if not is_node_ready():
		return
	_dibujar(false)
	var ancho_panel := size.x
	offset_left = -ancho_panel / 2.0
	offset_right = ancho_panel / 2.0
	offset_top = 210.0 if ancho_ventana < 1000.0 else 18.0
	offset_bottom = offset_top + size.y


func _dibujar(animar: bool) -> void:
	if not is_node_ready():
		return
	var nuevas: Array[String] = []
	var x := 0.0
	var hay_separador := false
	for entrada in _entradas:
		var siguiente: bool = entrada.get("siguiente", false)
		if siguiente and not hay_separador:
			hay_separador = true
			_separador.visible = true
			_separador.position = Vector2(x + 4.0, 5.0)
			_separador.size = Vector2(2.0, _alto_tarjeta - 10.0)
			x += ANCHO_SEPARADOR
		var clave := "%d:%s" % [_ronda + int(siguiente), entrada["id"]]
		nuevas.append(clave)
		var tarjeta: Button = _tarjetas.get(clave)
		if tarjeta == null:
			tarjeta = _crear_tarjeta(entrada)
			_tarjetas[clave] = tarjeta
			secuencia.add_child(tarjeta)
			tarjeta.position = Vector2(x, 0.0)
			if animar and not _claves_visibles.is_empty():
				tarjeta.modulate.a = 0.0
				create_tween().tween_property(tarjeta, "modulate:a", 1.0, DURACION_DESLIZAMIENTO)
		_actualizar_tarjeta(tarjeta, entrada, _ancho_tarjeta)
		_animar_a(clave, tarjeta, Vector2(x, 0.0), animar)
		x += _ancho_tarjeta + SEPARACION
	if not hay_separador:
		_separador.visible = false
	for clave in _claves_visibles:
		if clave in nuevas or not _tarjetas.has(clave):
			continue
		var tarjeta := _tarjetas[clave]
		_tarjetas.erase(clave)
		if _animaciones.has(clave):
			_animaciones[clave].kill()
			_animaciones.erase(clave)
		if animar:
			var destino := tarjeta.position + (Vector2(-_ancho_tarjeta, 0.0) if clave == _claves_visibles.front() else Vector2(0.0, -_alto_tarjeta - 12.0))
			var salida := create_tween()
			salida.tween_property(tarjeta, "position", destino, DURACION_DESLIZAMIENTO)
			salida.parallel().tween_property(tarjeta, "modulate:a", 0.0, DURACION_DESLIZAMIENTO)
			salida.finished.connect(tarjeta.queue_free)
		else:
			tarjeta.queue_free()
	_claves_visibles = nuevas
	secuencia.custom_minimum_size = Vector2(maxf(0.0, x - SEPARACION), _alto_tarjeta)
	reset_size()
	var ancho_panel := size.x
	offset_left = -ancho_panel / 2.0
	offset_right = ancho_panel / 2.0


func _crear_tarjeta(entrada: Dictionary) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton.pressed.connect(func(): retrato_pulsado.emit(entrada["id"]))
	var imagen := TextureRect.new()
	imagen.name = "Retrato"
	imagen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boton.add_child(imagen)
	var desconocido := Label.new()
	desconocido.name = "SinRetrato"
	desconocido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desconocido.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desconocido.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desconocido.add_theme_font_size_override(&"font_size", 34)
	desconocido.text = "?"
	desconocido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(desconocido)
	var bando := Label.new()
	bando.name = "Bando"
	bando.anchor_top = 1.0
	bando.anchor_bottom = 1.0
	bando.anchor_right = 1.0
	bando.offset_top = -22.0
	bando.offset_bottom = -2.0
	bando.offset_right = -4.0
	bando.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bando.add_theme_font_size_override(&"font_size", 15)
	bando.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	bando.add_theme_constant_override(&"shadow_offset_x", 2)
	bando.add_theme_constant_override(&"shadow_offset_y", 2)
	bando.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(bando)
	return boton


func _actualizar_tarjeta(boton: Button, entrada: Dictionary, ancho: float) -> void:
	boton.custom_minimum_size = Vector2(ancho, _alto_tarjeta)
	boton.size = boton.custom_minimum_size
	var retrato: Texture2D = entrada.get("retrato")
	(boton.get_node("Retrato") as TextureRect).texture = retrato
	(boton.get_node("SinRetrato") as Label).visible = retrato == null
	(boton.get_node("Bando") as Label).text = (
		"J" if entrada.get("jugador", false) else
		("A" if entrada.get("bando") == "Aliado" else "E")
	)
	var color := Color("#f4f1e9") if entrada.get("activo", false) else (
		Color("#8799aa") if entrada.get("jugador", false) else (
			Color("#70ad7e") if entrada.get("bando") == "Aliado" else Color("#ba5560")
		)
	)
	var marco := StyleBoxFlat.new()
	marco.bg_color = Color("#111821")
	marco.border_color = color
	marco.set_border_width_all(3 if entrada.get("activo", false) else 2)
	marco.set_corner_radius_all(3)
	marco.set_content_margin_all(4)
	boton.add_theme_stylebox_override(&"normal", marco)
	var resaltado := marco.duplicate()
	resaltado.border_color = Color.WHITE
	boton.add_theme_stylebox_override(&"hover", resaltado)
	boton.add_theme_stylebox_override(&"pressed", resaltado)
	var salud: String = entrada.get("salud", "")
	var iniciativa: Dictionary = entrada.get("iniciativa", {})
	boton.tooltip_text = "%s (%s)\n%s" % [entrada.get("nombre", ""), entrada.get("bando", ""), salud]
	if not iniciativa.is_empty():
		boton.tooltip_text += "\n%s: 1d6 (%d) + DES %d = %d" % [
			"Próxima ronda" if entrada.get("siguiente", false) else "Iniciativa",
			iniciativa["dado"], iniciativa["destreza"], iniciativa["total"]
		]


func _animar_a(clave: String, tarjeta: Button, destino: Vector2, animar: bool) -> void:
	if _animaciones.has(clave):
		_animaciones[clave].kill()
		_animaciones.erase(clave)
	if not animar:
		tarjeta.position = destino
		return
	var deslizamiento := create_tween()
	deslizamiento.tween_property(tarjeta, "position", destino, DURACION_DESLIZAMIENTO)
	_animaciones[clave] = deslizamiento
