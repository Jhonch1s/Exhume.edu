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
@onready var etiqueta_objetivo: Label = $Margen/Contenido/Objetivo
@onready var etiqueta_bonos: Label = $Margen/Contenido/Bonos
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
	etiqueta_mensajes.visible = not etiqueta_mensajes.text.is_empty()
	etiqueta_veredicto.visible = false
	etiqueta_objetivo.visible = false
	etiqueta_bonos.visible = false
	antetitulo.text = "R E S U L T A D O"
	antetitulo.visible = true
	contenedor_dados.visible = false
	visible = true
	_ajustar_altura()
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
	etiqueta_veredicto.visible = false
	if resultado is ResultadoPrueba:
		antetitulo.visible = resultado.modo != ResultadoPrueba.Modo.NORMAL
		antetitulo.text = (
			"V E N T A J A" if resultado.modo == ResultadoPrueba.Modo.VENTAJA
			else "D E S V E N T A J A"
		)
		etiqueta_objetivo.text = "OBJETIVO  ·  %d O MENOS" % resultado.atributo_efectivo
		etiqueta_objetivo.visible = true
		etiqueta_bonos.text = _componer_bonos(resultado)
		etiqueta_bonos.visible = not resultado.modificadores.is_empty()
		_texto_tirada_pendiente = separador_mensajes.join(mensajes)
		etiqueta_mensajes.text = ""
		etiqueta_mensajes.visible = false
	else:
		antetitulo.text = "T I R A D A"
		antetitulo.visible = true
		etiqueta_objetivo.visible = false
		etiqueta_bonos.visible = false
		_texto_tirada_pendiente = _componer_cantidad(resultado)
		if not mensajes.is_empty():
			_texto_tirada_pendiente += separador_mensajes + separador_mensajes.join(mensajes)
		etiqueta_mensajes.text = _texto_tirada_pendiente
		etiqueta_mensajes.visible = true
	_prueba_pendiente = resultado if resultado is ResultadoPrueba else null
	_mostrar_dados_prueba(resultado)
	visible = true
	_ajustar_altura()
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
	etiqueta_mensajes.visible = not _texto_tirada_pendiente.is_empty()
	var estado := "ÉXITO" if _prueba_pendiente.exitosa else "FALLO"
	if _prueba_pendiente.clasificacion == ResultadoPrueba.Clasificacion.CRITICO:
		estado = "ÉXITO CRÍTICO"
	elif _prueba_pendiente.clasificacion == ResultadoPrueba.Clasificacion.PIFIA:
		estado = "PIFIA"
	etiqueta_veredicto.text = "%d  ·  %s" % [_prueba_pendiente.dado_seleccionado, estado]
	etiqueta_veredicto.visible = true
	etiqueta_veredicto.add_theme_color_override("font_color",
		Color("365247") if _prueba_pendiente.exitosa else Color("883d32"))
	var dados := _prueba_pendiente.dados
	if dados.size() > 1 and dados[0] != dados[1]:
		if dados[0] == _prueba_pendiente.dado_seleccionado:
			vista_dado_2.modulate.a = 0.45
		else:
			vista_dado_1.modulate.a = 0.45
	_prueba_pendiente = null
	_ajustar_altura()


func _ajustar_altura() -> void:
	await get_tree().process_frame
	if not visible:
		return
	var mitad_altura := get_combined_minimum_size().y * 0.5
	offset_top = -mitad_altura
	offset_bottom = mitad_altura


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


func _componer_bonos(resultado: ResultadoPrueba) -> String:
	var partes: Array[String] = ["Base %d" % resultado.atributo]
	for modificador in resultado.modificadores:
		var valor: int = modificador[&"valor"]
		var fuente := String(modificador[&"fuente"]).replace("_", " ").capitalize()
		partes.append("%s%d %s" % ["+" if valor >= 0 else "−", absi(valor), fuente])
	return " ".join(partes) + "  =  %d" % resultado.atributo_efectivo


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
