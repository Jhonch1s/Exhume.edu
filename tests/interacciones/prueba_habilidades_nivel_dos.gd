extends SceneTree

var fallos: Array[String] = []
var casos := 0
var escena: Node
var e: Node
var f: Ficha
var npcs: Array[PersonajeNPC] = []
var originales: Array[Dictionary] = []
var ficha_original: Dictionary
var captura_empuje := false
const RUTA := "user://prueba_habilidades_nivel_dos.json"


func _initialize() -> void:
	call_deferred(&"_probar")


func _probar() -> void:
	escena = load("res://tests/interacciones/escena_facciones_npc.tscn").instantiate()
	e = escena.get_node("Escenario")
	e.set_script(load("res://tests/soporte/escenario_sin_render.gd"))
	root.add_child(escena)
	for intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 5:
			break
	escena.set_process(false)
	e.set_process(false)
	f = e.ficha_jugador
	ficha_original = f.obtener_estado_persistente()
	npcs.assign(escena.get("_enemigos"))
	for npc in npcs:
		originales.append(npc.obtener_estado_persistente())
	for x in range(94, 125):
		for y in range(94, 110):
			e.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	e.pathfinding.inicializar(e.tablero.datos)
	_probar_elecciones()
	await _probar_ariete()
	await _probar_agarre()
	await _probar_golpe()
	await _probar_inercia()
	await _probar_senuelo()
	await _probar_sombra()
	await _probar_escapista()
	_probar_trampero()
	await _probar_transposicion()
	await _probar_trasvase()
	_probar_piromancia()
	_probar_contagio()
	e._terminar_combate(false)
	escena.queue_free()
	await process_frame
	for fallo in fallos:
		push_error(fallo)
	print("Habilidades nivel 2: %d comprobaciones, %d fallos." % [casos, fallos.size()])
	quit(0 if fallos.is_empty() else 1)


func preparar(clase: String, id := "") -> void:
	e.panel_progresion.hide()
	e._actualizar_estado_modal_interaccion()
	e._terminar_combate(false)
	e._cancelar_exploracion_npc()
	for superficie in e.tablero.efectos_superficie_por_id.values().duplicate():
		if superficie.coordenada_mapa.x >= 94:
			e.tablero.retirar_efecto_superficie(superficie)
			superficie.queue_free()
	for i in npcs.size():
		npcs[i].restaurar_estado_persistente(originales[i])
		e.tablero.reubicar_interactuable(npcs[i], Vector2i(116 + i, 106))
		npcs[i].actualizar_posicion_visual()
	var anterior := f.coordenada_mapa
	f.restaurar_estado_persistente(ficha_original)
	e.tablero.liberar_celda(anterior, f)
	f.inicializar(Vector2i(99, 100), e.tablero.capa_referencia)
	e.tablero.ocupar_celda(f.coordenada_mapa, f)
	f.clase = clase
	f.velocidad_paso = 0.001
	f.ganar_experiencia(100)
	if id != "":
		comprobar(f.aprender_recompensa(id), "Aprender " + id)
	f.iniciar_turno()
	e.tablero.reubicar_interactuable(npcs[0], Vector2i(100, 100))
	npcs[0].actualizar_posicion_visual()
	for x in range(94, 125):
		for y in range(94, 110):
			e.tablero.datos[Vector2i(x, y)].visibilidad = Celda.EstadoVisibilidad.VISIBLE
	e.hud.actualizar_desde_ficha()
	e._actualizar_disponibilidad_turno()


func combate() -> void:
	comprobar(e._iniciar_combate(npcs[0], false), "Iniciar combate de prueba.")
	var estado: Dictionary = e.gestor_rondas.obtener_estado_persistente()
	estado["actor_activo_id"] = String(f.id_actor)
	e.gestor_rondas.restaurar_estado_persistente(estado)
	f.iniciar_turno()
	e._actualizar_disponibilidad_turno()


