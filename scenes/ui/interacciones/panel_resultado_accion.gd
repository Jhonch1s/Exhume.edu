class_name PanelResultadoAccion
extends PanelContainer

signal resultado_presentado(resultado: ResultadoAccion)
signal tirada_presentada(resultado: Variant)
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


func mostrar_tirada(
	titulo: String,
	resultado: Variant,
	mensajes: Array[String] = []
) -> bool:
	if (
		(not resultado is ResultadoPrueba and not resultado is ResultadoTirada)
		or not resultado.valida
		or resultado.presentacion != TiposTirada.Presentacion.PRIMER_PLANO
	):
		return false
	etiqueta_titulo.text = titulo
	etiqueta_mensajes.text = (
		_componer_prueba(resultado)
		if resultado is ResultadoPrueba
		else _componer_cantidad(resultado)
	)
	if not mensajes.is_empty():
		etiqueta_mensajes.text += separador_mensajes + separador_mensajes.join(mensajes)
	visible = true
	boton_cerrar.grab_focus()
	tirada_presentada.emit(resultado)
	return true


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


func _componer_prueba(resultado: ResultadoPrueba) -> String:
	return "Modo: %s\nDados: %s\nSeleccionado: %d\nAtributo: %d\n%s · %s" % [
		String(ResultadoPrueba.Modo.keys()[resultado.modo]).capitalize(),
		_formatear_dados(resultado.dados),
		resultado.dado_seleccionado,
		resultado.atributo,
		String(ResultadoPrueba.Clasificacion.keys()[resultado.clasificacion]).capitalize(),
		"Éxito" if resultado.exitosa else "Fallo",
	]


func _componer_cantidad(resultado: ResultadoTirada) -> String:
	var terminos: Array[String] = []
	for termino in resultado.terminos:
		terminos.append("%s%dd%d: %s" % [
			"+" if termino[&"signo"] > 0 else "-",
			termino[&"cantidad"],
			termino[&"caras"],
			_formatear_dados(termino[&"resultados"]),
		])
	return "%s\nTotal: %d\nEfectivo: %d" % [
		"\n".join(terminos),
		resultado.total_calculado,
		resultado.total_efectivo,
	]


func _formatear_dados(dados: Array[int]) -> String:
	var textos: Array[String] = []
	for dado in dados:
		textos.append(str(dado))
	return "[" + ", ".join(textos) + "]"
