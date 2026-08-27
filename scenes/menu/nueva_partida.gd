extends Control

signal volver_solicitado

@onready var rigs: Array[Control] = [$RigIzquierdo, $RigCentral, $RigDerecho]
@onready var piezas_por_rig: Array[Array] = [
	[$RigIzquierdo/Encabezado, $RigIzquierdo/Atributos, $RigIzquierdo/Volver],
	[$RigCentral/Ficha],
	[$RigDerecho/Ritual, $RigDerecho/ComenzarRig],
]
@onready var cadenas_por_rig: Array[Array] = [
	$RigIzquierdo/Cadenas.get_children(),
	$RigCentral/Cadenas.get_children(),
	$RigDerecho/Cadenas.get_children(),
]

var posiciones_base: Array[Vector2] = []
var rotaciones_base: Dictionary[Control, float] = {}


func _ready() -> void:
	for rig in rigs:
		posiciones_base.append(rig.position)
		rig.pivot_offset = Vector2(rig.size.x * 0.5, 0.0)
	for piezas in piezas_por_rig:
		for pieza: Control in piezas:
			pieza.pivot_offset = pieza.size * 0.5
			rotaciones_base[pieza] = pieza.rotation_degrees
	for cadenas in cadenas_por_rig:
		for cadena: Control in cadenas:
			cadena.pivot_offset = Vector2(cadena.size.x * 0.5, 0.0)
			rotaciones_base[cadena] = cadena.rotation_degrees


func reproducir_entrada() -> Signal:
	show()
	var ultimo_tween: Tween
	for indice in rigs.size():
		var rig := rigs[indice]
		rig.position.y = -rig.size.y - 100.0
		rig.rotation_degrees = -2.5 if indice % 2 == 0 else 2.5
		var tween := create_tween()
		tween.tween_interval(indice * 0.1)
		tween.tween_property(rig, "position:y", posiciones_base[indice].y + 22.0, 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(rig, "rotation_degrees", 1.8, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_sacudir_rig.bind(indice))
		tween.tween_property(rig, "position:y", posiciones_base[indice].y - 10.0, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(rig, "rotation_degrees", -0.9, 0.12)
		tween.tween_property(rig, "position:y", posiciones_base[indice].y, 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(rig, "rotation_degrees", 0.0, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ultimo_tween = tween
	return ultimo_tween.finished


func _sacudir_rig(indice_rig: int) -> void:
	for indice in piezas_por_rig[indice_rig].size():
		var pieza: Control = piezas_por_rig[indice_rig][indice]
		var amplitud := 1.4 * pow(0.82, indice) * (1.0 if indice % 2 == 0 else -1.0)
		var tween := create_tween()
		tween.tween_interval(indice * 0.04)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] + amplitud, 0.09)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza] - amplitud * 0.45, 0.13)
		tween.tween_property(pieza, "rotation_degrees", rotaciones_base[pieza], 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for indice in cadenas_por_rig[indice_rig].size():
		var cadena: Control = cadenas_por_rig[indice_rig][indice]
		var direccion := 1.0 if indice % 2 == 0 else -1.0
		var tween := create_tween()
		tween.tween_interval(0.04 + indice * 0.015)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] + 3.2 * direccion, 0.11)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena] - 1.4 * direccion, 0.16)
		tween.tween_property(cadena, "rotation_degrees", rotaciones_base[cadena], 0.24) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func reproducir_salida() -> Signal:
	var tween := create_tween().set_parallel()
	for indice in rigs.size():
		var rig := rigs[indice]
		tween.tween_property(rig, "position:y", -rig.size.y - 100.0, 0.5) \
			.set_delay(indice * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween.finished


func _on_volver_pressed() -> void:
	volver_solicitado.emit()
