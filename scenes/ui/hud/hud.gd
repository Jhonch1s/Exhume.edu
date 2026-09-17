class_name HUD
extends Control

signal pasar_turno_solicitado

const RETRATOS_POR_CLASE := {
	"Guerrero": preload("res://assets/ui/panels/hud/retratos/guerrero.png"),
	"Ladrón": preload("res://assets/ui/panels/hud/retratos/ladron.png"),
	"Mago": preload("res://assets/ui/panels/hud/retratos/mago.png"),
}

@onready var retrato: TextureRect = $HUDRoot/SeccionesHUD/SeccionJugador/Retrato/Imagen
@onready var nombre: Label = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/Nombre
@onready var vida_barra: ProgressBar = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/VidaBarra
@onready var vida_texto: Label = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/VidaTexto
@onready var energia_barra: ProgressBar = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/EnergiaBarra
@onready var energia_texto: Label = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/EnergiaTexto
@onready var antorcha: Label = $HUDRoot/SeccionesHUD/SeccionJugador/Recursos/Antorcha
@onready var antorcha_engarces: Array[Panel] = [
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce1,
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce2,
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce3,
]
@onready var antorcha_luces: Array[ColorRect] = [
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce1/Luz,
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce2/Luz,
	$HUDRoot/SeccionesHUD/SeccionJugador/EngarcesAntorchas/Engarce3/Luz,
]
@onready var pasar_turno: Button = $HUDRoot/SeccionesHUD/PasarTurno
@onready var engarces_acciones: VBoxContainer = $HUDRoot/SeccionesHUD/EngarcesAcciones
@onready var movimiento_barra: ProgressBar = $HUDRoot/SeccionesHUD/MovimientoBarra
@onready var experiencia_barra: ProgressBar = $HUDRoot/ExperienciaBarra
@onready var habilidades: Array[Button] = [
	$HUDRoot/SeccionesHUD/SeccionHabilidades/Ranura1,
	$HUDRoot/SeccionesHUD/SeccionHabilidades/Ranura2,
	$HUDRoot/SeccionesHUD/SeccionHabilidades/Ranura3,
	$HUDRoot/SeccionesHUD/SeccionHabilidades/Ranura4,
]
@onready var items_rapidos: Array[Button] = [
	$HUDRoot/SeccionesHUD/SeccionItems/Ranura1,
	$HUDRoot/SeccionesHUD/SeccionItems/Ranura2,
	$HUDRoot/SeccionesHUD/SeccionItems/Ranura3,
	$HUDRoot/SeccionesHUD/SeccionItems/Ranura4,
]
@onready var estados: Array[Control] = [
	$HUDRoot/SeccionesHUD/EstadosAlterados/EstadoQuemado,
	$HUDRoot/SeccionesHUD/EstadosAlterados/EstadoEnvenenado,
	$HUDRoot/SeccionesHUD/EstadosAlterados/EstadoCansado,
]

var ficha: Ficha
var vida_objetivo := -1.0
var energia_objetivo := -1.0
var estado_hover: Control
var tooltip_estado: PanelContainer


func _ready() -> void:
	pasar_turno.pressed.connect(func(): pasar_turno_solicitado.emit())
	for panel in estados:
		panel.mouse_entered.connect(_mostrar_tooltip_estado.bind(panel))
		panel.mouse_exited.connect(_ocultar_tooltip_estado)
	antorcha.visible = false
	for boton in habilidades + items_rapidos + [pasar_turno]:
		_conectar_feedback_boton(boton)
	for habilidad in habilidades:
		habilidad.disabled = true
	configurar_ficha(null)


func _conectar_feedback_boton(boton: Button) -> void:
	boton.mouse_entered.connect(func(): boton.modulate = Color("#f0d69c"))
	boton.mouse_exited.connect(func(): boton.modulate = Color.WHITE)
	boton.button_down.connect(func(): boton.modulate = Color("#c47d32"))
	boton.button_up.connect(func(): boton.modulate = Color("#f0d69c"))


func configurar_ficha(nueva_ficha: Ficha) -> void:
	if ficha != null:
		if ficha.puntos_vida_cambiados.is_connected(_actualizar_vida):
			ficha.puntos_vida_cambiados.disconnect(_actualizar_vida)
		if ficha.estado_cambiado.is_connected(_actualizar_estados):
			ficha.estado_cambiado.disconnect(_actualizar_estados)
		if ficha.recursos_turno_cambiados.is_connected(_actualizar_recursos_turno):
			ficha.recursos_turno_cambiados.disconnect(_actualizar_recursos_turno)
	ficha = nueva_ficha
	if ficha != null:
		ficha.puntos_vida_cambiados.connect(_actualizar_vida)
		ficha.estado_cambiado.connect(_actualizar_estados)
		ficha.recursos_turno_cambiados.connect(_actualizar_recursos_turno)
	_actualizar_todo()


