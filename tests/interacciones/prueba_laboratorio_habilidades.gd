extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	var laboratorio: Node = load("res://scenes/pruebas_habilidades/LaboratorioHabilidades.tscn").instantiate()
	root.add_child(laboratorio)
	await esperar(laboratorio)
	for indice in 3:
		if laboratorio.clase != laboratorio.CLASES[indice]:
			laboratorio.cambiar_clase(indice)
			await esperar(laboratorio)
		var e: Node = laboratorio.escenario
		var f: Ficha = e.ficha_jugador
		var clase: String = laboratorio.CLASES[indice]
		comprobar(f.clase == clase and f.nivel == 2 and f.experiencia_acumulada == 100, clase + " aparece en nivel2.")
		comprobar(f.activas_aprendidas.size() == 2 and f.pasivas_aprendidas.size() == 2 and f.nivel_recompensa_pendiente == 0, clase + " tiene las cuatro recompensas simultáneas.")
		comprobar(not e.panel_progresion.visible and not e.en_combate, clase + " permite empezar sin diálogo ni combate.")
		comprobar(f.usos_ataque_doble == 1 and f.usos_ocultarse == 1 and f.usos_bola_fuego == 1, clase + " conserva el uso inicial.")
		e.abrir_progresion()
		comprobar(e.panel_progresion.visible and not laboratorio.reponer() and not "Con 2" in e.panel_progresion.detalle.text, clase + " muestra efectos correctos y bloquea recuperación durante el diálogo.")
		e.panel_progresion.hide()
		e._actualizar_estado_modal_interaccion()
		comprobar(e.tablero.obtener_interactuable(&"segundo_enemigo_nivel_dos") != null and e.tablero.obtener_interactuable(&"arena_placa_descubierta") != null and e.tablero.efectos_superficie_por_id.size() == 3, clase + " reconstruye enemigos y peligros.")
		for activa in 2:
			if f.activas_aprendidas[activa] == "paso_sombra":
				comprobar(e.hud.habilidades[2].disabled and e.hud.habilidades[2].tooltip_text.contains("OCULTO"), "Paso de sombra explica que requiere sigilo.")
				f.turnos_oculto = 2
			e._actualizar_disponibilidad_turno()
			comprobar(not e.hud.habilidades[activa + 1].disabled, clase + " permite seleccionar activa%d." % activa)
			tecla(e, KEY_2 + activa)
			comprobar(e.habilidad_en_seleccion == f.activas_aprendidas[activa] and f.usos_activas[f.activas_aprendidas[activa]] == 1, clase + " apunta la activa%d sin gastar." % activa)
			tecla(e, KEY_ESCAPE)
			comprobar(e.habilidad_en_seleccion == "", clase + " cancela apuntado.")
		tecla(e, KEY_4)
		match clase:
			"Guerrero": comprobar(e.hud.habilidades[3].disabled and e.hud.habilidades[3].text.contains("AL ACERTAR"), "Empuje se decide después de acertar y no con4.")
			"Ladrón": comprobar(e.hud.habilidades[3].disabled, "Las dos pasivas de Ladrón son automáticas.")
			"Mago": comprobar(f.contagio_elegido == "veneno", "4 selecciona Contagio arcano.")
		for id in f.activas_aprendidas:
			f.usos_activas[id] = 0
		f.usos_ataque_doble = 0
		f.usos_ocultarse = 0
		f.usos_bola_fuego = 0
		f.pv_actual = 1
		f.energia_actual = 5
		f.aplicar_o_renovar_estado(&"veneno", 1, 3, 2)
		f.pasivas_usadas_turno.append("contagio_arcano" if clase == "Mago" else f.pasivas_aprendidas[0])
		var estado := f.obtener_estado_persistente()
		comprobar(f.validar_estado_persistente(estado) == &"", clase + " valida sus cuatro recompensas en laboratorio.")
		var normal := Ficha.new()
		comprobar(normal.validar_estado_persistente(estado) != &"", clase + " no permite importar las cuatro recompensas en ficha normal.")
		normal.free()
		var guardado: StringName = e.guardar_partida()
		comprobar(guardado == &"" and e.ruta_guardado_prueba.begins_with("user://laboratorio_habilidades_"), clase + " guarda en archivo separado: " + String(guardado))
		comprobar(laboratorio.reponer(), clase + " repone sin cerrar la arena.")
		comprobar(f.pv_actual == f.pv_max and f.energia_actual == f.energia_maxima and f.usos_ataque_doble == 1 and f.usos_ocultarse == 1 and f.usos_bola_fuego == 1 and f.usos_activas.values() == [1, 1] and f.pasivas_usadas_turno.is_empty() and f.obtener_claves_estado().is_empty(), clase + " recupera vida, energía, tres activas y límites pasivos, y limpia estados.")
		var cargado: StringName = e.cargar_partida()
		comprobar(cargado == &"" and f.obtener_estado_persistente() == estado, clase + " cargar conserva gastos y las cuatro recompensas: " + String(cargado))
		comprobar(e.entrar_campamento() == &"" and not is_instance_valid(e.campamento) and f.pv_actual == f.pv_max, clase + " B repone directamente en laboratorio.")
		if "--captura" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			var imagen := root.get_texture().get_image()
			comprobar(imagen != null and imagen.save_png("res://.godot/laboratorio_%d.png" % indice) == OK, clase + " captura con render real.")
			if clase == "Ladrón":
				f.ocultarse()
				e.hud.actualizar_desde_ficha()
				await process_frame
				await RenderingServer.frame_post_draw
				comprobar(root.get_texture().get_image().save_png("res://.godot/laboratorio_oculto.png") == OK, "Captura de ficha Oculta con render real.")
	var anterior: Node = laboratorio.escenario
	laboratorio.cambiar_clase(2)
	await esperar(laboratorio)
	comprobar(not is_instance_valid(anterior) and laboratorio.escenario.ficha_jugador.activas_aprendidas.size() == 2, "Reiniciar reconstruye sin duplicar habilidades.")
	laboratorio.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Laboratorio habilidades: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func esperar(laboratorio: Node) -> void:
	for intento in 400:
		await process_frame
		if not laboratorio.reconstruyendo and is_instance_valid(laboratorio.selector_clase) and laboratorio.escenario.ficha_jugador != null and laboratorio.escenario.ficha_jugador.activas_aprendidas.size() == 2:
			return
	comprobar(false, "El laboratorio termina de prepararse.")


func tecla(e: Node, codigo: int) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	e._unhandled_input(evento)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
