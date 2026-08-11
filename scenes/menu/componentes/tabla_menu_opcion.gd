extends Control
class_name TablaMenuOpcion

signal presionado

@export var texto: String = 'OPCIÓN':
	set(nuevo_texto):
		texto=nuevo_texto
		if is_node_ready():
			boton.text = texto

@onready var boton: Button = $Boton

@export_range(1.0, 1.2, 0.01) var escala_hover: float = 1.06
@export_range(0.05, 0.5, 0.01) var duracion_hover: float = 0.12

#gracias tween por existir
var tween_hover: Tween

func _ready() -> void:
	boton.text=texto
	_centrar_pivote()
	
	boton.resized.connect(_centrar_pivote)
	boton.mouse_entered.connect(_on_hover_entrar)
	boton.mouse_exited.connect(_on_hover_salir)
	boton.pressed.connect(_on_boton_pressed)

func _centrar_pivote()->void:
	boton.pivot_offset = boton.size * 0.5
	
func _on_hover_entrar()-> void:
	_animar_escala(escala_hover)

func _on_hover_salir()->void:
	_animar_escala(1.0)

func _animar_escala(escala_objetivo: float) -> void:
	if tween_hover != null and tween_hover.is_valid():
		tween_hover.kill()

	tween_hover = create_tween()
	tween_hover.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_hover.tween_property(
		boton,
		"scale",
		Vector2.ONE * escala_objetivo,
		duracion_hover
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_boton_pressed()->void:
	presionado.emit()