func actualizar_desde_ficha() -> void:
	_actualizar_todo()


func _process(_delta: float) -> void:
	if ficha != null:
		_actualizar_recursos_persistentes()
		_actualizar_items()


func _actualizar_todo() -> void:
	if ficha == null:
		retrato.texture = null
		nombre.text = "SIN FICHA"
		vida_barra.value = 0.0
		vida_objetivo = 0.0
		vida_texto.text = "-- / --"
		energia_barra.value = 0.0
		energia_objetivo = 0.0
		energia_texto.text = "-- / --"
		antorcha.text = "ANTORCHA   --"
		_actualizar_estados()
		_actualizar_recursos_turno(null)
		_actualizar_items()
		return
	retrato.texture = RETRATOS_POR_CLASE.get(ficha.clase) as Texture2D
	nombre.text = ficha.nombre
	_actualizar_vida(ficha.pv_actual, ficha.pv_max)
	_actualizar_recursos_persistentes()
	_actualizar_estados()
	_actualizar_recursos_turno(ficha.recursos_turno)
	_actualizar_items()


func _actualizar_vida(actual: int, maximo: int) -> void:
	vida_barra.max_value = maximo
	if not is_equal_approx(vida_objetivo, actual):
		vida_objetivo = actual
		_animar_barra(vida_barra, actual)
	vida_texto.text = "%d / %d" % [actual, maximo]


func _actualizar_recursos_persistentes() -> void:
	energia_barra.max_value = ficha.energia_maxima
	if not is_equal_approx(energia_objetivo, ficha.energia_actual):
		energia_objetivo = ficha.energia_actual
		_animar_barra(energia_barra, ficha.energia_actual)
	energia_texto.text = "%d / %d" % [ficha.energia_actual, ficha.energia_maxima]
	var cantidad_antorchas := ficha.obtener_cantidad_antorchas()
	antorcha.text = "ANTORCHA   %02d   (%02d)" % [cantidad_antorchas, ficha.pasos_antorcha_actual]
	for indice in antorcha_engarces.size():
		var encendido := indice < mini(cantidad_antorchas, antorcha_engarces.size())
		antorcha_engarces[indice].modulate = Color.WHITE
		var color_luz := Color("#f39a35") if encendido else Color("#28231b")
		if encendido and indice == mini(cantidad_antorchas, antorcha_engarces.size()) - 1:
			var progreso := clampf(
				float(ficha.pasos_antorcha_actual) / Ficha.PASOS_MAX_ANTORCHA,
				0.0,
				1.0
			)
			color_luz = Color("#7c3f20").lerp(color_luz, progreso)
		antorcha_luces[indice].color = color_luz
		antorcha_engarces[indice].tooltip_text = (
			"Antorchas: %d | Desgaste: %d/%d"
			% [cantidad_antorchas, ficha.pasos_antorcha_actual, Ficha.PASOS_MAX_ANTORCHA]
		)


func _actualizar_recursos_turno(recursos: RecursosTurnoActor) -> void:
	if recursos == null:
		pasar_turno.tooltip_text = "Pasar el turno"
		movimiento_barra.value = 0.0
		_actualizar_engarces_acciones(0, 0)
		return
	pasar_turno.text = "PASAR\nTURNO"
	pasar_turno.tooltip_text = "Pasar el turno y procesar estados"
	movimiento_barra.max_value = recursos.obtener_maximo(RecursosTurnoActor.MOVIMIENTO)
	_animar_barra(movimiento_barra, recursos.obtener(RecursosTurnoActor.MOVIMIENTO))
	_actualizar_engarces_acciones(
		recursos.obtener_maximo(RecursosTurnoActor.ACCION_PRINCIPAL),
		recursos.obtener(RecursosTurnoActor.ACCION_PRINCIPAL)
	)


func _actualizar_engarces_acciones(maximo: int, restantes: int) -> void:
	while engarces_acciones.get_child_count() < maximo:
		var engarce := Panel.new()
		engarce.custom_minimum_size = Vector2(18, 18)
		engarce.add_theme_stylebox_override(
			&"panel",
			$HUDRoot/SeccionesHUD/SeccionHabilidades/Ranura1.get_theme_stylebox(&"normal").duplicate()
		)
		var luz := ColorRect.new()
		luz.name = "Luz"
		luz.offset_left = 5.0
		luz.offset_top = 5.0
		luz.offset_right = 13.0
		luz.offset_bottom = 13.0
		luz.color = Color("#28231b")
		luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		engarce.add_child(luz)
		engarces_acciones.add_child(engarce)
	while engarces_acciones.get_child_count() > maximo:
		engarces_acciones.get_child(-1).free()
	for indice in maximo:
		var engarce := engarces_acciones.get_child(indice) as Panel
		engarce.modulate = Color.WHITE
		(engarce.get_node("Luz") as ColorRect).color = (
			Color("#d99543") if indice < restantes else Color("#28231b")
		)
		engarce.tooltip_text = "Acción disponible" if indice < restantes else "Acción agotada"


