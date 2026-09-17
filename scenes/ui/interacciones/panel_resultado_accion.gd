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
@onready var etiqueta_veredicto: Label = $Margen/Contenido/Veredicto
@onready var antetitulo: Label = $Margen/Contenido/Antetitulo
@onready var boton_cerrar: Button = $Margen/Contenido/Cerrar
@onready var contenedor_dados: HBoxContainer = $Margen/Contenido/Dados
@onready var vista_dado_1: Control = $Margen/Contenido/Dados/Dado1
@onready var vista_dado_2: Control = $Margen/Contenido/Dados/Dado2

var _texto_tirada_pendiente := ""
var _prueba_pendiente: ResultadoPrueba


func _ready() -> void:
	boton_cerrar.text = texto_boton_cerrar
	boton_cerrar.pressed.connect(ocultar)
	vista_dado_1.connect(&"animacion_finalizada", _revelar_tirada)


func mostrar_resultado(
	titulo: String,
	resultado: ResultadoAccion,
	catalogo: CatalogoMensajesInteraccion
) -> void:
	etiqueta_titulo.text = titulo
	_prueba_pendiente = null
	etiqueta_mensajes.text = _componer_mensajes(resultado, catalogo)
	etiqueta_veredicto.visible = false
	antetitulo.text = "R E S U L T A D O"
	contenedor_dados.visible = false
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
	antetitulo.text = "T I R A D A   D E   D A D O S"
	etiqueta_veredicto.visible = resultado is ResultadoPrueba
	etiqueta_veredicto.text = " "
	_texto_tirada_pendiente = (
		_componer_prueba(resultado)
		if resultado is ResultadoPrueba
		else _componer_cantidad(resultado)
	)
	if not mensajes.is_empty():
		_texto_tirada_pendiente += separador_mensajes + separador_mensajes.join(mensajes)
	_prueba_pendiente = resultado if resultado is ResultadoPrueba else null
	etiqueta_mensajes.text = "Lanzando dados…" if _prueba_pendiente != null else _texto_tirada_pendiente
	_mostrar_dados_prueba(resultado)
	visible = true
	boton_cerrar.grab_focus()
	tirada_presentada.emit(resultado)
	return true


func _mostrar_dados_prueba(resultado: Variant) -> void:
	contenedor_dados.visible = resultado is ResultadoPrueba
	if not resultado is ResultadoPrueba:
		return
	var dados: Array[int] = resultado.dados
	vista_dado_1.call(&"animar_a_valor", dados[0])
	vista_dado_2.visible = dados.size() > 1
	vista_dado_1.modulate = Color.WHITE
	if dados.size() > 1:
		vista_dado_2.call(&"animar_a_valor", dados[1])
		vista_dado_2.modulate = Color.WHITE


func _revelar_tirada() -> void:
	if not visible or _prueba_pendiente == null:
		return
	etiqueta_mensajes.text = _texto_tirada_pendiente
	etiqueta_veredicto.text = "%s · %s" % [
		"ÉXITO" if _prueba_pendiente.exitosa else "FALLO",
		String(ResultadoPrueba.Clasificacion.keys()[_prueba_pendiente.clasificacion]).to_upper().replace("CRITICO", "CRÍTICO"),
	]
	etiqueta_veredicto.add_theme_color_override("font_color",
		Color("365247") if _prueba_pendiente.exitosa else Color("883d32"))
	var dados := _prueba_pendiente.dados
	if dados.size() > 1 and dados[0] != dados[1]:
		if dados[0] == _prueba_pendiente.dado_seleccionado:
			vista_dado_2.modulate.a = 0.45
		else:
			vista_dado_1.modulate.a = 0.45
	_prueba_pendiente = null


func ocultar() -> void:
	if not visible:
		return
	_prueba_pendiente = null
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
	return "Modo: %s   ·   Atributo: %d\nDados: %s   ·   Seleccionado: %d" % [
		String(ResultadoPrueba.Modo.keys()[resultado.modo]).capitalize(),
		resultado.atributo,
		_formatear_dados(resultado.dados),
		resultado.dado_seleccionado,
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