func archivo() -> void:
	var antes := f.obtener_estado_persistente()
	var guardado: StringName = e.guardar_partida(RUTA)
	comprobar(guardado == &"", "Guardar habilidades: " + String(guardado))
	if guardado == &"":
		f.usos_ataque_doble = 1
		var cargado: StringName = e.cargar_partida(RUTA)
		var despues := f.obtener_estado_persistente()
		var diferencias: Array[String] = []
		for clave: String in antes:
			if antes[clave] != despues[clave]:
				diferencias.append(clave)
		comprobar(cargado == &"" and diferencias.is_empty(), "Cargar conserva aprendizaje, usos, selecciones y límites sin reponer: %s / %s." % [cargado, str(diferencias)])


func _probar_elecciones() -> void:
	for clase: String in ["Guerrero", "Ladrón", "Mago"]:
		var opciones := CatalogoHabilidades.opciones(clase)
		comprobar(opciones.size() == 4 and opciones.filter(func(o): return o["tipo"] == "Activa").size() == 2, "Cada clase tiene dos activas y dos pasivas.")
		for opcion in opciones:
			preparar(clase)
			var inicial: String = {"Guerrero": "ataque_doble", "Ladrón": "ocultarse", "Mago": "bola_de_fuego"}[clase]
			comprobar((e.hud.habilidades[0].get_node("IconoHabilidad") as TextureRect).texture == CatalogoHabilidades.icono(inicial), "HUD muestra icono inicial de " + clase)
			f.pv_actual -= 2
			f.usos_ataque_doble = 0
			comprobar(f.aprender_recompensa(opcion["id"]) and f.nivel_recompensa_pendiente == 0 and f.pv_actual == f.pv_max - 2 and f.usos_ataque_doble == 0, "Aprender una recompensa conserva vida y habilidad inicial gastada.")
			e.hud.actualizar_desde_ficha()
			comprobar((e.hud.habilidades[1].get_node("IconoHabilidad") as TextureRect).texture == CatalogoHabilidades.icono(opcion["id"]), "HUD muestra icono aprendido de " + opcion["id"])
			comprobar(not f.aprender_recompensa(opciones[1]["id"]) and f.pasivas_aprendidas.size() + f.activas_aprendidas.size() == 1, "Solo se aprende una de las cuatro.")
			var json: Dictionary = JSON.parse_string(JSON.stringify(f.obtener_estado_persistente()))
			comprobar(f.restaurar_estado_persistente(json) == &"" and f.conoce_habilidad(opcion["id"]), "Aprendizaje sobrevive a JSON.")
			if opcion["tipo"] == "Activa":
				f.usos_activas[opcion["id"]] = 0
				f.usos_habilidades_cambiados.emit()
				comprobar((e.hud.habilidades[1].get_node("EstadoHabilidad") as Label).text == "0/1", "HUD muestra uso agotado de " + opcion["id"])
				var gastado := f.obtener_estado_persistente()
				comprobar(f.descansar_en_campamento() == &"" and f.usos_activas[opcion["id"]] == 1, "El descanso recupera el uso propio de " + opcion["id"])
				comprobar(f.restaurar_estado_persistente(gastado) == &"" and f.usos_activas[opcion["id"]] == 0, "Cargar un uso agotado no lo repone.")
			var corrupto := json.duplicate(true)
			corrupto["pasivas_aprendidas"] = ["id_desconocido"]
			comprobar(f.restaurar_estado_persistente(corrupto) != &"" and f.conoce_habilidad(opcion["id"]), "ID inválido rechazado antes de mutar.")
	preparar("Guerrero")
	comprobar(e.abrir_progresion() == &"" and e.panel_progresion.opciones.size() == 4 and e.interaccion_modal_activa, "Panel real muestra cuatro opciones y bloquea el mundo.")
	e.panel_progresion.hide()
	e._actualizar_estado_modal_interaccion()
	comprobar(f.nivel_recompensa_pendiente == 2, "Cancelar conserva recompensa pendiente.")
	e.abrir_progresion()
	e.panel_progresion.selector.select(3)
	e.panel_progresion._confirmar()
	comprobar(f.conoce_habilidad("inercia") and not e.panel_progresion.visible, "Confirmar en panel aprende la opción seleccionada.")
	archivo()


