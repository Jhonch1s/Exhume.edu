extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var zona := load("res://scenes/Zona1/zona_1.tscn") as PackedScene
	var instancia := zona.instantiate()
	root.add_child(instancia)
	var antorcha := instancia.get_node("Interactuables/FuentesLuz/AntorchaPie_02_01") as FuenteLuzInteractuable
	var motas := antorcha.get_node("MotasPolvo") as CPUParticles2D
	assert(motas != null and motas.z_index == -1 and motas.amount == 12)
	antorcha.actualizar_presentacion_visibilidad(Celda.EstadoVisibilidad.OCULTO)
	assert(not motas.visible)
	antorcha.actualizar_presentacion_visibilidad(Celda.EstadoVisibilidad.EXPLORADO)
	assert(not motas.visible)
	antorcha.actualizar_presentacion_visibilidad(Celda.EstadoVisibilidad.VISIBLE)
	assert(motas.visible and motas.emitting)
	antorcha.encendida = false
	assert(not motas.emitting and not motas.visible)
	antorcha.encendida = true
	assert(motas.emitting and motas.visible)
	antorcha.restaurar_estado_persistente({"encendida": false})
	assert(not motas.emitting and not motas.visible)
	instancia.queue_free()
	await process_frame
	await _probar_mapa()
	await _probar_templo()
	await _probar_templo_f6()
	if "--captura" in OS.get_cmdline_user_args():
		await _capturar()
	print("Motas de polvo: visibilidad, encendido y restauración correctos.")
	quit()


func _probar_mapa() -> void:
	var escena: Variant = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	root.add_child(escena)
	var escenario: Variant = escena.get_node("Escenario")
	for intento in 300:
		await process_frame
		if escena.get("_enemigos").size() == 5:
			break
	assert(escena.get("_enemigos").size() == 5 and escenario.ficha_jugador != null)
	var polvo: Variant = escenario.zona_actual.get_node("PolvoAmbiental")
	await process_frame
	assert(polvo._emisores.size() > 0)
	for coord in polvo._emisores:
		assert(coord in escenario.gestor_vision.celdas_visibles_actuales)
		assert(escenario.tablero.datos[coord].caminable)
		assert(escenario.gestor_vision.iluminacion_actual[coord] != FOVManager.NivelLuz.OSCURIDAD)
	escenario.gestor_vision.celdas_visibles_actuales.clear()
	escenario.gestor_vision.revision_vision += 1
	await process_frame
	assert(polvo._emisores.is_empty())
	escena.queue_free()
	await process_frame


func _probar_templo() -> void:
	var escenario: Variant = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.get_node("Zona").free()
	var templo: Node2D = load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn").instantiate()
	templo.name = "Zona"
	escenario.add_child(templo)
	root.add_child(escenario)
	for intento in 200:
		await process_frame
		if escenario.ficha_jugador != null and escenario.gestor_vision.tiene_vision_calculada:
			break
	assert(escenario.ficha_jugador != null)
	var polvo: Variant = templo.get_node("PolvoAmbiental")
	await process_frame
	if polvo.get_script() == null or polvo._revision != escenario.gestor_vision.revision_vision or polvo._emisores.size() < 5:
		push_error("El templo no actualizó suficientes emisores de polvo sobre celdas visibles.")
		quit(1)
		return
	for coord in polvo._emisores:
		assert(coord in escenario.gestor_vision.celdas_visibles_actuales)
	if "--captura-templo" in OS.get_cmdline_user_args():
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
		polvo.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/motas_templo_antes.png")
		polvo.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/motas_templo_despues.png")
	escenario.queue_free()
	await process_frame


func _probar_templo_f6() -> void:
	change_scene_to_file("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn")
	await scene_changed
	var escenario: Variant
	for intento in 600:
		await process_frame
		escenario = current_scene
		if escenario != null and escenario.has_node("GestorVision"):
			var polvo: Variant = escenario.get_node("Zona/PolvoAmbiental")
			if not polvo._emisores.is_empty():
				print("Templo iniciado con F6: ", polvo._emisores.size(), " emisores de polvo activos.")
				if "--captura-templo" in OS.get_cmdline_user_args():
					await process_frame
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.godot/motas_templo_f6.png")
				escenario.queue_free()
				await process_frame
				return
	push_error("El arranque individual del templo no activó el polvo ambiental.")
	quit(1)


func _capturar() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var escena: Variant = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	root.add_child(escena)
	var escenario: Variant = escena.get_node("Escenario")
	for intento in 300:
		await process_frame
		if escena.get("_enemigos").size() == 5:
			break
	assert(escena.get("_enemigos").size() == 5 and escenario.ficha_jugador != null)
	escenario.set_process(false)
	var antorcha := escenario.zona_actual.get_node("Interactuables/FuentesLuz/AntorchaPie_02_01") as FuenteLuzInteractuable
	var polvo_ambiental: Node2D = escenario.zona_actual.get_node("PolvoAmbiental")
	polvo_ambiental.hide()
	var motas := antorcha.get_node("MotasPolvo") as CPUParticles2D
	motas.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/motas_polvo_antes.png") == OK)
	polvo_ambiental.show()
	motas.show()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/motas_polvo_cueva.png") == OK)
	escena.queue_free()
	await process_frame