func _animar_barra(barra: ProgressBar, valor: float) -> void:
	var tween := create_tween()
	tween.tween_property(barra, "value", valor, 0.16)


func _actualizar_estados(_clave: StringName = &"", _estado: EstadoActor = null) -> void:
	if ficha == null:
		_ocultar_tooltip_estado()
		for panel in estados:
			panel.visible = false
		return
	var claves := ficha.obtener_claves_estado()
	for indice in estados.size():
		var panel := estados[indice]
		if indice >= claves.size():
			panel.visible = false
			continue
		var clave := claves[indice]
		var estado := ficha.obtener_estado(clave)
		panel.visible = true
		panel.tooltip_text = _descripcion_estado(clave, estado)
		var icono := panel.get_node("Icono") as Label
		icono.text = String(clave).left(1).to_upper()
		icono.modulate = _color_estado(clave)
	if estado_hover != null:
		_mostrar_tooltip_estado(estado_hover)


func _mostrar_tooltip_estado(panel: Control) -> void:
	_ocultar_tooltip_estado()
	if not panel.visible or panel.tooltip_text.is_empty():
		return
	estado_hover = panel
	tooltip_estado = panel.call(&"_make_custom_tooltip", panel.tooltip_text) as PanelContainer
	tooltip_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in tooltip_estado.get_children():
		(hijo as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		for nieto in hijo.get_children():
			(nieto as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_estado.z_index = 10
	$HUDRoot.add_child(tooltip_estado)
	tooltip_estado.reset_size()
	var pantalla := get_viewport_rect().size
	var ancla := panel.get_global_rect()
	tooltip_estado.global_position = Vector2(
		clampf(ancla.position.x, 0.0, maxf(0.0, pantalla.x - tooltip_estado.size.x)),
		clampf(
			ancla.position.y - tooltip_estado.size.y - 8.0,
			0.0,
			maxf(0.0, pantalla.y - tooltip_estado.size.y)
		)
	)


func _ocultar_tooltip_estado() -> void:
	estado_hover = null
	if tooltip_estado != null:
		tooltip_estado.free()
		tooltip_estado = null


func _descripcion_estado(clave: StringName, estado: EstadoActor) -> String:
	var titulo := String(clave).capitalize()
	var descripcion := ""
	var terminos := estado.terminos_dano_tick
	if not terminos.is_empty():
		var dados: Array[String] = []
		for termino in terminos:
			dados.append("%dd%d" % [termino[&"cantidad"], termino[&"caras"]])
		descripcion = "%s de daño al terminar cada turno." % " + ".join(dados)
	elif clave in [&"quemado", &"veneno"]:
		descripcion = "%d de daño al terminar cada turno." % int(estado.magnitud)
	elif clave == &"enredado":
		descripcion = "No puedes moverte. Debes destrabarte."
	elif clave == &"caido":
		titulo = "Caído"
		descripcion = "Te levantarás al terminar este turno."
	else:
		descripcion = "Efecto activo."
	if estado.ticks_pendientes > 0:
		var restantes := estado.ticks_pendientes
		descripcion += "\n%d %s" % [
			restantes, "turno restante." if restantes == 1 else "turnos restantes."
		]
	return "%s\n%s" % [titulo, descripcion]


func _color_estado(clave: StringName) -> Color:
	var texto := String(clave).to_lower()
	if "quem" in texto or "fuego" in texto:
		return Color("#ef7134")
	if "venen" in texto:
		return Color("#82bd55")
	if "enred" in texto or "inmov" in texto:
		return Color("#b88be0")
	return Color("#d6bd68")


func _actualizar_items() -> void:
	if ficha == null:
		for ranura in items_rapidos:
			ranura.text = "—"
			ranura.tooltip_text = "Ranura de item rápido vacía"
		return
	var contenido := ficha.obtener_inventario().obtener_contenido()
	for indice in items_rapidos.size():
		var ranura := items_rapidos[indice]
		if indice >= contenido.size():
			ranura.text = "—"
			ranura.tooltip_text = "Ranura de item rápido vacía"
			continue
		var item := contenido[indice]
		ranura.text = "%s\n×%d" % [item.definicion.nombre.left(8), item.cantidad]
		ranura.tooltip_text = item.definicion.nombre
