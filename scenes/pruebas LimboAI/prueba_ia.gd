extends Node

## Ejemplo interactivo de decisiones, separado de la ejecución del combate.

@onready var bt_player: BTPlayer = $BTPlayer

var _distancia: SpinBox
var _movimiento: SpinBox
var _accion_principal: CheckButton
var _hay_camino: CheckButton
var _resultado: Label
var _traza: Label


func _ready() -> void:
	_crear_panel()
	_evaluar()


func _crear_panel() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 32)
	add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	_agregar_texto(columna, "Primer árbol de decisiones del NPC", 28)
	_agregar_texto(columna, "Cambia las condiciones y pulsa Evaluar decisión.\nEste ejemplo elige una acción; no mueve ni ataca a personajes.", 20)
	_distancia = _agregar_numero(columna, "Distancia al jugador en casillas", 1, 10, 3)
	_movimiento = _agregar_numero(columna, "Movimiento disponible", 0, 10, 2)
	_accion_principal = CheckButton.new()
	_accion_principal.text = "Tengo acción principal disponible"
	_accion_principal.button_pressed = true
	columna.add_child(_accion_principal)
	_hay_camino = CheckButton.new()
	_hay_camino.text = "Hay camino hacia una casilla junto al jugador"
	_hay_camino.button_pressed = true
	columna.add_child(_hay_camino)
	var boton := Button.new()
	boton.text = "Evaluar decisión"
	boton.custom_minimum_size.y = 48
	boton.pressed.connect(_evaluar)
	columna.add_child(boton)
	_resultado = _agregar_texto(columna, "", 24)
	_traza = _agregar_texto(columna, "", 20)
	_agregar_texto(columna, "Selector: prueba las ramas por orden y se queda con la primera que tiene éxito.\nSecuencia: comprueba la condición y, si se cumple, ejecuta su acción.\nBlackboard: memoria compartida donde ponemos condiciones y leemos la decisión.", 18)


func _agregar_texto(contenedor: VBoxContainer, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override(&"font_size", tamano)
	contenedor.add_child(etiqueta)
	return etiqueta


func _agregar_numero(
	contenedor: VBoxContainer, titulo: String, minimo: int, maximo: int, inicial: int
) -> SpinBox:
	_agregar_texto(contenedor, titulo, 18)
	var numero := SpinBox.new()
	numero.min_value = minimo
	numero.max_value = maximo
	numero.step = 1
	numero.value = inicial
	contenedor.add_child(numero)
	return numero


func _evaluar() -> void:
	var memoria: Blackboard = bt_player.blackboard
	memoria.set_var(&"puede_atacar", _accion_principal.button_pressed and int(_distancia.value) == 1)
	memoria.set_var(&"puede_acercarse", int(_distancia.value) > 1 and _movimiento.value > 0 and _hay_camino.button_pressed)
	memoria.set_var(&"decision", &"")
	memoria.set_var(&"traza", [])
	# Cada pulsación comienza una evaluación nueva con las condiciones actuales.
	bt_player.restart()
	bt_player.update(0.0)
	var decision: StringName = memoria.get_var(&"decision", &"")
	match decision:
		&"atacar":
			_resultado.text = "Decisión: ATACAR. Tengo acción principal y el jugador está junto a mí."
		&"acercarse":
			_resultado.text = "Decisión: ACERCARSE. Estoy lejos, tengo movimiento y hay camino."
		&"terminar_turno":
			_resultado.text = "Decisión: TERMINAR TURNO. Ninguna de las ramas anteriores pudo ejecutarse."
		_:
			_resultado.text = "El árbol no eligió una acción. Revisa sus tareas en LimboAI."
	var pasos: Array = memoria.get_var(&"traza", [])
	_traza.text = "Recorrido de esta evaluación:\n" + "\n".join(pasos)
	print("PruebaIA: %s\n%s" % [decision, _traza.text])
