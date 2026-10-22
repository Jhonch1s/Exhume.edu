extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	for nombre: String in ["Guerrero", "Ladron", "Mago"]:
		var escena := (load("res://scenes/pruebas_habilidades/PruebaNivel2%s.tscn" % nombre) as PackedScene).instantiate()
		root.add_child(escena)
		var e = escena.get_node("EscenarioBase")
		for intento in 300:
			await process_frame
			if e.panel_progresion != null and e.panel_progresion.visible:
				break
		comprobar(e.ficha_jugador != null and e.ficha_jugador.nivel == 2 and e.ficha_jugador.experiencia_acumulada == 100, nombre + " arranca en nivel2 a100XP.")
		comprobar(e.panel_progresion.visible and e.panel_progresion.opciones.size() == 4, nombre + " muestra4opciones reales.")
		comprobar(not e.en_combate, nombre + " empieza sin agro.")
		comprobar(e.tablero.obtener_interactuable(&"arena_placa_descubierta") != null, nombre + " permite probar la placa de presión.")
		var segundo := e.tablero.obtener_interactuable(&"segundo_enemigo_nivel_dos") as PersonajeNPC
		comprobar(segundo != null and segundo.obtener_definicion_personaje().movimiento_fijo == 3, nombre + " incluye un segundo enemigo móvil para Señuelo e Inercia.")
		if "--captura" in OS.get_cmdline_user_args() and nombre == "Guerrero":
			await RenderingServer.frame_post_draw
			var imagen := root.get_texture().get_image()
			comprobar(imagen != null and imagen.save_png("res://.godot/eleccion_nivel_dos.png") == OK, "Guardar captura real de elección.")
		e.panel_progresion.selector.select(0)
		e.panel_progresion._confirmar()
		await process_frame
		e._actualizar_disponibilidad_turno()
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_2
		tecla.pressed = true
		e._unhandled_input(tecla)
		comprobar(e.habilidad_en_seleccion != "" and e.ficha_jugador.usos_activas.values()[0] == 1, nombre + " activa el apuntado con2 sin gastar.")
		tecla.keycode = KEY_ESCAPE
		e._unhandled_input(tecla)
		comprobar(e.habilidad_en_seleccion == "" and e.ficha_jugador.usos_activas.values()[0] == 1, nombre + " cancela conEsc sin gasto.")
		comprobar(e.guardar_partida() == &"" and FileAccess.file_exists(e.ruta_guardado_prueba) and e.ruta_guardado_prueba.begins_with("user://prueba_nivel_dos_"), nombre + " guarda en un slot propio de pruebas.")
		escena.queue_free()
		await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Arenas nivel 2: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
