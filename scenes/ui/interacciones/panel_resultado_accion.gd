class_name PanelResultadoAccion
extends PanelContainer

signal resultado_presentado(resultado: ResultadoAccion)
signal cerrado

@export var texto_boton_cerrar: String = "Cerrar"
@export var separador_mensajes: String = "\n\n"
@export var prefijo_mensaje: String = "• "

@onready var etiqueta_titulo: Label = $Margen/Contenido/Titulo
@onready var etiqueta_mensajes: Label = $Margen/Contenido/Mensajes
@onready var boton_cerrar: Button = $Margen/Contenido/Cerrar


func _ready() -> void:
	boton_cerrar.text = texto_boton_cerrar
	boton_cerrar.pressed.connect(ocultar)


func mostrar_resultado(
	titulo: String,
	resultado: ResultadoAccion,
	catalogo: CatalogoMensajesInteraccion
) -> void:
	etiqueta_titulo.text = titulo
	etiqueta_mensajes.text = _componer_mensajes(resultado, catalogo)
	visible = true
	boton_cerrar.grab_focus()
	resultado_presentado.emit(resultado)


func ocultar() -> void:
	if not visible:
		return
	visible = false
	cerrado.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		ocultar()
		get_viewport().set_input_as_handled()


func _componer_mensajes(
	resultado: ResultadoAccion,
	catalogo: CatalogoMensajesInteraccion
) -> String:
	if resultado == null:
		return ""
	var ids := resultado.mensajes
	if ids.is_empty() and resultado.motivo != &"":
		ids.append(resultado.motivo)
	var lineas: Array[String] = []
	for id_mensaje in ids:
		var texto := catalogo.resolver(id_mensaje) if catalogo != null else String(id_mensaje)
		lineas.append(prefijo_mensaje + texto)
	return separador_mensajes.join(lineas)
