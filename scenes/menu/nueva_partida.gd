extends Control

signal volver_solicitado

@onready var rigs: Array[Control] = [$RigIzquierdo, $RigCentral, $RigDerecho]

var posiciones_base: Array[Vector2] = []


func _ready() -> void:
	for rig in rigs:
		posiciones_base.append(rig.position)
		rig.pivot_offset = Vector2(rig.size.x * 0.5, 0.0)


func reproducir_entrada() -> Signal:
	show()
	var tween := create_tween().set_parallel()
	for indice in rigs.size():
		var rig := rigs[indice]
		rig.position.y = -rig.size.y - 100.0
		rig.rotation_degrees = -2.5 if indice % 2 == 0 else 2.5
		tween.tween_property(rig, "position:y", posiciones_base[indice].y, 0.8) \
			.set_delay(indice * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(rig, "rotation_degrees", 0.0, 0.9) \
			.set_delay(indice * 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween.finished


func reproducir_salida() -> Signal:
	var tween := create_tween().set_parallel()
	for indice in rigs.size():
		var rig := rigs[indice]
		tween.tween_property(rig, "position:y", -rig.size.y - 100.0, 0.5) \
			.set_delay(indice * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween.finished


func _on_volver_pressed() -> void:
	volver_solicitado.emit()
