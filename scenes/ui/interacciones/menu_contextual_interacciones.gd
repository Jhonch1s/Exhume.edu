class_name MenuContextualInteracciones
extends PanelContainer

signal opcion_accion_elegida(opcion: OpcionAccion)
signal objetivo_elegido(objetivo: Interactuable)
signal cancelado

@export var separacion_opciones: int = 6

@onready var etiqueta_titulo: Label = $Margen/Contenido/Titulo
@onready var contenedor_opciones: VBoxContainer = $Margen/Contenido/Opciones


func _ready() -> void:
	contenedor_opciones.add_theme_constant_override(&"separation", separacion_opciones)


func mostrar(
	titulo: String,
	entradas: Array[EntradaMenuContextual],
	posicion_pantalla: Vector2
) -> void:
	_limpiar_opciones()
	etiqueta_titulo.text = titulo
	position = posicion_pantalla
	for entrada in entradas:
		_agregar_entrada(entrada)
	visible = true
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
