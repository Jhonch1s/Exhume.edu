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
		comprobar(e.get_node("FiltroCRT").visible and e.get_node("FiltroCRT").layer > e.panel_progresion.get_parent().layer and laboratorio.capa_ayuda.layer < e.panel_progresion.get_parent().layer, "CRT cubre el panel y la ayuda queda detrás para " + f.clase)
		var icono_inicial := e.hud.habilidades[0].get_node("IconoHabilidad") as TextureRect
		comprobar(icono_inicial.position == Vector2.ZERO and icono_inicial.size == e.hud.habilidades[0].size, "El icono ocupa toda la ranura de " + f.clase)
		var inicial: String = {"Guerrero": "ataque_doble", "Ladrón": "ocultarse", "Mago": "bola_de_fuego"}[f.clase]
		comprobar((e.hud.habilidades[0].get_node("IconoHabilidad") as TextureRect).texture == CatalogoHabilidades.icono(inicial), "La ranura inicial muestra el icono de " + f.clase)
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
			comprobar((boton.get_node("IconoHabilidad") as TextureRect).texture == CatalogoHabilidades.icono(f.activas_aprendidas[indice]), "La ranura muestra el icono de " + f.activas_aprendidas[indice])
			comprobar(not boton.disabled, f.clase + " tiene activa%d disponible." % indice)
			await clic(boton)
			comprobar(e.habilidad_en_seleccion == f.activas_aprendidas[indice], "Clic selecciona " + f.activas_aprendidas[indice])
			comprobar(f.usos_activas[f.activas_aprendidas[indice]] == 1 and f.coordenada_mapa == posicion, "Clic en HUD no gasta el uso ni mueve la ficha en el mapa.")
			e._cancelar_habilidad_nueva()
		if f.clase == "Mago":
			await clic(e.hud.habilidades[3])
			comprobar(f.contagio_elegido == "veneno", "Clic cambia la pasiva Contagio.")
			e._actualizar_disponibilidad_turno()
			comprobar((e.hud.habilidades[3].get_node("IconoHabilidad") as TextureRect).texture == CatalogoHabilidades.icono("contagio_arcano") and (e.hud.habilidades[3].get_node("EstadoHabilidad") as Label).text == "VENENO", "Contagio muestra icono y modo elegido.")
		f.usos_activas[f.activas_aprendidas[1]] = 0
		e._actualizar_disponibilidad_turno()
		comprobar((e.hud.habilidades[2].get_node("EstadoHabilidad") as Label).text == "0/1", "La ranura muestra el uso agotado.")
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
		comprobar(e.get_node("FiltroCRT").visible and e.get_node("FiltroCRT").layer > e.panel_progresion.get_parent().layer, "El panel de la arena queda bajo el CRT activo.")
		comprobar(e.hud.indicador_progresion.visible, "La recompensa pendiente se indica junto al retrato.")
		comprobar(e.panel_progresion.selector.get_selected_items().is_empty() and e.panel_progresion.boton_aprender.disabled, "El panel espera una selección explícita.")
		if opcion == 0:
			if "--captura" in OS.get_cmdline_user_args() and is_instance_valid(e.presentacion_zona) and e.presentacion_zona.visible:
				await e.presentacion_zona.finalizada
			await clic(e.panel_progresion.boton_cerrar)
			comprobar(not e.panel_progresion.visible and e.ficha_jugador.nivel_recompensa_pendiente == 2 and e.hud.indicador_progresion.visible, "Elegir después conserva la recompensa y su indicador.")
			if "--captura" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				comprobar(root.get_texture().get_image().save_png("res://.godot/indicador_progresion.png") == OK, "Captura del indicador junto al retrato.")
			e._acciones_en_resolucion = 1
			await process_frame
			await clic(e.hud.indicador_progresion)
			comprobar(not e.panel_progresion.visible and e.hud.indicador_progresion.tooltip_text.contains("termine"), "La flecha explica el bloqueo durante una acción.")
			e._acciones_en_resolucion = 0
			await process_frame
			await clic(e.hud.indicador_progresion)
			comprobar(e.panel_progresion.visible, "La flecha abre la elección pendiente.")
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			root.push_input(escape, true)
			await process_frame
			comprobar(not e.panel_progresion.visible and e.ficha_jugador.nivel_recompensa_pendiente == 2, "Esc cierra y conserva la recompensa pendiente.")
			comprobar(e.abrir_progresion() == &"" and e.panel_progresion.visible, "La elección se puede retomar tras Esc.")
			var abajo := InputEventAction.new()
			abajo.action = &"ui_down"
			abajo.pressed = true
			root.push_input(abajo, true)
			await process_frame
			comprobar(not e.panel_progresion.selector.get_selected_items().is_empty() and not e.panel_progresion.boton_aprender.disabled, "El teclado permite seleccionar una recompensa.")
		await clic_opcion(e.panel_progresion.selector, opcion)
		comprobar(not e.panel_progresion.boton_aprender.disabled and e.panel_progresion.nombre_opcion.text == e.panel_progresion.opciones[opcion]["nombre"], "El clic muestra el detalle y habilita la confirmación.")
		if "--captura" in OS.get_cmdline_user_args() and opcion == 0:
			if is_instance_valid(e.presentacion_zona) and e.presentacion_zona.visible:
				await e.presentacion_zona.finalizada
			await RenderingServer.frame_post_draw
			comprobar(root.get_texture().get_image().save_png("res://.godot/panel_progresion_seleccion.png") == OK, "Captura del panel con selección.")
		if opcion == 3:
			e.ficha_jugador.nivel_recompensa_pendiente = 0
			await clic(e.panel_progresion.boton_aprender)
			comprobar(e.panel_progresion.visible and e.panel_progresion.error.visible and not e.panel_progresion.boton_aprender.disabled, "Un rechazo mantiene el panel abierto e informa al jugador.")
			e.ficha_jugador.nivel_recompensa_pendiente = 2
		await clic(e.panel_progresion.boton_aprender)
		await process_frame
		comprobar(not e.hud.indicador_progresion.visible, "El indicador se oculta al aprender.")
		await clic(e.hud.habilidades[1])
		comprobar(e.habilidad_en_seleccion == "transposicion" if opcion == 0 else e.ficha_jugador.contagio_elegido == "veneno", "Clic funciona con recompensa única, activa o pasiva configurable.")
		escena.queue_free()
		await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Clic habilidades HUD: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func clic(boton: Button) -> void:
	await process_frame
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


func clic_opcion(selector: ItemList, indice: int) -> void:
	await process_frame
	var rect := selector.get_item_rect(indice)
	var punto := selector.get_global_transform_with_canvas() * rect.get_center()
	var movimiento := InputEventMouseMotion.new()
	movimiento.position = punto
	movimiento.global_position = punto
	root.push_input(movimiento, true)
	await process_frame
	comprobar(root.gui_get_hovered_control() == selector, "El ratón alcanza la lista del panel.")
	for presionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.position = punto
		evento.global_position = punto
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.button_mask = MOUSE_BUTTON_MASK_LEFT if presionado else 0
		evento.pressed = presionado
		root.push_input(evento, true)
		await process_frame


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
