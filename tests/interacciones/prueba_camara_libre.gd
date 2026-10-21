extends SceneTree

var _fallos: Array[String] = []
var _casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	_probar_control_y_limites()
	await _probar_integracion()
	for fallo in _fallos:
		push_error(fallo)
	print("CamaraLibre: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _probar_control_y_limites() -> void:
	var camara := CamaraEscenario.new()
	root.add_child(camara)
	camara.zoom = Vector2(2, 2)
	camara.limites = Rect2(-1000, -1000, 2000, 2000)
	var vista := Vector2(800, 600)
	var centro := vista / 2.0
	_comprobar(camara.direccion_borde(Vector2(0, 300), vista) == Vector2.LEFT, "Borde izquierdo.")
	_comprobar(camara.direccion_borde(Vector2(799, 300), vista) == Vector2.RIGHT, "Borde derecho.")
	_comprobar(camara.direccion_borde(Vector2(400, 0), vista) == Vector2.UP, "Borde superior.")
	_comprobar(camara.direccion_borde(Vector2(400, 599), vista) == Vector2.DOWN, "Borde inferior.")
	_comprobar(is_equal_approx(camara.direccion_borde(Vector2.ZERO, vista).length(), 1.0), "La diagonal no acelera la cámara.")
	_comprobar(camara.direccion_borde(Vector2(-1, 300), vista) == Vector2.ZERO, "Fuera de ventana no desplaza.")
	_comprobar(camara.direccion_borde(centro, vista) == Vector2.ZERO, "El interior no desplaza.")
	camara.actualizar(0.1, Vector2.ZERO, vista, centro, true)
	camara.actualizar(0.1, Vector2.ZERO, vista, Vector2(799, 300), true)
	_comprobar(camara.libre and camara.desplazando and camara.position.x > 0, "El borde entra en cámara libre.")
	var posicion := camara.position
	camara.actualizar(0.1, Vector2(300, 0), vista, centro, true)
	_comprobar(camara.position == posicion, "Soltar el borde mantiene la vista aunque se mueva la ficha.")
	camara.actualizar(0.1, Vector2.ZERO, vista, Vector2(799, 300), false)
	_comprobar(camara.position == posicion and not camara.desplazando, "El bloqueo suspende la cámara.")
	camara.actualizar(0.1, Vector2.ZERO, vista, Vector2(799, 300), true)
	_comprobar(camara.position == posicion, "Cerrar un modal no reanuda el borde sin salir de él.")
	camara.centrar(Vector2.ZERO)
	_comprobar(not camara.libre and not camara.desplazando, "Centrar restaura seguimiento.")
	camara.actualizar(0.1, Vector2(50, 60), vista, centro, true)
	_comprobar(camara.position == Vector2(50, 60), "El seguimiento acompaña a la ficha.")
	camara.actualizar(0.1, Vector2(80, 60), vista, centro, false)
	_comprobar(camara.position == Vector2(80, 60), "Pasar sobre HUD no detiene el seguimiento de un recorrido.")
	camara.actualizar(0.1, Vector2(90, 60), vista, centro, false, true)
	_comprobar(camara.position == Vector2(80, 60), "El modal sí suspende también el seguimiento.")
	_comprobar(camara.limitar_posicion(Vector2(5000, -5000), vista) == Vector2(800, -850), "Limitar encuadre usando semivista y zoom.")
	_comprobar(camara.limitar_posicion(Vector2(5000, -5000), Vector2(1200, 800)) == Vector2(700, -800), "Cambiar ventana reajusta límites.")
	camara.limites = Rect2(-50, -40, 100, 80)
	_comprobar(camara.limitar_posicion(Vector2(5000, 5000), vista) == Vector2.ZERO, "Mapa menor que ventana queda centrado sin límites invertidos.")
	camara.limites = Rect2(-1000, -1000, 2000, 2000)
	camara.zoom = Vector2(3, 3)
	camara.centrar(Vector2(100, 0))
	camara.cambiar_zoom(1.0, Vector2(100, 0))
	_comprobar(is_equal_approx(camara.zoom.x, 3.6) and camara.position == Vector2(100, 0) and not camara.libre, "Acercar conserva seguimiento y centro de ficha.")
	camara.cambiar_zoom(100.0, Vector2(100, 0))
	_comprobar(is_equal_approx(camara.zoom.x, CamaraEscenario.ZOOM_MAXIMO), "El zoom tiene máximo.")
	camara.cambiar_zoom(-100.0, Vector2(100, 0))
	_comprobar(is_equal_approx(camara.zoom.x, CamaraEscenario.ZOOM_MINIMO), "El zoom tiene mínimo.")
	camara.libre = true
	camara.position = Vector2(200, 0)
	camara.cambiar_zoom(1.0, Vector2.ZERO)
	_comprobar(camara.libre and camara.position == Vector2(200, 0), "Zoom en cámara libre conserva el encuadre.")
	var escala_libre := camara.zoom.x
	camara.centrar(Vector2(100, 0))
	_comprobar(is_equal_approx(camara.zoom.x, escala_libre), "Espacio no reinicia el zoom.")
	camara.free()


func _probar_integracion() -> void:
	var escena: Node = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	var escenario = escena.get_node("Escenario")
	escenario.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	escenario.set_process(false)
	if escena.get("_enemigos").size() != 5:
		_comprobar(false, "Debe iniciar el fixture de facciones.")
		escena.queue_free()
		return
	var camara: CamaraEscenario = escenario.camera_2d
	var ficha: Ficha = escenario.ficha_jugador
	_comprobar(camara.limites.has_area(), "Los límites proceden del contenido real de zona.")
	var snapshot: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, &"zona1", ficha, escenario.registro_conocimiento)
	var revision: int = escenario.gestor_vision.revision_vision
	var vista := Vector2(1920, 1080)
	camara.actualizar(0.1, ficha.global_position, vista, vista / 2.0, true)
	camara.actualizar(0.1, ficha.global_position, vista, Vector2(1919, 540), true)
	_comprobar(camara.libre, "Exploración permite cámara libre.")
	var despues: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, &"zona1", ficha, escenario.registro_conocimiento)
	_comprobar(snapshot == despues and escenario.gestor_vision.revision_vision == revision, "Pan no cambia guardado, recursos, conocimiento, ocupación ni FOV.")
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_UP
	rueda.pressed = true
	rueda.position = vista / 2.0
	var zoom_anterior := camara.zoom.x
	escenario._unhandled_input(rueda)
	_comprobar(camara.zoom.x > zoom_anterior and camara.libre, "Rueda acerca sin salir de cámara libre.")
	var despues_zoom: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, &"zona1", ficha, escenario.registro_conocimiento)
	_comprobar(despues_zoom == despues and escenario.gestor_vision.revision_vision == revision, "Zoom no cambia guardado, recursos ni FOV.")
	rueda.button_index = MOUSE_BUTTON_WHEEL_DOWN
	escenario._unhandled_input(rueda)
	_comprobar(is_equal_approx(camara.zoom.x, zoom_anterior), "Rueda aleja al valor anterior.")
	var item := ItemInstancia.new(&"camara_piedra", load("res://assets/items/piedra/piedra.tres"), 1)
	escenario.item_lanzamiento_pendiente = item
	escenario._input(_espacio())
	_comprobar(escenario.item_lanzamiento_pendiente == item and not camara.libre, "Recentrar conserva selección de lanzamiento.")
	escenario.item_lanzamiento_pendiente = null
	camara.libre = true
	_comprobar(escenario.guardar_partida("user://prueba_camara.json") == &"", "Guardar en cámara libre conserva el contrato.")
	_comprobar(escenario.cargar_partida("user://prueba_camara.json") == &"" and not camara.libre, "Cargar recupera partida y seguimiento sin persistir cámara.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prueba_camara.json"))
	camara.libre = true
	for panel in [escenario.menu_contextual, escenario.panel_resultado_accion, escenario.panel_examen_ilustrado, escenario.panel_ficha_npc, escenario.panel_inventario_cofre]:
		panel.show()
		escenario._actualizar_estado_modal_interaccion()
		_comprobar(escenario._camara_bloqueada(), "Panel %s bloquea cámara." % panel.name)
		var posicion := camara.position
		var escala := camara.zoom.x
		escenario._unhandled_input(rueda)
		_comprobar(is_equal_approx(camara.zoom.x, escala), "Panel %s bloquea zoom." % panel.name)
		escenario._input(_espacio())
		_comprobar(camara.libre and camara.position == posicion, "Espacio cede al modal %s." % panel.name)
		panel.hide()
		escenario._actualizar_estado_modal_interaccion()
	escenario.lanzamiento_en_vuelo = true
	escenario._actualizar_estado_modal_interaccion()
	_comprobar(escenario._camara_bloqueada(), "El vuelo bloquea cámara.")
	escenario.lanzamiento_en_vuelo = false
	escenario._actualizar_estado_modal_interaccion()
	var dialogo := DialogueResource.new()
	DialogueManager.dialogue_started.emit(dialogo)
	_comprobar(escenario._camara_bloqueada(), "También bloquea el diálogo iniciado fuera del menú NPC.")
	escenario._input(_espacio())
	_comprobar(camara.libre, "Espacio no recentra durante diálogo.")
	DialogueManager.dialogue_ended.emit(dialogo)
	_comprobar(not escenario._camara_bloqueada(), "Finalizar diálogo libera navegación.")
	# Comprobar el evento real con el botón de pasar turno enfocado.
	escenario.hud.pasar_turno.grab_focus()
	var recursos: Dictionary = ficha.obtener_estado_persistente()["recursos_turno"].duplicate(true)
	root.push_input(_espacio())
	_comprobar(not camara.libre, "Espacio recentra antes de llegar al botón enfocado.")
	_comprobar(ficha.obtener_estado_persistente()["recursos_turno"] == recursos, "Espacio no pasa turno desde el foco residual del HUD.")
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	ficha.des = 99
	_comprobar(escenario._iniciar_combate(npc, false), "Iniciar combate de integración.")
	var gestor: GestorRondas = escenario.gestor_rondas
	var participantes: Array[Object] = [ficha, npc]
	# Mantener sólo dos actores para probar la transición de vuelta al jugador.
	gestor = GestorRondas.new(escenario.servicio_turnos, escenario.procesador_superficies)
	gestor.iniciar(participantes)
	escenario.gestor_rondas = gestor
	escenario._actor_turno_camara = null
	escenario._actualizar_ui_combate()
	camara.libre = true
	camara.position += Vector2(30, 0)
	var posicion_libre := camara.position
	escenario._actualizar_ui_combate()
	_comprobar(camara.libre and camara.position == posicion_libre, "Refrescar HUD durante tu turno no recentra cada frame.")
	gestor.finalizar_turno_activo()
	escenario._actualizar_ui_combate()
	_comprobar(gestor.actor_activo == npc and camara.libre, "Turno NPC conserva encuadre libre.")
	var coord := ficha.coordenada_mapa
	escenario._manejar_clic_derecho(npc.coordenada_mapa)
	escenario._manejar_clic_izquierdo(npc.coordenada_mapa)
	escenario._on_pasar_turno_hud()
	_comprobar(gestor.actor_activo == npc and ficha.coordenada_mapa == coord and not ficha.esta_moviendose and not escenario.menu_contextual.visible, "Cámara libre no permite órdenes durante turno NPC.")
	escenario._input(_espacio())
	_comprobar(not camara.libre and gestor.actor_activo == npc, "Espacio funciona durante turno ajeno sin cambiarlo.")
	camara.libre = true
	gestor.finalizar_turno_activo()
	escenario._actualizar_ui_combate()
	_comprobar(gestor.actor_activo == ficha and not camara.libre, "Comenzar tu turno recentra automáticamente.")
	_comprobar(camara.position.is_equal_approx(camara.limitar_posicion(ficha.global_position, escenario.get_viewport_rect().size)), "Recentrado automático respeta límites.")
	camara.libre = true
	escenario._actualizar_camara(0)
	_comprobar(escenario.estado_camara.text.contains("Tu turno") and escenario.estado_camara.text.contains("Cámara libre"), "Indicador fijo conserva modo y turno.")
	var celda_npc: Celda = escenario.tablero.obtener_celda(npc.coordenada_mapa)
	celda_npc.visibilidad = Celda.EstadoVisibilidad.EXPLORADO
	gestor.finalizar_turno_activo()
	escenario._actualizar_ui_combate()
	escenario._actualizar_camara(0)
	_comprobar(escenario.estado_camara.text.contains("oculto") and not escenario.estado_camara.text.contains(npc.obtener_nombre_interaccion()), "El indicador no revela identidad del actor oculto.")
	escenario.panel_resultado_accion.show()
	escenario._actualizar_estado_modal_interaccion()
	camara.libre = true
	gestor.finalizar_turno_activo()
	escenario._actualizar_ui_combate()
	_comprobar(camara.libre and escenario._centrado_camara_pendiente, "Un modal difiere el recentrado del turno propio.")
	escenario.panel_resultado_accion.hide()
	escenario._actualizar_estado_modal_interaccion()
	escenario._actualizar_camara(0)
	_comprobar(not camara.libre and not escenario._centrado_camara_pendiente, "Cerrar el modal completa el recentrado pendiente.")
	escena.queue_free()
	await process_frame


func _espacio() -> InputEventKey:
	var evento := InputEventKey.new()
	evento.keycode = KEY_SPACE
	evento.pressed = true
	return evento


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
