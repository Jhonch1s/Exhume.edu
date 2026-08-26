extends Control

signal volver_solicitado


func _on_volver_pressed() -> void:
	volver_solicitado.emit()
