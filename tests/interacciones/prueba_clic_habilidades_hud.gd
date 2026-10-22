extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var laboratorio: Node = load("res://scenes/pruebas_habilidades/LaboratorioHabilidades.tscn").instantiate()
	laboratorio.clase = "Mago"
	root.add_child(laboratorio)
	await esperar(laboratorio)
	for clase in 3:
		laboratorio.cambiar_clase(clase)
		await esperar(laboratorio)
		var e: Node = laboratorio.escenario
		var f: Ficha = e.ficha_jugador
		var posicion := f.coordenada_mapa
		if f.clase == "Guerrero":
			var npc: PersonajeNPC = e.tablero.obtener_interactuable(&"segundo_enemigo_nivel_dos")
			e.tablero.reubicar_interactuable(npc, posicion + Vector2i.RIGHT)
			npc.actualizar_posicion_visual()
			e._iniciar_combate(npc, false)
			var estado: Dictionary = e.gestor_rondas.obtener_estado_persistente()
			estado["actor_activo_id"] = String(f.id_actor)
			e.gestor_rondas.restaurar_estado_persistente(estado)
			f.iniciar_turno()
		e._actualizar_disponibilidad_turno()
		await clic(e.hud.habilidades[0])
		match f.clase:
			"Guerrero": comprobar(e.seleccionando_ataque_doble, "Clic activa Ataque doble.")
			"Mago": comprobar(e.seleccionando_bola_fuego, "Clic activa Bola de fuego.")
			"Ladrón": comprobar(f.turnos_oculto > 0 and f.usos_ocultarse == 0, "Clic usa Ocultarse una sola vez.")
		e.seleccionando_ataque_doble = false
		e._cancelar_bola_fuego()
		f.iniciar_turno()
		for indice in 2:
			var boton: Button = e.hud.habilidades[indice + 1]
			comprobar(not boton.disabled, f.clase + " tiene activa%d disponible." % indice)
			await clic(boton)
			comprobar(e.habilidad_en_seleccion == f.activas_aprendidas[indice], "Clic selecciona " + f.activas_aprendidas[indice])
			comprobar(f.usos_activas[f.activas_aprendidas[indice]] == 1 and f.coordenada_mapa == posicion, "Clic en HUD no gasta el uso ni mueve la ficha en el mapa.")
			e._cancelar_habilidad_nueva()
		if f.clase == "Mago":
			await clic(e.hud.habilidades[3])
			comprobar(f.contagio_elegido == "veneno", "Clic cambia la pasiva Contagio.")
		f.usos_activas[f.activas_aprendidas[1]] = 0
		e._actualizar_disponibilidad_turno()
		await clic(e.hud.habilidades[2])
		comprobar(e.habilidad_en_seleccion == "", "Un clic en una activa agotada no inicia apuntado.")
	laboratorio.queue_free()
	await process_frame
	# También probar la recompensa única del juego normal, sin los callbacks del laboratorio.
	for opcion in [0, 3]:
		var escena: Node = load("res://scenes/pruebas_habilidades/PruebaNivel2Mago.tscn").instantiate()
		root.add_child(escena)
		var e: Node = escena.get_node("EscenarioBase")
		for intento in 400:
			await process_frame
			if e.panel_progresion != null and e.panel_progresion.visible:
				break
		e.panel_progresion.selector.select(opcion)
		e.panel_progresion._confirmar()
		await process_frame
		await clic(e.hud.habilidades[1])
		comprobar(e.habilidad_en_seleccion == "transposicion" if opcion == 0 else e.ficha_jugador.contagio_elegido == "veneno", "Clic funciona con recompensa única, activa o pasiva configurable.")
		escena.queue_free()
		await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Clic habilidades HUD: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func clic(boton: Button) -> void:
	var punto := boton.get_global_rect().get_center()
	var movimiento := InputEventMouseMotion.new()
	movimiento.position = punto
	movimiento.global_position = punto
	root.push_input(movimiento, true)
	await process_frame
	comprobar(root.gui_get_hovered_control() == boton, "El ratón alcanza la ranura visible del HUD.")
	for presionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.position = punto
		evento.global_position = punto
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.button_mask = MOUSE_BUTTON_MASK_LEFT if presionado else 0
		evento.pressed = presionado
		root.push_input(evento, true)
		await process_frame
		if presionado:
			await create_timer(0.08).timeout


func esperar(laboratorio: Node) -> void:
	for intento in 400:
		await process_frame
		if not laboratorio.reconstruyendo and is_instance_valid(laboratorio.selector_clase) and laboratorio.escenario.ficha_jugador.activas_aprendidas.size() == 2:
			return
	comprobar(false, "El laboratorio termina de prepararse.")


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