func _probar_ariete() -> void:
	preparar("Guerrero", "ariete")
	comprobar((await e.habilidades_nivel_dos.ejecutar("ariete", Vector2i(120, 100))).exitosa == false and f.usos_activas["ariete"] == 1, "Ariete inválido no consume.")
	e.tablero.datos[Vector2i(101, 100)].caminable = false
	comprobar(not (await e.habilidades_nivel_dos.ejecutar("ariete", Vector2i(100, 100))).exitosa and f.usos_activas["ariete"] == 1, "Un muro tras el blanco bloquea Ariete sin cobrar.")
	e.tablero.datos[Vector2i(101, 100)].caminable = true
	observar_empuje()
	comprobar((await e.habilidades_nivel_dos.ejecutar("ariete", Vector2i(100, 100))).exitosa and npcs[0].coordenada_mapa == Vector2i(102, 100) and f.usos_activas["ariete"] == 0, "Ariete empuja dos casillas y gasta su uso.")
	archivo()
	preparar("Guerrero", "ariete")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Fuego.tscn"), Vector2i(101, 100), 0, &"ariete_fuego")
	comprobar((await e.habilidades_nivel_dos.ejecutar("ariete", Vector2i(100, 100))).exitosa and npcs[0].coordenada_mapa == Vector2i(101, 100) and npcs[0].obtener_estado(&"quemado") != null, "El fuego reacciona al empuje e interrumpe su recorrido.")
	preparar("Guerrero", "ariete")
	var trampa := preload("res://scenes/interactuables/trampas/TrampaSuperficie.tscn").instantiate() as TrampaSuperficie
	trampa.id_instancia = &"placa_ariete"
	trampa.interrumpe_al_activar = false
	trampa.escena_superficie = preload("res://scenes/efectos_superficie/Humo.tscn")
	trampa.radio = 0
	e.zona_actual.get_node("Interactuables").add_child(trampa)
	e.tablero.registrar_interactuable(Vector2i(101, 100), trampa)
	comprobar((await e.habilidades_nivel_dos.ejecutar("ariete", Vector2i(100, 100))).exitosa and npcs[0].coordenada_mapa == Vector2i(101, 100) and trampa.estado == TrampaSuperficie.Estado.ACTIVADA, "Ariete se detiene en una trampa activada aunque no interrumpa el movimiento normal.")
	e.tablero.retirar_interactuable(trampa)
	trampa.queue_free()


func observar_empuje() -> void:
	var origen := npcs[0].global_position
	var destino: Vector2 = e.tablero.capa_referencia.to_global(e.tablero.capa_referencia.map_to_local(Vector2i(101, 100)))
	await create_timer(0.08).timeout
	comprobar(npcs[0].esta_moviendose and npcs[0].global_position != origen and npcs[0].global_position != destino and npcs[0].coordenada_mapa == Vector2i(100, 100), "Ariete interpola la primera casilla antes de confirmar entrada y peligros.")
	comprobar(e.guardar_partida(RUTA) != &"", "No se guarda a mitad del desplazamiento.")


func _probar_agarre() -> void:
	preparar("Guerrero", "agarre")
	combate()
	comprobar((await e.habilidades_nivel_dos.ejecutar("agarre", Vector2i(100, 100))).exitosa, "Agarre válido.")
	var camino: Array[Vector2i] = [f.coordenada_mapa, Vector2i(98, 100)]
	await f.mover_por_camino(camino, e._preparar_paso_actor, e._confirmar_paso_actor, e._cancelar_paso_actor, e._procesar_salida_paso_actor, e._procesar_entrada_paso_actor, e._calcular_coste_paso_actor, Callable(), true)
	comprobar(npcs[0].coordenada_mapa == Vector2i(99, 100) and f.agarre_pasos == 1, "Un paso real arrastra al agarrado y conserva un paso.")
	archivo()
	var corrupto: Dictionary = e.persistencia_partida.crear_snapshot(e.tablero, e.obtener_id_zona(), f, e.registro_conocimiento, e.gestor_rondas)
	corrupto["ficha"]["habilidades_nivel_dos"]["agarre_objetivo"] = "actor_desconocido"
	comprobar(e.persistencia_partida.validar_restauracion(corrupto, e.tablero, e.obtener_id_zona(), f, e.registro_conocimiento, e.gestor_rondas) == &"agarre_guardado_invalido", "Rechaza Agarre a una identidad ausente antes de restaurar.")
	f.iniciar_turno()
	comprobar(f.agarre_objetivo == "", "El siguiente turno rompe Agarre.")


