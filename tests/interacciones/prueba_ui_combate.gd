extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escena: Node = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	var escenario = escena.get_node("Escenario")
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in range(200):
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	escenario.set_process(false)
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	escenario.ficha_jugador.des = 99
	if not escenario._iniciar_combate(npc, false):
		push_error("No se inició el combate de prueba.")
		quit(1)
		return
	var panel: PanelOrdenCombate = escenario.panel_orden_combate
	if not panel.visible or panel._claves_visibles.size() > 6 or panel._claves_visibles.is_empty():
		push_error("La secuencia no muestra entre uno y seis retratos.")
		quit(1)
		return
	var ronda: int = escenario.gestor_rondas.ronda_actual
	var recursos: Variant = escenario.ficha_jugador.obtener_estado_persistente()["recursos_turno"]
	escenario._on_retrato_combate_pulsado(npc.obtener_id_actor())
	if not escenario.panel_ficha_npc.visible or not escenario.interaccion_modal_activa:
		push_error("El retrato visible no abrió la ficha NPC modal.")
		quit(1)
		return
	escenario._actualizar_disponibilidad_turno()
	if not escenario.hud.pasar_turno.disabled:
		push_error("El botón de turno debe bloquearse durante la ficha NPC.")
		quit(1)
		return
	escenario.panel_ficha_npc.ocultar()
	if escenario.gestor_rondas.ronda_actual != ronda or escenario.ficha_jugador.obtener_estado_persistente()["recursos_turno"] != recursos:
		push_error("Examinar desde la tira alteró turno o reservas.")
		quit(1)
		return
	print("UICombate: seis retratos como máximo, ficha NPC modal y sin gasto de recursos.")
	quit(0)
