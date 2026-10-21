extends SceneTree

var fallos: Array[String] = []
var casos := 0


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
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
	var ficha: Ficha = escenario.ficha_jugador
	var npc: PersonajeNPC = escena.get("_enemigos")[0]
	ficha.clase = "Ladrón"
	escenario.hud.actualizar_desde_ficha()
	comprobar(escenario._iniciar_combate(npc, false), "Iniciar combate con enemigo visible.")
	var rondas: Dictionary = escenario.gestor_rondas.obtener_estado_persistente()
	rondas["actor_activo_id"] = String(ficha.obtener_id_actor())
	comprobar(escenario.gestor_rondas.restaurar_estado_persistente(rondas) == &"", "Dar turno al Ladrón.")
	ficha.iniciar_turno()
	escenario._actualizar_disponibilidad_turno()
	comprobar(not escenario.hud.habilidades[0].disabled and escenario.hud.habilidades[0].text.contains("1/1"), "HUD ofrece Ocultarse.")
	var adicionales := ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_ADICIONAL)
	escenario._on_ocultarse_hud()
	comprobar(ficha.turnos_oculto == 2 and ficha.usos_ocultarse == 0, "Activar gasta el uso y concede dos turnos oculto.")
	comprobar(ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_ADICIONAL) == adicionales, "Al escapar del combate se reponen los recursos de turno.")
	comprobar(not npc.puede_ver_actor(ficha, escenario.validador_espacial) and not npc.puede_detectar_jugador(ficha, escenario.validador_espacial), "El enemigo no ve al Ladrón aunque esté a plena vista.")
	comprobar(not escenario.en_combate, "Al perder toda percepción termina el combate.")
	var estado := ficha.obtener_estado_persistente()
	comprobar(estado["turnos_oculto"] == 2 and estado["usos_ocultarse"] == 0, "Guardado conserva duración y uso.")
	ficha.romper_ocultamiento()
	comprobar(ficha.restaurar_estado_persistente(estado) == &"" and ficha.turnos_oculto == 2, "Carga restaura el sigilo.")
	ficha.avanzar_ocultamiento()
	comprobar(ficha.turnos_oculto == 1, "Dura un segundo turno.")
	ficha.recibir_danio(1)
	comprobar(ficha.turnos_oculto == 0, "Cualquier daño recibido rompe el sigilo.")
	ficha.restaurar_estado_persistente(estado)
	ficha.aplicar_o_renovar_estado(&"veneno", 1.0, 1, 1)
	escenario.servicio_turnos.avanzar_turno(ficha)
	comprobar(ficha.turnos_oculto == 0, "El daño periódico de un estado también rompe el sigilo.")
	ficha.restaurar_estado_persistente(estado)
	ficha.avanzar_ocultamiento()
	ficha.avanzar_ocultamiento()
	comprobar(ficha.turnos_oculto == 0 and ficha.usos_ocultarse == 0, "Expira tras dos turnos sin reponer el uso.")
	var viejo := estado.duplicate(true)
	viejo.erase("usos_ocultarse")
	viejo.erase("turnos_oculto")
	comprobar(ficha.restaurar_estado_persistente(viejo) == &"" and ficha.usos_ocultarse == 1 and ficha.turnos_oculto == 0, "Guardados viejos comienzan con uso disponible.")
	var corrupto := estado.duplicate(true)
	corrupto["turnos_oculto"] = 3
	comprobar(ficha.validar_estado_persistente(corrupto) != &"", "Se rechaza duración inválida.")
	ficha.usos_ocultarse = 0
	var raciones := ficha.raciones
	comprobar(ficha.descansar_en_campamento() == &"" and ficha.usos_ocultarse == 1 and ficha.raciones == raciones - 1, "Descanso recupera Ocultarse.")
	escenario._actualizar_disponibilidad_turno()
	comprobar(not escenario.hud.habilidades[0].disabled, "Ocultarse también está disponible fuera de combate.")
	escenario._on_ocultarse_hud()
	comprobar(ficha.turnos_oculto == 2 and ficha.usos_ocultarse == 0, "Se puede iniciar el sigilo en exploración.")
	var origen := Vector2i(99, 100)
	var destino := Vector2i(100, 100)
	for x in range(98, 103):
		for y in range(98, 103):
			escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.inicializar(origen, escenario.tablero.capa_referencia)
	escenario.tablero.ocupar_celda(origen, ficha)
	comprobar(escenario.tablero.reubicar_interactuable(npc, destino), "Acercar enemigo para ataque.")
	npc.actualizar_posicion_visual()
	ficha.turnos_oculto = 2
	var opcion_ataque: OpcionAccion = null
	for opcion in npc.obtener_opciones_accion(ficha):
		if opcion.id == &"ataque_basico":
			opcion_ataque = opcion
			break
	var contexto: ContextoAccion = escenario.constructor_contexto_accion.construir_desde_opcion(opcion_ataque, ficha, origen, destino) as ContextoAccion
	var ataque: ResultadoAccion = escenario._procesar_accion_contextual(contexto)
	if ataque.tirada == null and escenario.en_combate:
		rondas = escenario.gestor_rondas.obtener_estado_persistente()
		rondas["actor_activo_id"] = String(ficha.obtener_id_actor())
		escenario.gestor_rondas.restaurar_estado_persistente(rondas)
		ficha.iniciar_turno()
		ataque = escenario._procesar_accion_contextual(contexto)
	comprobar(ataque.tirada != null and ficha.turnos_oculto == 0, "Un ataque intentado rompe el sigilo aunque falle.")
	escena.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Ocultarse: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
