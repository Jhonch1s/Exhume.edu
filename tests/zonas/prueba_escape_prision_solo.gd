extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var catalogo = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	escenario.get_node("Zona").free()
	var zona = load("res://scenes/Prision/prision.tscn").instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	current_scene = escenario
	for intento in 300:
		await process_frame
		if escenario.escenario_preparado:
			break
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var salida: TriggerMapa = zona.get_node("Triggers/Mecanismos/escape_prision")
	var controlador = escenario.get_node("SecuenciaRoffa")
	await salida.accion.ejecutar(escenario, salida)
	await process_frame
	assert(current_scene == escenario)
	controlador.peeble.vida_actual = 0
	await salida.accion.ejecutar(escenario, salida)
	await process_frame
	assert(current_scene == escenario)
	controlador.rengo.vida_actual = 0
	await salida.accion.ejecutar(escenario, salida)
	for intento in 100:
		await process_frame
		if current_scene != null and current_scene != escenario:
			break
	assert(current_scene != null and current_scene != escenario and current_scene.scene_file_path.ends_with("fin_demo.tscn"))
	print("EscapePrisionSolo: exige los dos guardias derrotados y muestra el final.")
	quit()
