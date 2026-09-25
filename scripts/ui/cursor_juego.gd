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

var _tipo_actual: int = Tipo.DEFAULT
var _canvas_cursor: CanvasLayer
var _sprite_cursor: Sprite2D
var _sobre_interfaz: bool = false


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
	_actualizar_textura()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(_delta: float) -> void:
	_actualizar_cursor_interfaz()
	_sprite_cursor.position = (
		get_viewport().get_mouse_position()
		- PUNTOS_ACTIVOS[_tipo_actual] * ESCALA_CURSOR
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
