extends Node

const PRUEBA_AUTONOMA := preload("res://tests/interacciones/prueba_exploracion_npc_autonoma.gd")


func _ready() -> void:
	call_deferred("_comprobar")


func _comprobar() -> void:
	var escena := load("res://tests/interacciones/escena_npc_hostil.tscn").instantiate() as Node2D
	escena.set("radio_vision_enemigos", 0)
	var escenario := escena.get_node("Escenario")
	escenario.set_script(PRUEBA_AUTONOMA.EscenarioSinRender)
	add_child(escena)
	var tablero := escenario.get("tablero") as TableroGrid
	var npcs: Array[PersonajeNPC] = []
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		var primero := tablero.obtener_interactuable(&"npc_hostil_prueba_001") as PersonajeNPC
		var segundo := tablero.obtener_interactuable(&"npc_hostil_prueba_002") as PersonajeNPC
		if primero != null and segundo != null:
			npcs.assign([primero, segundo])
			break
	if npcs.size() != 2:
		push_error("No se pudieron preparar las dos patrullas.")
		get_tree().quit(1)
		return
	var indices: Array[int] = []
	var vueltas: Array[int] = [0, 0]
	for npc in npcs:
		if not npc.obtener_patrulla().esta_configurada():
			push_error("Ruta no configurada: %s" % npc.id_instancia)
			get_tree().quit(1)
			return
		indices.append(int(npc.obtener_patrulla().obtener_estado_persistente()["indice_siguiente"]))
		print("Ruta de %s: %s" % [npc.id_instancia, npc.obtener_patrulla().obtener_estado_persistente()])
	for instante in range(400):
		await get_tree().create_timer(0.1).timeout
		for numero in range(npcs.size()):
			var estado := npcs[numero].obtener_patrulla().obtener_estado_persistente()
			var indice: int = estado["indice_siguiente"]
			if indice < indices[numero]:
				vueltas[numero] += 1
			indices[numero] = indice
		if instante % 20 == 19:
			for numero in range(npcs.size()):
				var npc := npcs[numero]
				print("Patrulla t=%d %s celda=%s PV=%d movimiento=%d indice=%d espera=%s moviendose=%s estados=%s vueltas=%d" % [
					(instante + 1) / 10, npc.id_instancia, npc.coordenada_mapa,
					npc.estado_personaje.vida_actual, npc.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO),
					indices[numero], npc.obtener_patrulla().esta_esperando(), npc.esta_moviendose,
					npc.obtener_claves_estado(), vueltas[numero],
				])
	var correcto := vueltas[0] >= 2 and vueltas[1] >= 2
	escenario.set_process(false)
	escenario.call("_cancelar_exploracion_npc")
	await get_tree().create_timer(0.7).timeout
	escena.queue_free()
	await get_tree().process_frame
	if correcto:
		print("ContinuidadPatrullas: ambas completaron al menos dos circuitos: %s." % [vueltas])
	else:
		push_error("Las patrullas dejaron de completar circuitos: %s." % [vueltas])
	get_tree().quit(0 if correcto else 1)