func _probar_golpe() -> void:
	preparar("Guerrero", "golpe_desplazante")
	combate()
	var soporte = load("res://tests/interacciones/prueba_actitud_npc.gd").new()
	npcs[0].motor_dados = MotorDados.new(soporte._rng_para([1, 6]))
	decidir_empujes([true])
	var golpes: Array[ResultadoAccion] = await e.ejecutar_ataque_doble(npcs[0])
	comprobar(golpes.size() == 1 and npcs[0].coordenada_mapa == Vector2i(101, 100) and "golpe_desplazante" in f.pasivas_usadas_turno, "El primer golpe desplaza y el segundo no golpea fuera de alcance.")
	e.habilidades_nivel_dos.al_golpe(npcs[0])
	comprobar(e.habilidades_nivel_dos.empuje_pendiente == null, "No se ofrece otro empuje tras consumir la oportunidad.")
	archivo()
	preparar("Guerrero", "golpe_desplazante")
	combate()
	npcs[0].motor_dados = MotorDados.new(soporte._rng_para([1, 6, 1, 6]))
	var vida := npcs[0].vida_actual
	decidir_empujes([false, true])
	golpes = await e.ejecutar_ataque_doble(npcs[0])
	comprobar(golpes.size() == 2 and npcs[0].vida_actual == vida - 2 and npcs[0].coordenada_mapa == Vector2i(101, 100), "Rechazar el primer empuje permite ambos golpes y decidir al acertar el segundo.")
	archivo()
	preparar("Guerrero", "golpe_desplazante")
	combate()
	npcs[0].motor_dados = MotorDados.new(soporte._rng_para([1, 6, 1, 6]))
	decidir_empujes([false, false])
	golpes = await e.ejecutar_ataque_doble(npcs[0])
	comprobar(golpes.size() == 2 and npcs[0].coordenada_mapa == Vector2i(100, 100) and f.pasivas_usadas_turno.is_empty(), "Rechazar ambos empujes no mueve ni consume la pasiva.")
	preparar("Guerrero", "golpe_desplazante")
	combate()
	npcs[0].motor_dados = MotorDados.new(soporte._rng_para([6, 6]))
	golpes = await e.ejecutar_ataque_doble(npcs[0])
	comprobar(golpes.size() == 2 and e.habilidades_nivel_dos.empuje_pendiente == null, "Ataques fallidos no ofrecen empuje.")
	preparar("Guerrero", "golpe_desplazante")
	combate()
	npcs[0].motor_dados = MotorDados.new(soporte._rng_para([1, 6]))
	var opcion: OpcionAccion
	for candidata in npcs[0].obtener_opciones_accion(f):
		if candidata.id == &"ataque_basico":
			opcion = candidata
	var contexto: ContextoAccion = e.constructor_contexto_accion.construir_desde_opcion(opcion, f, f.coordenada_mapa, npcs[0].coordenada_mapa)
	var resultado: ResultadoAccion = e._procesar_accion_contextual(contexto)
	e._presentar_resultado_contextual("Ataque básico", resultado, contexto)
	e._actualizar_decision_empuje()
	comprobar(resultado.tirada != null and e.habilidades_nivel_dos.empuje_pendiente == npcs[0] and not e.panel_empuje.visible, "El ataque básico espera a cerrar su resultado antes de ofrecer empuje.")
	e.panel_resultado_accion.ocultar()
	e._actualizar_decision_empuje()
	comprobar(e.panel_empuje.visible and e.interaccion_modal_activa, "Cerrar el resultado da paso a la decisión de empuje.")
	e.panel_empuje.canceled.emit()
	comprobar(e.habilidades_nivel_dos.empuje_pendiente == null and npcs[0].coordenada_mapa == Vector2i(100, 100) and not e.interaccion_modal_activa, "No empujar cierra el diálogo y libera el mundo sin mover al blanco.")
	soporte.free()


