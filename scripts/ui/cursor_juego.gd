extends Node

enum Tipo { DEFAULT, MOVIMIENTO, INTERACCION, EXAMINAR, LANZAR }

const ESCALA_CURSOR := 0.5
const SOMBREADOR_CRT: Shader = preload("res://scenes/ui/cursor_crt.gdshader")
const TEXTURAS: Array[Texture2D] = [
	preload("res://assets/ui/cursors/cursor_default.png"),
	preload("res://assets/ui/cursors/cursor_movimiento.png"),
	preload("res://assets/ui/cursors/cursor_interaccion.png"),
	preload("res://assets/ui/cursors/cursor_examinar.png"),
	preload("res://assets/ui/cursors/cursor_lanzar.png"),
]
const PUNTOS_ACTIVOS: Array[Vector2] = [
	Vector2(4, 4),
	Vector2(7, 7),
	Vector2(34, 6),
	Vector2(30, 30),
	Vector2(32, 32),
]
const SONIDO_CLICK_UI: AudioStream = preload("res://assets/sonidos/sonidos finales/sonidos extras/Special Click 02.wav")

var _tipo_actual: int = Tipo.DEFAULT
var _canvas_cursor: CanvasLayer
var _canvas_indicador: CanvasLayer
var _sprite_cursor: Sprite2D
var _sobre_interfaz: bool = false
var _reproductor_click: AudioStreamPlayer
var _ultimo_click_msec: int = 0
var _panel_probabilidad: PanelContainer
var _texto_probabilidad: Label


func _ready() -> void:
	_canvas_cursor = CanvasLayer.new()
	_canvas_cursor.name = "CapaCursorCRT"
	_canvas_cursor.layer = 127
	add_child(_canvas_cursor)

	_sprite_cursor = Sprite2D.new()
	_sprite_cursor.name = "Puntero"
	_sprite_cursor.centered = false
	_sprite_cursor.scale = Vector2.ONE * ESCALA_CURSOR
	var material := ShaderMaterial.new()
	material.shader = SOMBREADOR_CRT
	_sprite_cursor.material = material
	_canvas_cursor.add_child(_sprite_cursor)
	_canvas_indicador = CanvasLayer.new()
	_canvas_indicador.name = "CapaIndicadorCombate"
	_canvas_indicador.layer = 2
	add_child(_canvas_indicador)
	_panel_probabilidad = PanelContainer.new()
	_panel_probabilidad.name = "ProbabilidadAtaqueBasico"
	_panel_probabilidad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_probabilidad.visible = false
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#211b18ed")
	fondo.border_color = Color("#b58b53")
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(5)
	fondo.content_margin_left = 8.0
	fondo.content_margin_right = 8.0
	fondo.content_margin_top = 5.0
	fondo.content_margin_bottom = 5.0
	_panel_probabilidad.add_theme_stylebox_override(&"panel", fondo)
	_canvas_indicador.add_child(_panel_probabilidad)
	_texto_probabilidad = Label.new()
	_texto_probabilidad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_probabilidad.add_theme_color_override(&"font_color", Color("#f2dfbd"))
	_texto_probabilidad.add_theme_font_size_override(&"font_size", 14)
	_panel_probabilidad.add_child(_texto_probabilidad)
	_actualizar_textura()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	_reproductor_click = AudioStreamPlayer.new()
	_reproductor_click.name = "AudioClickUI"
	_reproductor_click.stream = SONIDO_CLICK_UI
	_reproductor_click.volume_db = -16.0
	add_child(_reproductor_click)

	_conectar_botones(get_tree().root)
	get_tree().node_added.connect(_on_node_added)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if _sobre_interfaz:
			reproducir_click_ui()


func _on_node_added(nodo: Node) -> void:
	if nodo is BaseButton:
		_conectar_boton(nodo as BaseButton)


func _conectar_botones(raiz: Node) -> void:
	if raiz == null:
		return
	if raiz is BaseButton:
		_conectar_boton(raiz as BaseButton)
	for hijo in raiz.get_children():
		_conectar_botones(hijo)


func _conectar_boton(boton: BaseButton) -> void:
	if not boton.pressed.is_connected(reproducir_click_ui):
		boton.pressed.connect(reproducir_click_ui)


func reproducir_click_ui() -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_click_msec < 60:
		return
	_ultimo_click_msec = ahora
	if _reproductor_click == null:
		_reproductor_click = AudioStreamPlayer.new()
		_reproductor_click.name = "AudioClickUI"
		_reproductor_click.stream = SONIDO_CLICK_UI
		_reproductor_click.volume_db = -16.0
		add_child(_reproductor_click)
	if is_instance_valid(_reproductor_click):
		_reproductor_click.pitch_scale = randf_range(0.96, 1.04)
		_reproductor_click.play()


func _process(_delta: float) -> void:
	_actualizar_cursor_interfaz()
	var punto := get_viewport().get_mouse_position()
	_sprite_cursor.position = (
		punto
		- PUNTOS_ACTIVOS[_tipo_actual] * ESCALA_CURSOR
	)
	if _panel_probabilidad.visible:
		var ancho := get_viewport().get_visible_rect().size.x
		var alto := get_viewport().get_visible_rect().size.y
		var x := punto.x + 28.0
		if x + _panel_probabilidad.size.x > ancho - 8.0:
			x = punto.x - _panel_probabilidad.size.x - 12.0
		_panel_probabilidad.position = Vector2(
			maxf(8.0, x),
			clampf(punto.y - 8.0, 8.0, maxf(8.0, alto - _panel_probabilidad.size.y - 8.0))
		)


func mostrar_probabilidad_ataque(texto: String) -> void:
	if not is_instance_valid(_panel_probabilidad):
		return
	if _texto_probabilidad.text != texto:
		_texto_probabilidad.text = texto
		_panel_probabilidad.reset_size()
	_panel_probabilidad.show()


func ocultar_probabilidad_ataque() -> void:
	if is_instance_valid(_panel_probabilidad):
		_panel_probabilidad.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ocultar_probabilidad_ataque()
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func establecer_cursor(tipo: Tipo) -> void:
	var tipo_nuevo := clampi(int(tipo), Tipo.DEFAULT, Tipo.LANZAR)
	if tipo_nuevo == _tipo_actual:
		return
	_tipo_actual = tipo_nuevo
	_actualizar_textura()


func _actualizar_textura() -> void:
	_sprite_cursor.texture = (
		TEXTURAS[Tipo.INTERACCION]
		if _sobre_interfaz
		else TEXTURAS[_tipo_actual]
	)


func _actualizar_cursor_interfaz() -> void:
	var control := get_viewport().gui_get_hovered_control()
	var sobre_interfaz := (
		control != null
		and control.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND
	)
	if sobre_interfaz == _sobre_interfaz:
		return
	_sobre_interfaz = sobre_interfaz
	_actualizar_textura()
