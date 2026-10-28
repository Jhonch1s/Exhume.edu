class_name HUD
extends Control

signal pasar_turno_solicitado
signal ataque_doble_solicitado
signal ocultarse_solicitado
signal bola_fuego_solicitada
signal habilidad_aprendida_solicitada
signal progresion_solicitada
signal item_rapido_solicitado(indice: int)

const RETRATOS_POR_CLASE := {
	"Guerrero": preload("res://assets/ui/panels/hud/retratos/guerrero.png"),
	"Ladrón": preload("res://assets/ui/panels/hud/retratos/ladron.png"),
	"Mago": preload("res://assets/ui/panels/hud/retratos/mago.png"),
}

@onready var retrato: TextureRect = $HUDRoot/SeccionesHUD/SeccionJugador/Retrato/Imagen
@onready var indicador_progresion: Button = $HUDRoot/SeccionesHUD/SeccionJugador/Retrato/IndicadorProgresion
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
@onready var reservas_turno: Array[PanelContainer] = [
	$HUDRoot/SeccionesHUD/ReservasTurno/Movimiento,
	$HUDRoot/SeccionesHUD/ReservasTurno/Principal,
	$HUDRoot/SeccionesHUD/ReservasTurno/Adicional,
	$HUDRoot/SeccionesHUD/ReservasTurno/Reaccion,
]
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
var ataque_doble_en_turno := false
var aprendida_disponible := false
var vida_objetivo := -1.0
var energia_objetivo := -1.0
var estado_hover: Control
var tooltip_estado: PanelContainer
var items_rapidos_asignados: Array[ItemInstancia] = [null, null, null, null]


func _ready() -> void:
	pasar_turno.pressed.connect(func(): pasar_turno_solicitado.emit())
	indicador_progresion.pressed.connect(func(): progresion_solicitada.emit())
	var pulso := create_tween().set_loops()
	pulso.tween_property(indicador_progresion.get_node("Flecha"), "modulate:a", 0.35, 0.65)
	pulso.tween_property(indicador_progresion.get_node("Flecha"), "modulate:a", 1.0, 0.65)
	for panel in estados:
		panel.mouse_entered.connect(_mostrar_tooltip_estado.bind(panel))
		panel.mouse_exited.connect(_ocultar_tooltip_estado)
	antorcha.visible = true
	for boton in habilidades + items_rapidos + [pasar_turno]:
		_conectar_feedback_boton(boton)
	for indice in habilidades.size():
		var habilidad := habilidades[indice]
		habilidad.disabled = true
		habilidad.tooltip_text = "Atajo %d · Habilidad todavía no implementada." % (indice + 1)
		var icono := TextureRect.new()
		icono.name = "IconoHabilidad"
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.visible = false
		habilidad.add_child(icono)
		icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var estado := Label.new()
		estado.name = "EstadoHabilidad"
		estado.position = Vector2(2, 59)
		estado.size = Vector2(78, 21)
		estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		estado.add_theme_font_size_override(&"font_size", 14)
		estado.add_theme_color_override(&"font_color", Color.WHITE)
		estado.add_theme_color_override(&"font_outline_color", Color.BLACK)
		estado.add_theme_constant_override(&"outline_size", 4)
		estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		estado.visible = false
		habilidad.add_child(estado)
		var tecla := Label.new()
		tecla.name = "TeclaHabilidad"
		tecla.position = Vector2(4, 1)
		tecla.text = str(indice + 1)
		tecla.add_theme_font_size_override(&"font_size", 14)
		tecla.add_theme_color_override(&"font_outline_color", Color.BLACK)
		tecla.add_theme_constant_override(&"outline_size", 3)
		tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tecla.visible = false
		habilidad.add_child(tecla)
	habilidades[0].pressed.connect(func(): ataque_doble_solicitado.emit())
	habilidades[0].pressed.connect(func(): ocultarse_solicitado.emit())
	habilidades[0].pressed.connect(func(): bola_fuego_solicitada.emit())
	habilidades[1].pressed.connect(func(): habilidad_aprendida_solicitada.emit())
	for indice in items_rapidos.size():
		var ranura := items_rapidos[indice]
		ranura.disabled = false
		ranura.pressed.connect(_on_ranura_item_rapido_pulsada.bind(indice))
		if ranura is CasillaItemRapido:
			ranura.item_arrastrado_soltado.connect(asignar_item_rapido)
			ranura.click_derecho_solicitado.connect(desasignar_item_rapido)
	$HUDRoot/SeccionesHUD/SeccionHabilidades/Titulo.tooltip_text = "Habilidades de clase; cada uso se recupera al descansar."
	$HUDRoot/SeccionesHUD/SeccionItems/Titulo.tooltip_text = "Acceso rápido a objetos. Arrastra ítems desde el inventario para asignarlos."
	$HUDRoot/SeccionesHUD/SeccionJugador/Retrato.tooltip_text = "Tu personaje"
	configurar_ficha(null)