func decidir_empujes(respuestas: Array[bool]) -> void:
	for aceptar in respuestas:
		for intento in 300:
			await process_frame
			if e.habilidades_nivel_dos.empuje_pendiente != null:
				break
		e._actualizar_decision_empuje()
		comprobar(is_instance_valid(e.panel_empuje) and e.panel_empuje.visible and e.interaccion_modal_activa and "golpe_desplazante" not in f.pasivas_usadas_turno, "La decisión aparece tras causar daño y antes de gastar la pasiva.")
		comprobar(e.guardar_partida(RUTA) != &"" and e.cargar_partida(RUTA) != &"", "La decisión pendiente bloquea guardar y cargar.")
		if "--captura" in OS.get_cmdline_user_args() and not captura_empuje:
			await RenderingServer.frame_post_draw
			comprobar(root.get_texture().get_image().save_png("res://.godot/decision_empuje.png") == OK, "Captura de decisión de empuje.")
			captura_empuje = true
		await e._resolver_decision_empuje(aceptar)


func _probar_inercia() -> void:
	preparar("Guerrero", "inercia")
	combate()
	e.tablero.reubicar_interactuable(npcs[1], Vector2i(99, 102))
	e._incorporar_con_bando(npcs[1], GestorRondas.Bando.OPONENTE)
	npcs[0].recibir_danio(npcs[0].vida_actual, f)
	comprobar(f.pasos_inercia == 2 and "inercia" in f.pasivas_usadas_turno, "La baja concede Inercia una vez.")
	f.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO))
	f.consumir_paso_movimiento(2)
	comprobar(f.pasos_inercia == 1 and f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 0, "Un paso de Inercia no consume movimiento aunque tenga coste de terreno.")
	var estado: Dictionary = JSON.parse_string(JSON.stringify(f.obtener_estado_persistente()))
	comprobar(f.restaurar_estado_persistente(estado) == &"" and f.pasos_inercia == 1 and "inercia" in f.pasivas_usadas_turno, "Inercia no se renueva al cargar.")
	var camino: Array[Vector2i] = [f.coordenada_mapa, Vector2i(98, 100), Vector2i(97, 100)]
	comprobar(e._limitar_camino_jugador(camino).size() == 2, "La ruta incluye exactamente el paso gratis restante con movimiento agotado.")
	camino.resize(2)
	await f.mover_por_camino(camino, e._preparar_paso_actor, e._confirmar_paso_actor, e._cancelar_paso_actor, e._procesar_salida_paso_actor, e._procesar_entrada_paso_actor, e._calcular_coste_paso_actor, Callable(), true)
	comprobar(f.coordenada_mapa == Vector2i(98, 100) and f.pasos_inercia == 0 and f.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 0, "Inercia permite movimiento real con reserva agotada.")


func _probar_senuelo() -> void:
	preparar("Ladrón", "senuelo")
	comprobar((await e.habilidades_nivel_dos.ejecutar("senuelo", Vector2i(102, 100))).exitosa and f.senuelos.has(String(npcs[0].id_instancia)), "Señuelo atrae al neutral que no ve una amenaza.")
	var plan: Dictionary = e.habilidades_nivel_dos.plan_senuelo(npcs[0])
	comprobar(plan.get("destino") == Vector2i(102, 100) and plan["camino"].size() > 1, "La IA planea investigar la casilla del sonido.")
	archivo()
	combate()
	comprobar(e.habilidades_nivel_dos.plan_senuelo(npcs[0]).is_empty() and not f.senuelos.has(String(npcs[0].id_instancia)), "Una amenaza visible interrumpe el señuelo.")
	preparar("Ladrón", "senuelo")
	await e.habilidades_nivel_dos.ejecutar("senuelo", Vector2i(102, 100))
	await e._procesar_turno_npc_exploracion(npcs[0], e._secuencia_exploracion_npc)
	comprobar(npcs[0].coordenada_mapa == Vector2i(102, 100) and not f.senuelos.has(String(npcs[0].id_instancia)), "El NPC investiga con movimiento real y el señuelo expira tras su turno.")
	npcs[0].aplicar_o_renovar_estado(&"enredado", 1, 1, 1)
	f.senuelos[String(npcs[0].id_instancia)] = [103, 100]
	comprobar(e.habilidades_nivel_dos.plan_senuelo(npcs[0]).is_empty(), "Un NPC enredado conserva su rama de liberación y no entra en bucle por el señuelo.")


