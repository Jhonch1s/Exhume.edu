extends "res://scenes/escenario_base/escenario_base.gd"

var ejecutar_turnos: bool = false


func capturar_textura(_angulo: float, _jugador: String) -> ImageTexture:
	return ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))


func _inicializar_audio_ambiente() -> void:
	pass


# Cada prueba decide cuándo ejecutar turnos para que los timers no alteren su caso.
func _programar_turno_npc() -> void:
	if ejecutar_turnos:
		super._programar_turno_npc()
