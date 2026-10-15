class_name PanelFichaNPC
extends Control

signal cerrado

@onready var titulo: Label = $Ventana/Margen/Contenido/Cabecera/Titulo
@onready var cerrar: Button = $Ventana/Margen/Contenido/Cabecera/Cerrar
@onready var datos: Label = $Ventana/Margen/Contenido/Datos
@onready var observacion: Label = $Ventana/Margen/Contenido/Observacion

var personaje: PersonajeNPC


func _ready() -> void:
	cerrar.pressed.connect(ocultar)
	visible = false


func mostrar(npc: PersonajeNPC, textos: Array[String]) -> void:
	personaje = npc
	observacion.text = "\n\n".join(textos)
	_actualizar()
	visible = true
	cerrar.grab_focus()


func ocultar() -> void:
	if not visible:
		return
	visible = false
	personaje = null
	cerrado.emit()


func _process(_delta: float) -> void:
	if visible:
		_actualizar()


func _actualizar() -> void:
	if personaje == null or not is_instance_valid(personaje):
		ocultar()
		return
	var perfil := personaje.obtener_definicion_personaje()
	titulo.text = personaje.obtener_nombre_interaccion()
	datos.text = "Nivel %d  ·  PV %d / %d\nFUE %d     DES %d     VOL %d" % [
		personaje.nivel_actual, personaje.vida_actual, perfil.vida_maxima,
		personaje.obtener_fuerza(), personaje.obtener_destreza(), personaje.obtener_voluntad()
	]


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		ocultar()
		get_viewport().set_input_as_handled()
