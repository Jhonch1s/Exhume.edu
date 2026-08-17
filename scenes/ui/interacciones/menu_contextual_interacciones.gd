class_name MenuContextualInteracciones
extends PanelContainer

signal opcion_accion_elegida(opcion: OpcionAccion)
signal objetivo_elegido(objetivo: Interactuable)
signal cancelado

@export var separacion_opciones: int = 6
@export_range(0.0, 64.0, 1.0) var margen_viewport: float = 8.0

@onready var etiqueta_titulo: Label = $Margen/Contenido/Titulo
@onready var contenedor_opciones: VBoxContainer = $Margen/Contenido/Opciones

var _posicion_solicitada: Vector2 = Vector2.ZERO


func _ready() -> void:
	contenedor_opciones.add_theme_constant_override(&"separation", separacion_opciones)
	get_viewport().size_changed.connect(_ajustar_posicion_al_viewport)


func mostrar(
	titulo: String,
	entradas: Array[EntradaMenuContextual],
	posicion_pantalla: Vector2
) -> void:
	_limpiar_opciones()
	etiqueta_titulo.text = titulo
	_posicion_solicitada = posicion_pantalla
	for entrada in entradas:
		_agregar_entrada(entrada)
	visible = true
	reset_size()
	_ajustar_posicion_al_viewport()
	call_deferred(&"_ajustar_posicion_al_viewport")
	_enfocar_primera_entrada_habilitada()


func ocultar() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	if foco is Control and is_ancestor_of(foco):
		foco.release_focus()
	visible = false
	_limpiar_opciones()


func obtener_botones() -> Array[Button]:
	var botones: Array[Button] = []
	for hijo in contenedor_opciones.get_children():
		if hijo is Button:
			botones.append(hijo)
	return botones


func navegar(direccion: int) -> bool:
	var botones_habilitados: Array[Button] = []
	for boton in obtener_botones():
		if not boton.disabled and boton.visible:
			botones_habilitados.append(boton)
	if botones_habilitados.is_empty():
		return false

	var foco := get_viewport().gui_get_focus_owner() as Button
	var indice := botones_habilitados.find(foco)
	if indice < 0:
		indice = 0 if direccion >= 0 else botones_habilitados.size() - 1
	else:
		indice = posmod(indice + signi(direccion), botones_habilitados.size())
	botones_habilitados[indice].grab_focus()
	return true


func activar_entrada_en_foco() -> bool:
	var foco := get_viewport().gui_get_focus_owner() as Button
	if foco == null or foco.disabled or not foco in obtener_botones():
		return false
	foco.pressed.emit()
	return true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		cancelado.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		if navegar(-1):
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		if navegar(1):
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		if activar_entrada_en_foco():
			get_viewport().set_input_as_handled()


func _agregar_entrada(entrada: EntradaMenuContextual) -> void:
	if entrada == null:
		return
	var boton := Button.new()
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.disabled = not entrada.habilitada
	boton.text = entrada.texto
	if not entrada.habilitada and not entrada.motivo_bloqueo.is_empty():
		boton.text += "\n" + entrada.motivo_bloqueo
		boton.tooltip_text = entrada.motivo_bloqueo
	boton.pressed.connect(_on_entrada_pulsada.bind(entrada))
	contenedor_opciones.add_child(boton)


func _on_entrada_pulsada(entrada: EntradaMenuContextual) -> void:
	match entrada.tipo:
		EntradaMenuContextual.TipoEntrada.ACCION:
			opcion_accion_elegida.emit(entrada.opcion_accion)
		EntradaMenuContextual.TipoEntrada.OBJETIVO:
			objetivo_elegido.emit(entrada.objetivo)
		EntradaMenuContextual.TipoEntrada.CANCELAR:
			cancelado.emit()


func _enfocar_primera_entrada_habilitada() -> void:
	for boton in obtener_botones():
		if not boton.disabled:
			boton.grab_focus()
			return


func _limpiar_opciones() -> void:
	if not is_instance_valid(contenedor_opciones):
		return
	for hijo in contenedor_opciones.get_children():
		contenedor_opciones.remove_child(hijo)
		hijo.queue_free()


func _ajustar_posicion_al_viewport() -> void:
	if not visible:
		return
	var tamano_viewport := get_viewport_rect().size
	var tamano_menu := size.max(get_combined_minimum_size())
	var minimo := Vector2(margen_viewport, margen_viewport)
	var maximo := Vector2(
		maxf(minimo.x, tamano_viewport.x - tamano_menu.x - margen_viewport),
		maxf(minimo.y, tamano_viewport.y - tamano_menu.y - margen_viewport)
	)
	position = Vector2(
		clampf(_posicion_solicitada.x, minimo.x, maximo.x),
		clampf(_posicion_solicitada.y, minimo.y, maximo.y)
	)