func asignar_item_rapido(indice: int, item: ItemInstancia) -> void:
	if indice < 0 or indice >= items_rapidos_asignados.size() or item == null:
		return
	items_rapidos_asignados[indice] = item
	_actualizar_items()


func desasignar_item_rapido(indice: int) -> void:
	if indice < 0 or indice >= items_rapidos_asignados.size():
		return
	items_rapidos_asignados[indice] = null
	_actualizar_items()


func _on_ranura_item_rapido_pulsada(indice: int) -> void:
	if indice < 0 or indice >= items_rapidos_asignados.size():
		return
	if items_rapidos_asignados[indice] == null:
		return
	item_rapido_solicitado.emit(indice)


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
		if ficha.usos_habilidades_cambiados.is_connected(_actualizar_ataque_doble):
			ficha.usos_habilidades_cambiados.disconnect(_actualizar_ataque_doble)
	ficha = nueva_ficha
	if ficha != null:
		ficha.puntos_vida_cambiados.connect(_actualizar_vida)
		ficha.estado_cambiado.connect(_actualizar_estados)
		ficha.recursos_turno_cambiados.connect(_actualizar_recursos_turno)
		ficha.usos_habilidades_cambiados.connect(_actualizar_ataque_doble)
	_actualizar_todo()


func actualizar_desde_ficha() -> void:
	_actualizar_todo()


func configurar_ataque_doble_en_turno(valor: bool) -> void:
	ataque_doble_en_turno = valor
	_actualizar_ataque_doble()


func _process(_delta: float) -> void:
	if ficha != null:
		_actualizar_recursos_persistentes()
		_actualizar_items()


func _actualizar_todo() -> void:
	indicador_progresion.visible = ficha != null and ficha.nivel_recompensa_pendiente > 0
	if ficha == null:
		retrato.texture = null
		nombre.text = "SIN FICHA"
		$HUDRoot/SeccionesHUD/SeccionJugador/Retrato.tooltip_text = "Sin personaje."
		nombre.tooltip_text = "Sin personaje."
		vida_barra.value = 0.0
		vida_objetivo = 0.0
		vida_texto.text = "VIDA -- / --"
		vida_barra.tooltip_text = "Vida no disponible sin personaje."
		vida_texto.tooltip_text = vida_barra.tooltip_text
		energia_barra.value = 0.0
		energia_objetivo = 0.0
		energia_texto.text = "ENERGÍA -- / --"
		energia_barra.tooltip_text = "Energía no disponible sin personaje."
		energia_texto.tooltip_text = energia_barra.tooltip_text
		antorcha.text = "ANTORCHAS --"
		antorcha.tooltip_text = "Antorchas no disponibles sin personaje."
		for indice in antorcha_engarces.size():
			antorcha_luces[indice].color = Color("#28231b")
			antorcha_engarces[indice].tooltip_text = antorcha.tooltip_text
		experiencia_barra.value = 0.0
		experiencia_barra.tooltip_text = "Experiencia acumulada: 0 XP"
		_actualizar_estados()
		_actualizar_recursos_turno(null)
		_actualizar_items()
		_actualizar_ataque_doble()
		return
	retrato.texture = RETRATOS_POR_CLASE.get(ficha.clase) as Texture2D
	nombre.text = ficha.nombre
	$HUDRoot/SeccionesHUD/SeccionJugador/Retrato.tooltip_text = "%s · %s · Nivel %d" % [
		ficha.nombre, ficha.clase, ficha.nivel
	]
	nombre.tooltip_text = $HUDRoot/SeccionesHUD/SeccionJugador/Retrato.tooltip_text
	_actualizar_vida(ficha.pv_actual, ficha.pv_max)
	_actualizar_recursos_persistentes()
	_actualizar_experiencia()
	_actualizar_estados()
	_actualizar_recursos_turno(ficha.recursos_turno)
	_actualizar_items()
	_actualizar_ataque_doble()