func _probar_sombra() -> void:
	preparar("Ladrón", "paso_sombra")
	comprobar(not (await e.habilidades_nivel_dos.ejecutar("paso_sombra", Vector2i(99, 102))).exitosa and f.usos_activas["paso_sombra"] == 1, "Paso de sombra exige ocultamiento.")
	f.ocultarse()
	comprobar(not (await e.habilidades_nivel_dos.ejecutar("paso_sombra", Vector2i(100, 100))).exitosa and f.usos_activas["paso_sombra"] == 1, "Paso de sombra no ocupa la casilla de otro actor.")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Fuego.tscn"), Vector2i(99, 101), 0, &"sombra_fuego")
	comprobar((await e.habilidades_nivel_dos.ejecutar("paso_sombra", Vector2i(99, 102))).exitosa and f.coordenada_mapa == Vector2i(99, 102) and f.obtener_estado(&"quemado") == null and f.turnos_oculto == 2, "Paso de sombra salta sobre el fuego y conserva sigilo.")
	archivo()
	preparar("Ladrón", "paso_sombra")
	combate()
	f.ocultarse()
	f.consumir_recurso_turno(RecursosTurnoActor.ACCION_ADICIONAL, 1)
	comprobar(e.habilidades_nivel_dos.validar("paso_sombra", Vector2i(99, 102)) == &"recursos_turno_insuficientes" and f.usos_activas["paso_sombra"] == 1, "Ocultarse y Paso de sombra no comparten una única acción adicional.")
	f.iniciar_turno()
	comprobar((await e.habilidades_nivel_dos.ejecutar("paso_sombra", Vector2i(99, 102))).exitosa and f.turnos_oculto > 0, "Paso de sombra funciona en combate oculto y con acción adicional disponible.")


func _probar_escapista() -> void:
	preparar("Ladrón", "escapista")
	combate()
	e.tablero.datos[Vector2i(100, 100)].bloquea_vision = true
	npcs[0].obtener_definicion_personaje().radio_agro = 1
	e.tablero.reubicar_interactuable(npcs[0], Vector2i(102, 100))
	var camino: Array[Vector2i] = [f.coordenada_mapa, Vector2i(98, 100)]
	await f.mover_por_camino(camino, e._preparar_paso_actor, e._confirmar_paso_actor, e._cancelar_paso_actor, e._procesar_salida_paso_actor, e._procesar_entrada_paso_actor, e._calcular_coste_paso_actor, Callable(), true)
	comprobar(f.turnos_oculto == 1 and f.usos_ocultarse == 1, "Escapista oculta sin gastar la habilidad inicial.")
	var json: Dictionary = JSON.parse_string(JSON.stringify(f.obtener_estado_persistente()))
	comprobar(f.restaurar_estado_persistente(json) == &"" and f.turnos_oculto == 1, "El sigilo de Escapista puede guardarse con Ocultarse sin gastar.")
	e.tablero.datos[Vector2i(100, 100)].bloquea_vision = false
	npcs[0].obtener_definicion_personaje().radio_agro = 7


