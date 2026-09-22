class_name VistaDado3D
extends SubViewportContainer

signal animacion_finalizada
signal presionado

# Renderizar menos píxeles y ampliarlos sin interpolación también escalona
# la silueta y las runas. 1 permite comparar con el acabado original.
@export_range(1, 6, 1) var tamano_pixel: int = 3:
	set(valor):
		tamano_pixel = clampi(valor, 1, 6)
		stretch_shrink = tamano_pixel
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if tamano_pixel > 1 else CanvasItem.TEXTURE_FILTER_LINEAR

## 0 desactiva; 1 rellena la transparencia del borde; 2 y 3 lo expanden.
@export_range(0, 3, 1) var grosor_contorno: int = 1:
	set(valor):
		grosor_contorno = clampi(valor, 0, 3)
		_actualizar_contorno()

@export var color_contorno := Color("090e16"):
	set(valor):
		color_contorno = valor
		_actualizar_contorno()

const ANGULOS_POR_VALOR := {
	1: 270.0,
	2: 30.0,
	3: 150.0,
	4: 90.0,
	5: 330.0,
	6: 210.0,
}

@onready var pivote_dado: Node3D = $SubViewport/PivoteDado
@onready var modelo_dado: Node3D = $SubViewport/PivoteDado/Dado

var _animacion: Tween
var _esta_en_hover := false


# Los materiales PBR y las texturas horneadas se importan desde dadico.glb.
# No reemplazarlos: incluyen el cuerpo de piedra y las ranuras emisivas.


func _ready() -> void:
	_actualizar_contorno()
	mouse_entered.connect(_al_entrar_mouse)
	mouse_exited.connect(_al_salir_mouse)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		presionado.emit()
		accept_event()


func _al_entrar_mouse() -> void:
	_esta_en_hover = true
	_actualizar_contorno()


func _al_salir_mouse() -> void:
	_esta_en_hover = false
	_actualizar_contorno()


func _actualizar_contorno() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("grosor_contorno", float(grosor_contorno))
		material.set_shader_parameter(
			"color_contorno", Color.WHITE if _esta_en_hover else color_contorno
		)


func mostrar_valor(valor: int) -> void:
	if not ANGULOS_POR_VALOR.has(valor):
		return
	if _animacion != null and _animacion.is_running():
		_animacion.kill()
	pivote_dado.rotation_degrees = Vector3(0.0, float(ANGULOS_POR_VALOR[valor]), 0.0)


func animar_a_valor(valor: int) -> void:
	if not ANGULOS_POR_VALOR.has(valor):
		return
	if _animacion != null and _animacion.is_running():
		_animacion.kill()
	var angulo_actual := pivote_dado.rotation_degrees.y
	var diferencia := fposmod(float(ANGULOS_POR_VALOR[valor]) - fposmod(angulo_actual, 360.0), 360.0)
	_animacion = create_tween()
	_animacion.tween_property(
		pivote_dado, "rotation_degrees:y", angulo_actual + 1440.0 + diferencia, 1.35
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_animacion.tween_callback(animacion_finalizada.emit)
