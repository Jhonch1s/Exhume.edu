extends Node


func _ready() -> void:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	add_child(escenario)
	for intento in 600:
		await get_tree().process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	if escenario.ficha_jugador == null or escenario.hud.ficha != escenario.ficha_jugador:
		push_error("No se pudo preparar la prueba manual de campamento.")
		return
	escenario.ficha_jugador.pv_actual = maxi(1, escenario.ficha_jugador.pv_max - 4)
	escenario.ficha_jugador.energia_actual = 50
	escenario.hud.actualizar_desde_ficha()
	escenario.entrar_campamento()
	# Captura opcional para revisar la composición real renderizada por Godot.
	if "--capturar" in OS.get_cmdline_user_args():
		for intento in 600:
			await get_tree().process_frame
			if is_instance_valid(escenario.campamento.escenario_descanso) and escenario.campamento.escenario_descanso.hud.ficha != null:
				break
		for frame in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/campamento_preview.png")
		get_tree().quit()