func _probar_trampero() -> void:
	preparar("Ladrón", "trampero")
	var trampa := TrampaSuperficie.new()
	trampa.id_instancia = &"placa_trampero"
	trampa.estado = TrampaSuperficie.Estado.DESCUBIERTA
	var celda := Celda.new()
	celda.interactuables.append(trampa)
	comprobar(e.consultor_reacciones.obtener_reacciones(celda, TiposInteraccion.TipoAccion.ENTRAR, f).is_empty(), "Trampero evita disparar una placa descubierta.")
	trampa.estado = TrampaSuperficie.Estado.OCULTA
	comprobar(not e.consultor_reacciones.obtener_reacciones(celda, TiposInteraccion.TipoAccion.ENTRAR, f).is_empty(), "Las trampas desconocidas siguen reaccionando.")
	trampa.free()


func _probar_transposicion() -> void:
	preparar("Mago", "transposicion")
	var origen := f.coordenada_mapa
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Fuego.tscn"), origen, 0, &"intercambio_origen")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Fuego.tscn"), Vector2i(100, 100), 0, &"intercambio_destino")
	comprobar((await e.habilidades_nivel_dos.ejecutar("transposicion", Vector2i(100, 100))).exitosa and f.coordenada_mapa == Vector2i(100, 100) and npcs[0].coordenada_mapa == origen, "Transposición intercambia ambos registros del tablero.")
	comprobar(f in e.tablero.obtener_celda(f.coordenada_mapa).ocupantes and npcs[0] in e.tablero.obtener_celda(origen).interactuables, "Ocupación coincide con posiciones tras intercambiar.")
	comprobar(f.obtener_estado(&"quemado") != null and npcs[0].obtener_estado(&"quemado") != null, "Ambos destinos de Transposición aplican sus peligros.")
	archivo()
	preparar("Mago", "transposicion")
	e.tablero.reubicar_interactuable(npcs[0], Vector2i(105, 100))
	comprobar(not (await e.habilidades_nivel_dos.ejecutar("transposicion", Vector2i(105, 100))).exitosa and f.usos_activas["transposicion"] == 1, "Transposición rechaza6casillas sin gastar.")
	e.tablero.reubicar_interactuable(npcs[0], Vector2i(104, 100))
	comprobar((await e.habilidades_nivel_dos.ejecutar("transposicion", Vector2i(104, 100))).exitosa and f.coordenada_mapa == Vector2i(104, 100), "Transposición alcanza5casillas.")


