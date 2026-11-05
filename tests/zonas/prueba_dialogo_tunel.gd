extends SceneTree


func _init() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	EstadoPartida.establecer_aventurero({"nombre": "Prueba", "titulo": "Probador", "clase": "Guerrero", "origen": "Prueba", "fuerza": 4, "destreza": 4, "voluntad": 4})
	var escenario := (load("res://scenes/escenario_base/escenario_base.tscn") as PackedScene).instantiate()
	var retratos := [escenario.ilustracion_dialogo_guerrero, escenario.ilustracion_dialogo_ladron, escenario.ilustracion_dialogo_mago]
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.ilustracion_dialogo_guerrero = retratos[0]
	escenario.ilustracion_dialogo_ladron = retratos[1]
	escenario.ilustracion_dialogo_mago = retratos[2]
	escenario.get_node("Zona").free()
	var zona := (load("res://scenes/templo_de_las_trampas/TemploDeLasTrampas.tscn") as PackedScene).instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	for intento in range(250):
		await process_frame
		if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
			break
	if escenario.ficha_jugador == null:
		push_error("No se inicializó el jugador.")
		quit(1)
		return
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	var trigger: TriggerMapa = zona.get_node("Triggers/Dialogos/TriggerMapa")
	var fallos := 0
	if not trigger.validar_configuracion(zona.get_node("CapaSuelo"), escenario.tablero).is_empty():
		fallos += 1
	var clases := ["Guerrero", "Ladrón", "Mago"]
	for indice in range(clases.size()):
		escenario.ficha_jugador.clase = clases[indice]
		if trigger.accion.ejecutar(escenario, trigger) != &"":
			fallos += 1
			continue
		await create_timer(0.1).timeout
		var globo: Node = escenario.gestor_triggers._globo_activo
		if not is_instance_valid(globo) or globo.dialogue_line == null or not globo.dialogue_line.text.contains("Esto no pinta nada bien") or not globo.ilustracion_jugador.visible or globo.ilustracion_jugador.texture != retratos[indice] or retratos[indice] == null or globo.ilustracion_npc.visible:
			push_error("Texto o ilustración incorrectos para " + clases[indice])
			fallos += 1
		escenario.gestor_triggers.limpiar()
		await process_frame
	escenario.queue_free()
	await process_frame
	print("DialogoTunel: %d fallos, tres clases verificadas." % fallos)
	quit(0 if fallos == 0 else 1)