func mostrar_icono_habilidad(indice: int, id: String, estado: String = "") -> void:
	var boton := habilidades[indice]
	var imagen := boton.get_node("IconoHabilidad") as TextureRect
	var etiqueta := boton.get_node("EstadoHabilidad") as Label
	var tecla := boton.get_node("TeclaHabilidad") as Label
	var textura := CatalogoHabilidades.icono(id)
	var visible := textura != null
	if imagen.visible != visible:
		for color in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_disabled_color", &"font_hover_pressed_color"]:
			if visible:
				boton.add_theme_color_override(color, Color.TRANSPARENT)
			else:
				boton.remove_theme_color_override(color)
	imagen.texture = textura
	imagen.visible = visible
	etiqueta.text = estado
	etiqueta.visible = visible and not estado.is_empty()
	tecla.visible = visible


func _actualizar_ataque_doble() -> void:
	_actualizar_aprendida()
	var boton := habilidades[0]
	var inicial := ""
	var estado := ""
	if ficha != null:
		match ficha.clase:
			"Guerrero":
				inicial = "ataque_doble"
				estado = "%d/1" % ficha.usos_ataque_doble
			"Ladrón":
				inicial = "ocultarse"
				estado = "OCULTO %d" % ficha.turnos_oculto if ficha.turnos_oculto > 0 else "%d/1" % ficha.usos_ocultarse
			"Mago":
				inicial = "bola_de_fuego"
				estado = "%d/1" % ficha.usos_bola_fuego
	mostrar_icono_habilidad(0, inicial, estado)
	if ficha != null and ficha.clase == "Mago":
		boton.text = "FUEGO\n%d/1" % ficha.usos_bola_fuego
		boton.add_theme_font_size_override(&"font_size", 14)
		boton.disabled = (
			not ataque_doble_en_turno or ficha.usos_bola_fuego == 0
			or ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1
		)
		boton.tooltip_text = "Atajo 1 · Bola de fuego: enemigo a 4 casillas. 1 daño y 50% de Quemado. Su celda siempre arde durante 3 turnos, aunque no quede Quemado. 1 acción principal y 1 uso por descanso. Esc cancela."
		return
	if ficha != null and ficha.clase == "Ladrón":
		boton.text = "OCULTAR\n%d/1" % ficha.usos_ocultarse
		if ficha.turnos_oculto > 0:
			boton.text = "OCULTO\n%d TURNOS" % ficha.turnos_oculto
		boton.add_theme_font_size_override(&"font_size", 14)
		boton.disabled = (
			not ataque_doble_en_turno or ficha.usos_ocultarse == 0
			or ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_ADICIONAL) < 1
		)
		boton.tooltip_text = (
			"Atajo 1 · Oculto %d turnos. Puedes moverte; atacar o recibir daño rompe el sigilo."
			% ficha.turnos_oculto if ficha.turnos_oculto > 0 else
			"Atajo 1 · Ocultarse: cuesta 1 acción adicional y 1 uso por descanso; dura 2 turnos."
		)
		return
	if ficha == null or ficha.clase != "Guerrero":
		boton.text = "I"
		boton.disabled = true
		boton.tooltip_text = "Atajo 1 · Ataque doble: habilidad del Guerrero."
		return
	boton.text = "DOBLE\n%d/1" % ficha.usos_ataque_doble
	boton.add_theme_font_size_override(&"font_size", 14)
	boton.disabled = (
		not ataque_doble_en_turno or ficha.usos_ataque_doble == 0
		or ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) < 1
	)
	boton.tooltip_text = "Atajo 1 · Ataque doble: selecciona un enemigo adyacente. Cuesta 1 acción principal y 1 uso por descanso. Esc cancela."
	if ficha.usos_ataque_doble == 0:
		boton.tooltip_text = "Atajo 1 · Ataque doble agotado. Descansa para recuperar su uso."


