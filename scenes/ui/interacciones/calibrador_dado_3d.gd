extends Control

@onready var pivote_dado: Node3D = $Panel/Margen/Contenido/Vista/SubViewport/PivoteDado
@onready var etiqueta_angulo: Label = $Panel/Margen/Contenido/Controles/Angulo

const OFFSET_CARA_GRADOS := 30

var indice_cara := 0


func _ready() -> void:
	$Panel/Margen/Contenido/Controles/Anterior.pressed.connect(_cambiar_cara.bind(-1))
	$Panel/Margen/Contenido/Controles/Siguiente.pressed.connect(_cambiar_cara.bind(1))
	_mostrar_cara()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		_cambiar_cara(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		_cambiar_cara(1)
		get_viewport().set_input_as_handled()


func _cambiar_cara(paso: int) -> void:
	indice_cara = posmod(indice_cara + paso, 6)
	_mostrar_cara()


func _mostrar_cara() -> void:
	var angulo := OFFSET_CARA_GRADOS + indice_cara * 60
	pivote_dado.rotation_degrees = Vector3(0, angulo, 0)
	etiqueta_angulo.text = "Rotación Y: %d°" % angulo
