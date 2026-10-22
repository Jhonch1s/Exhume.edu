extends "res://scenes/ficha/ficha.gd"


func _validar_progresion_guardada(estado: Dictionary, _limite_recompensas: int = 1) -> StringName:
	# Solo esta ficha de laboratorio admite las cuatro recompensas de su clase.
	return super._validar_progresion_guardada(estado, 4)