func _actualizar_aprendida() -> void:
	var boton := habilidades[1]
	boton.text = "II"
	boton.tooltip_text = "La recompensa de nivel 2 aparecerá aquí."
	if ficha == null:
		mostrar_icono_habilidad(1, "")
		boton.disabled = true
		return
	var ids := ficha.activas_aprendidas + ficha.pasivas_aprendidas
	if ids.is_empty():
		mostrar_icono_habilidad(1, "")
		boton.disabled = true
		return
	var deshabilitada := true
	var id: String = ids[0]
	var opcion := CatalogoHabilidades.obtener(id)
	boton.add_theme_font_size_override(&"font_size", 12)
	boton.text = opcion["nombre"].to_upper().replace(" ", "\n")
	if id == "transposicion":
		boton.text = "TRANSPONER"
	boton.tooltip_text = "Atajo 2 · %s\n%s\n%s" % [opcion["nombre"], opcion["descripcion"], opcion["coste"]]
	if opcion["tipo"] == "Activa":
		boton.text += "\n%d/1" % ficha.usos_activas.get(id, 0)
		if id == "agarre" and ficha.agarre_pasos > 0:
			boton.text += "\n%d PASOS" % ficha.agarre_pasos
		deshabilitada = not aprendida_disponible or ficha.usos_activas.get(id, 0) < 1 or ficha.obtener_recurso_turno(opcion["recurso"]) < 1
		if id == "paso_sombra" and ficha.turnos_oculto < 1:
			deshabilitada = true
			boton.tooltip_text += "\nFalta estar OCULTO. Se permite en combate con una acción adicional libre."
	elif id == "golpe_desplazante":
		boton.text = "EMPUJE\nAL ACERTAR"
	elif id == "contagio_arcano":
		deshabilitada = not aprendida_disponible
		boton.text = "CONTAGIO\n" + (ficha.contagio_elegido.to_upper() if ficha.contagio_elegido != "" else "NO")
	elif id == "inercia":
		boton.text = "INERCIA\n%d PASOS" % ficha.pasos_inercia
	else:
		boton.text += "\nPASIVA"
	if id in ficha.pasivas_usadas_turno:
		boton.tooltip_text += "\nYa usaste esta oportunidad durante el turno."
	var estado := "PASIVA"
	if opcion["tipo"] == "Activa":
		estado = "%d/1" % ficha.usos_activas.get(id, 0)
		if id == "agarre" and ficha.agarre_pasos > 0:
			estado = "%d PASOS" % ficha.agarre_pasos
	elif id == "contagio_arcano":
		estado = ficha.contagio_elegido.to_upper() if ficha.contagio_elegido != "" else "NO"
	elif id == "inercia" and ficha.pasos_inercia > 0:
		estado = "%d PASOS" % ficha.pasos_inercia
	mostrar_icono_habilidad(1, id, estado)
	# Cambiar disabled temporalmente cancela un clic que todavía está presionado.
	boton.disabled = deshabilitada


func _actualizar_vida(actual: int, maximo: int) -> void:
	vida_barra.max_value = maximo
	if not is_equal_approx(vida_objetivo, actual):
		vida_objetivo = actual
		_animar_barra(vida_barra, actual)
	vida_texto.text = "VIDA %d / %d" % [actual, maximo]
	vida_barra.tooltip_text = "Vida: %d de %d puntos. Si llega a 0, caes derrotado." % [actual, maximo]
	vida_texto.tooltip_text = vida_barra.tooltip_text


func _actualizar_recursos_persistentes() -> void:
	energia_barra.max_value = ficha.energia_maxima
	if not is_equal_approx(energia_objetivo, ficha.energia_actual):
		energia_objetivo = ficha.energia_actual
		_animar_barra(energia_barra, ficha.energia_actual)
	energia_texto.text = "ENERGÍA %d / %d" % [ficha.energia_actual, ficha.energia_maxima]
	energia_barra.tooltip_text = "Energía: %d de %d. Se gasta al moverte y en algunas acciones." % [
		ficha.energia_actual, ficha.energia_maxima
	]
	energia_texto.tooltip_text = energia_barra.tooltip_text
	var cantidad_antorchas := ficha.obtener_cantidad_antorchas()
	antorcha.text = "ANTORCHAS %d · %d PASOS" % [cantidad_antorchas, ficha.pasos_antorcha_actual]
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
			"Antorchas disponibles: %d\nPasos restantes de la antorcha actual: %d/%d."
			% [cantidad_antorchas, ficha.pasos_antorcha_actual, Ficha.PASOS_MAX_ANTORCHA]
		)
	antorcha.tooltip_text = antorcha_engarces[0].tooltip_text


func _actualizar_experiencia() -> void:
	var umbral_actual := 50 * ficha.nivel * (ficha.nivel - 1)
	var umbral_siguiente := 50 * ficha.nivel * (ficha.nivel + 1)
	experiencia_barra.max_value = umbral_siguiente - umbral_actual
	experiencia_barra.value = clampi(
		ficha.experiencia_acumulada - umbral_actual, 0, umbral_siguiente - umbral_actual
	)
	experiencia_barra.tooltip_text = "Experiencia: %d XP acumulados. Próximo nivel a %d XP." % [
		ficha.experiencia_acumulada, umbral_siguiente
	]


