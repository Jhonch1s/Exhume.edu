extends SceneTree


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var escenario = load("res://scenes/escenario_base/escenario_base.tscn").instantiate()
	var catalogo = escenario.catalogo_mensajes
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	escenario.catalogo_mensajes = catalogo
	escenario.get_node("Zona").free()
	var zona = load("res://scenes/Prision/prision_prueba_roffa.tscn").instantiate()
	zona.name = "Zona"
	escenario.add_child(zona)
	root.add_child(escenario)
	current_scene = escenario
	for intento in 300:
		await process_frame
		if zona.prueba_preparada:
			break
	assert(zona.prueba_preparada)
	escenario.set_process(false)
	escenario._cancelar_exploracion_npc()
	assert(escenario.ficha_jugador.coordenada_mapa == Vector2i(45, -12))
	var item: ItemInstancia = escenario.ficha_jugador.inventario.obtener_por_id(&"prueba_roffa_ganzua")
	assert(item != null and item.definicion.id_definicion == &"ganzua_mecanica")
	var puerta: PuertaInteractuable = escenario.tablero.obtener_interactuable(&"interactuable_001")
	assert(puerta.bloqueada and not puerta.abierta)
	assert((item.definicion as DefinicionLlave).patron_cerradura == (puerta.definicion as DefinicionPuerta).patron_cerradura)
	assert(escenario.has_node("SecuenciaRoffa"))
	assert(zona.get_node("Interactuables/Personajes/Roffa").vida_actual > 0)
	escenario.queue_free()
	await process_frame
	print("PrisionPruebaRoffa: spawn (45, -12), ganzúa compatible, celda cerrada y secuencia preparados.")
	quit()
