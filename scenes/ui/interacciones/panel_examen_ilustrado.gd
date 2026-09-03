class_name PanelExamenIlustrado
extends Control

signal cerrado

@onready var etiqueta_titulo: Label = $Ventana/Margen/Contenido/Cabecera/Titulo
@onready var boton_cerrar: Button = $Ventana/Margen/Contenido/Cabecera/Cerrar
@onready var imagen: TextureRect = $Ventana/Margen/Contenido/Cuerpo/Imagen
@onready var etiqueta_texto: RichTextLabel = $Ventana/Margen/Contenido/Cuerpo/Texto


func _ready() -> void:
	_ajustar_al_viewport()
	get_viewport().size_changed.connect(_ajustar_al_viewport)
	boton_cerrar.pressed.connect(ocultar)
	visible = false


func mostrar(titulo: String, ilustracion: Texture2D, texto: String) -> void:
	etiqueta_titulo.text = titulo
	imagen.texture = ilustracion
	etiqueta_texto.text = texto
	visible = true
	boton_cerrar.grab_focus()


func ocultar() -> void:
	if not visible:
		return
	visible = false
	cerrado.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		ocultar()
		get_viewport().set_input_as_handled()


func _ajustar_al_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