func _probar_trasvase() -> void:
	preparar("Mago", "trasvase")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/HumoVeneno.tscn"), Vector2i(99, 101), 0, &"trasvase_veneno")
	var superficie: Node2D = e.habilidades_nivel_dos.superficie(Vector2i(99, 101))
	superficie.restaurar_turnos_restantes_superficie(2)
	var id: StringName = superficie.obtener_id_reaccion()
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/HumoVeneno.tscn"), Vector2i(100, 100), 0, &"trasvase_destino_ocupado")
	comprobar(not (await e.habilidades_nivel_dos.ejecutar("trasvase", Vector2i(100, 100), Vector2i(99, 101))).exitosa and f.usos_activas["trasvase"] == 1 and superficie.coordenada_mapa == Vector2i(99, 101), "Trasvase rechaza otra superficie bajo el NPC sin gastar ni mover el origen.")
	comprobar((await e.habilidades_nivel_dos.ejecutar("trasvase", Vector2i(98, 101), Vector2i(99, 101))).exitosa and superficie.coordenada_mapa == Vector2i(98, 101) and superficie.obtener_turnos_restantes_superficie() == 2, "Trasvase mueve la misma superficie sin renovar duración.")
	comprobar(e.tablero.efectos_superficie_por_id[id] == superficie and e.tablero.obtener_celda(Vector2i(99, 101)).efectos_superficie.is_empty(), "No duplica superficie ni deja registro anterior.")
	archivo()
	comprobar(e.habilidades_nivel_dos.superficie(Vector2i(98, 101)).obtener_turnos_restantes_superficie() == 2, "Carga conserva la superficie trasladada y su duración.")
	preparar("Mago", "trasvase")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Humo.tscn"), Vector2i(105, 100), 0, &"trasvase_seis")
	e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/Humo.tscn"), Vector2i(104, 100), 0, &"trasvase_cinco")
	comprobar(e.habilidades_nivel_dos.validar("trasvase", Vector2i(99, 105), Vector2i(105, 100)) != &"" and e.habilidades_nivel_dos.validar("trasvase", Vector2i(99, 106), Vector2i(104, 100)) != &"", "Trasvase rechaza origen o destino a6casillas.")
	comprobar((await e.habilidades_nivel_dos.ejecutar("trasvase", Vector2i(99, 105), Vector2i(104, 100))).exitosa and e.habilidades_nivel_dos.superficie(Vector2i(99, 105)) != null, "Trasvase acepta origen y destino a5casillas.")
	var soporte = load("res://tests/interacciones/prueba_actitud_npc.gd").new()
	for familia in ["Fuego", "HumoVeneno", "Humo"]:
		preparar("Mago", "trasvase")
		e.tablero.desplegar_efecto_superficie(load("res://scenes/efectos_superficie/%s.tscn" % familia), Vector2i(99, 101), 0, &"trasvase_sobre_npc")
		superficie = e.habilidades_nivel_dos.superficie(Vector2i(99, 101))
		superficie.restaurar_turnos_restantes_superficie(2)
		if superficie is HumoVeneno:
			superficie.motor_dados = MotorDados.new(soporte._rng_para([6]))
		var principales := f.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL)
		comprobar((await e.habilidades_nivel_dos.ejecutar("trasvase", Vector2i(100, 100), Vector2i(99, 101))).exitosa and e.habilidades_nivel_dos.superficie(Vector2i(100, 100)) == superficie, familia + " se puede mover bajo un NPC vivo.")
		comprobar(npcs[0].coordenada_mapa == Vector2i(100, 100) and superficie.obtener_turnos_restantes_superficie() == 2 and e.tablero.obtener_celda(Vector2i(99, 101)).efectos_superficie.is_empty(), "Trasvase conserva duración, no mueve al NPC ni duplica el bloque.")
		if familia != "Humo":
			comprobar(npcs[0].obtener_estado(&"quemado" if familia == "Fuego" else &"veneno") != null, familia + " aplica su reacción al NPC al colocarse.")
		comprobar(f.usos_activas["trasvase"] == 0 and f.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == principales - 1, "Trasvase sobre NPC cuesta un único uso y una acción principal.")
		archivo()
	soporte.free()


func _probar_piromancia() -> void:
	preparar("Mago", "piromancia_libre")
	comprobar(not e.habilidades_nivel_dos.lanzar_al_suelo(Vector2i(100, 100)).exitosa and f.usos_bola_fuego == 1, "Piromancia libre no crea fuego debajo de un actor.")
	comprobar(e.habilidades_nivel_dos.lanzar_al_suelo(Vector2i(98, 100)).exitosa and f.usos_bola_fuego == 0 and e.habilidades_nivel_dos.superficie(Vector2i(98, 100)).obtener_turnos_restantes_superficie() == 3, "Piromancia crea fuego de tres turnos y consume el uso de Bola de fuego.")
	archivo()


func _probar_contagio() -> void:
	preparar("Mago", "contagio_arcano")
	f.aplicar_o_renovar_estado(&"veneno", 1, 3, 2)
	f.contagio_elegido = "veneno"
	comprobar(e.ejecutar_bola_fuego(npcs[0]).exitosa, "El ataque real del Mago dispara Contagio.")
	comprobar(f.obtener_estado(&"veneno") == null and npcs[0].obtener_estado(&"veneno").ticks_pendientes == 2 and "contagio_arcano" in f.pasivas_usadas_turno, "Contagio transfiere estado y ticks y consume oportunidad del turno.")
	f.aplicar_o_renovar_estado(&"veneno", 1, 3, 3)
	e.habilidades_nivel_dos.al_golpe(npcs[0])
	comprobar(f.obtener_estado(&"veneno") != null and npcs[0].obtener_estado(&"veneno").ticks_pendientes == 2, "No se repite Contagio en el mismo turno.")
	archivo()


func comprobar(condicion: bool, mensaje: String) -> void:
	casos += 1
	if not condicion:
		fallos.append(mensaje)