func _actualizar_recursos_turno(recursos: RecursosTurnoActor) -> void:
	_actualizar_ataque_doble()
	if recursos == null:
		pasar_turno.tooltip_text = "Pasar el turno"
		movimiento_barra.value = 0.0
		movimiento_barra.tooltip_text = "Movimiento no disponible sin personaje."
		_actualizar_engarces_acciones(0, 0)
		for indice in reservas_turno.size():
			(reservas_turno[indice].get_node("Texto") as Label).text = (
				["MOVIMIENTO", "PRINCIPAL", "ADICIONAL", "REACCIÓN"][indice] + " --"
			)
			reservas_turno[indice].tooltip_text = "Reserva no disponible sin personaje."
		return
	pasar_turno.text = "PASAR\nTURNO"
	pasar_turno.tooltip_text = "Pasar el turno y procesar estados"
	movimiento_barra.max_value = recursos.obtener_maximo(RecursosTurnoActor.MOVIMIENTO)
	_animar_barra(movimiento_barra, recursos.obtener(RecursosTurnoActor.MOVIMIENTO))
	_actualizar_reserva(0, "MOVIMIENTO", recursos, RecursosTurnoActor.MOVIMIENTO,
		"Casillas que puedes recorrer durante tu turno.")
	_actualizar_reserva(1, "PRINCIPAL", recursos, RecursosTurnoActor.ACCION_PRINCIPAL,
		"Se usa para atacar y realizar acciones principales.")
	_actualizar_reserva(2, "ADICIONAL", recursos, RecursosTurnoActor.ACCION_ADICIONAL,
		"La reserva existe, pero aún no hay acciones adicionales implementadas.", true)
	_actualizar_reserva(3, "REACCIÓN", recursos, RecursosTurnoActor.REACCION,
		"La reserva existe, pero aún no hay reacciones elegibles. La esquiva automática no la consume.", true)
	_actualizar_engarces_acciones(
		recursos.obtener_maximo(RecursosTurnoActor.ACCION_PRINCIPAL),
		recursos.obtener(RecursosTurnoActor.ACCION_PRINCIPAL)
	)


func _actualizar_reserva(
	indice: int, titulo: String, recursos: RecursosTurnoActor,
	clave: StringName, descripcion: String, pendiente: bool = false
) -> void:
	var reserva := reservas_turno[indice]
	var texto := reserva.get_node("Texto") as Label
	var restantes := recursos.obtener(clave)
	var maximo := recursos.obtener_maximo(clave)
	texto.text = "%s %d/%d" % [titulo, restantes, maximo]
	texto.add_theme_color_override(&"font_color", Color("#8f9290") if pendiente else (
		Color("#767371") if restantes == 0 else Color("#dbd3bc")
	))
	reserva.tooltip_text = "%s: %d de %d.\n%s" % [titulo.capitalize(), restantes, maximo, descripcion]
	if restantes == 0:
		reserva.tooltip_text += "\nReserva agotada."
	if indice == 0:
		movimiento_barra.tooltip_text = reserva.tooltip_text


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
		engarce.tooltip_text = (
			"Acción principal disponible" if indice < restantes else "Acción principal agotada"
		)


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
	elif clave in EfectosEquipo.PENALIZACIONES:
		titulo = "Atributo debilitado"
		descripcion = "-%d %s mientras dure el efecto." % [int(estado.magnitud), String(clave).trim_prefix("debilitado_").to_upper()]
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
	var inv: Inventario = ficha.obtener_inventario() if ficha != null else null
	for indice in items_rapidos.size():
		var ranura := items_rapidos[indice]
		var item: ItemInstancia = items_rapidos_asignados[indice] if indice < items_rapidos_asignados.size() else null
		if item != null and inv != null:
			var item_en_inv := inv.obtener_por_id(item.id_instancia)
			if item_en_inv == null or item_en_inv.cantidad <= 0:
				items_rapidos_asignados[indice] = null
				item = null
			else:
				item = item_en_inv
				items_rapidos_asignados[indice] = item_en_inv
		elif inv == null:
			item = null

		var icono := ranura.get_node_or_null("Icono") as TextureRect
		var cantidad := ranura.get_node_or_null("Cantidad") as Label
		if icono != null:
			icono.texture = item.definicion.icono if item != null else null
			icono.visible = item != null and icono.texture != null
		if cantidad != null:
			cantidad.text = str(item.cantidad) if item != null and item.cantidad > 1 else ""
		ranura.text = ""
		if item != null:
			ranura.tooltip_text = (
				"Atajo %d · %s (x%d)\n%s\nClic o atajo para usar (clic derecho para retirar)."
				% [indice + 5, item.definicion.nombre, item.cantidad, item.definicion.descripcion_base]
			)
		else:
			ranura.tooltip_text = (
				"Atajo %d · Ranura rápida vacía.\nArrastra un ítem aquí desde el inventario para asignarlo."
				% (indice + 5)
			)
