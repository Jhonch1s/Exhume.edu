extends Control

signal recompensa_elegida(id: String)

const INICIALES := {"Guerrero": "Ataque doble", "Ladrón": "Ocultarse", "Mago": "Bola de fuego"}
const ACENTOS := {"Guerrero": Color("#dca77e"), "Ladrón": Color("#93c7e0"), "Mago": Color("#d7a9dc")}

@onready var selector: ItemList = $Marco/Contenido/Cuerpo/Lista/Selector
@onready var detalle: RichTextLabel = $Marco/Contenido/Cuerpo/DetalleMarco/DetalleContenido/Detalle
@onready var instruccion: Label = $Marco/Contenido/Instruccion
@onready var titulo: Label = $Marco/Contenido/Titulo
@onready var lista: VBoxContainer = $Marco/Contenido/Cuerpo/Lista
@onready var icono: TextureRect = $Marco/Contenido/Cuerpo/DetalleMarco/DetalleContenido/Identidad/Icono
@onready var tipo: Label = $Marco/Contenido/Cuerpo/DetalleMarco/DetalleContenido/Identidad/Textos/Tipo
@onready var nombre_opcion: Label = $Marco/Contenido/Cuerpo/DetalleMarco/DetalleContenido/Identidad/Textos/Nombre
@onready var error: Label = $Marco/Contenido/Error
@onready var boton_cerrar: Button = $Marco/Contenido/Botones/Cerrar
@onready var boton_aprender: Button = $Marco/Contenido/Botones/Aprender

var opciones: Array[Dictionary] = []
var procesando := false


func _ready() -> void:
	selector.item_selected.connect(_seleccionar)
	boton_aprender.pressed.connect(_confirmar)
	boton_cerrar.pressed.connect(hide)


func mostrar(nivel: int, nuevas_opciones: Array[Dictionary], resumen: String, clase: String = "") -> void:
	opciones = nuevas_opciones
	procesando = false
	error.hide()
	titulo.text = (clase.to_upper() + " · " if not clase.is_empty() else "") + "NIVEL %d" % nivel
	titulo.add_theme_color_override(&"font_color", ACENTOS.get(clase, Color("#eee3cc")))
	selector.clear()
	for opcion in opciones:
		selector.add_item("%s · %s" % [opcion["tipo"], opcion["nombre"]], CatalogoHabilidades.icono(opcion["id"]))
	var hay_opciones := not opciones.is_empty()
	var inicial: String = INICIALES.get(clase, "tu habilidad inicial")
	instruccion.text = "Elige una recompensa. Conservas %s." % inicial if hay_opciones else "Tus conocimientos y progreso"
	lista.visible = hay_opciones
	boton_aprender.visible = hay_opciones
	boton_aprender.disabled = true
	boton_aprender.text = "Selecciona una opción"
	boton_cerrar.text = "Elegir después" if hay_opciones else "Cerrar"
	icono.texture = null
	icono.visible = false
	tipo.text = "RECOMPENSA DE CLASE" if hay_opciones else "PROGRESIÓN"
	nombre_opcion.text = "Selecciona una opción" if hay_opciones else "Tus conocimientos"
	detalle.text = "Elige una habilidad o pasiva para conocer su efecto y su coste." if hay_opciones else resumen
	show()
	if hay_opciones:
		selector.grab_focus()
	else:
		boton_cerrar.grab_focus()


func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= opciones.size() or procesando:
		return
	var opcion := opciones[indice]
	icono.texture = CatalogoHabilidades.icono(opcion["id"])
	icono.visible = icono.texture != null
	tipo.text = String(opcion["tipo"]).to_upper()
	nombre_opcion.text = opcion["nombre"]
	detalle.text = "%s\n\nCoste: %s\n\nLa elección es permanente." % [opcion["descripcion"], opcion["coste"]]
	boton_aprender.text = "Aprender %s" % opcion["nombre"]
	boton_aprender.disabled = false
	error.hide()


func _confirmar() -> void:
	var indices := selector.get_selected_items()
	if procesando or indices.is_empty() or indices[0] >= opciones.size():
		return
	procesando = true
	boton_aprender.disabled = true
	recompensa_elegida.emit(opciones[indices[0]]["id"])


func mostrar_error(mensaje: String) -> void:
	procesando = false
	error.text = mensaje
	error.show()
	boton_aprender.disabled = selector.get_selected_items().is_empty()
	show()
	selector.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
