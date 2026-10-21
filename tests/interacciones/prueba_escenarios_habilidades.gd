extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	for clase in ["Ladrón", "Mago"]:
		var ruta := "res://scenes/pruebas_habilidades/Prueba%s.tscn" % ("Ladron" if clase == "Ladrón" else "Mago")
		var escena := (load(ruta) as PackedScene).instantiate()
		root.add_child(escena)
		var escenario = escena.get_node("EscenarioBase")
		for intento in 240:
			await process_frame
			if escenario.ficha_jugador != null and escenario.hud.ficha == escenario.ficha_jugador:
				break
		var ficha: Ficha = escenario.ficha_jugador
		var npc: PersonajeNPC = escenario.get_node("Zona/Interactuables/Personajes/EnemigoApartado")
		comprobar(ficha != null and ficha.clase == clase and npc != null, "%s inicia con su clase y enemigo." % clase)
		if ficha == null or npc == null:
			escena.queue_free()
			await process_frame
			continue
		comprobar(ficha.coordenada_mapa == Vector2i.ZERO and npc.coordenada_mapa == Vector2i(4, 0), "%s: enemigo visible a cuatro casillas del inicio." % clase)
		comprobar(not escenario.en_combate and not npc.puede_detectar_jugador(ficha, escenario.validador_espacial), "%s: no toma agro al cargar." % clase)
		comprobar(npc.obtener_definicion_personaje().radio_agro == 2 and npc.obtener_definicion_personaje().movimiento_fijo == 0, "%s: enemigo espera inmóvil hasta acercarse." % clase)
		var teclado := InputEventKey.new()
		teclado.keycode = KEY_1
		teclado.pressed = true
		escenario._actualizar_disponibilidad_turno()
		if clase == "Ladrón":
			var casilla := Vector2i(1, 0)
			escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
			ficha.inicializar(casilla, escenario.zona_actual.get_node("CapaSuelo"))
			escenario.tablero.ocupar_celda(casilla, ficha)
			escenario._actualizar_luz_jugador(casilla)
			comprobar(not npc.puede_detectar_jugador(ficha, escenario.validador_espacial), "Ladrón puede acercarse antes del agro.")
		else:
			comprobar(escenario.tablero.obtener_celda(npc.coordenada_mapa).visibilidad == Celda.EstadoVisibilidad.VISIBLE, "Mago ve al enemigo desde el inicio.")
		escenario._unhandled_input(teclado)
		comprobar(ficha.usos_ocultarse == 0 if clase == "Ladrón" else escenario.seleccionando_bola_fuego, "La entrada del escenario procesa la tecla 1.")
		if clase == "Ladrón":
			comprobar(ficha.turnos_oculto == 2 and ficha.usos_ocultarse == 0 and not escenario.en_combate, "Ladrón usa Ocultarse fuera de combate con 1.")
			escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
			ficha.inicializar(Vector2i(2, 0), escenario.zona_actual.get_node("CapaSuelo"))
			escenario.tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
			escenario._evaluar_agro_npc()
			comprobar(not escenario.en_combate, "Ocultarse evita el agro incluso a dos casillas.")
			ficha.romper_ocultamiento()
			escenario._evaluar_agro_npc()
			comprobar(escenario.en_combate, "El enemigo inicia combate cuando vuelve a ver al Ladrón.")
		else:
			comprobar(escenario.seleccionando_bola_fuego and not escenario.en_combate, "Mago selecciona Bola de fuego fuera de combate con 1.")
			var suelo: TileMapLayer = escenario.zona_actual.get_node("CapaSuelo")
			var punto_enemigo := suelo.to_global(suelo.map_to_local(npc.coordenada_mapa))
			escenario._actualizar_previsualizacion_bola_fuego(npc.coordenada_mapa, punto_enemigo)
			comprobar(escenario.trayectoria_lanzamiento.points.size() == 2 and escenario.capa_selector.get_cell_source_id(npc.coordenada_mapa) != -1, "El modo de apuntado dibuja trayectoria y marca la casilla enemiga.")
			comprobar(escenario._obtener_objetivo_bola_fuego(npc.coordenada_mapa, punto_enemigo) == npc, "El hechizo acepta un clic en la casilla, fuera del sprite.")
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			escenario._unhandled_input(escape)
			comprobar(not escenario.seleccionando_bola_fuego and escenario.trayectoria_lanzamiento.points.is_empty() and ficha.usos_bola_fuego == 1, "Esc cancela el apuntado sin gastar el hechizo.")
			escenario._unhandled_input(teclado)
			var vida := npc.vida_actual
			escenario._manejar_clic_izquierdo(npc.coordenada_mapa, punto_enemigo)
			comprobar(escenario.en_combate and npc.vida_actual == vida - 1 and ficha.usos_bola_fuego == 0, "Bola de fuego abre combate desde el inicio y causa daño.")
			comprobar(not escenario.seleccionando_bola_fuego and escenario.trayectoria_lanzamiento.points.is_empty(), "El apuntado se limpia después de lanzar.")
		var numpad := InputEventKey.new()
		numpad.keycode = KEY_KP_1
		numpad.pressed = true
		comprobar(escenario._activar_atajo_numerico(numpad), "La tecla 1 del teclado numérico usa la misma ranura.")
		var tecla_objeto := InputEventKey.new()
		tecla_objeto.keycode = KEY_5
		tecla_objeto.pressed = true
		comprobar(escenario._activar_atajo_numerico(tecla_objeto), "La tecla 5 apunta a la primera ranura de objetos.")
		escena.queue_free()
		await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Escenarios de habilidades: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
