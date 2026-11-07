extends SceneTree


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var tablero := TableroGrid.new()
	var gestor := GestorAcciones.new()
	root.add_child(tablero)
	root.add_child(gestor)
	for x in range(3):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	gestor.configurar_validador_espacial(ValidadorEspacialTablero.new(tablero))
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"guardian_prueba"
	perfil.fuerza = 3
	perfil.destreza = 2
	perfil.voluntad = 2
	perfil.vida_maxima = 20
	perfil.puede_combatir = true
	perfil.estilo_combate = DefinicionPersonaje.EstiloCombate.GUARDIAN
	perfil.radio_agro = 6
	var guardian := PersonajeNPC.new()
	guardian.definicion = perfil
	guardian.id_instancia = &"guardian_prueba"
	root.add_child(guardian)
	tablero.registrar_interactuable(Vector2i.ZERO, guardian)
	var blanco := PersonajeNPC.new()
	blanco.definicion = perfil.duplicate()
	blanco.id_instancia = &"blanco_prueba"
	root.add_child(blanco)
	tablero.registrar_interactuable(Vector2i(1, 0), blanco)
	var servicio := ServicioTurnos.new(gestor)
	var rondas := GestorRondas.new(servicio)
	rondas.iniciar([guardian, blanco])
	rondas.bandos[guardian.id_instancia] = GestorRondas.Bando.OPONENTE
	rondas.bandos[blanco.id_instancia] = GestorRondas.Bando.JUGADOR
	var acierto := false
	var fallo := false
	var correcto := true
	for semilla in 40:
		guardian.estado_personaje = null
		blanco.estado_personaje = null
		guardian.iniciar_turno()
		blanco.iniciar_turno()
		var vida := blanco.vida_actual
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var accion := AccionBarridaGuardian.new(blanco, rondas)
		accion.motor_dados = MotorDados.new(rng)
		var resultado := gestor.procesar_accion(accion.construir_contexto(guardian))
		correcto = correcto and resultado.exitosa and resultado.tirada != null and resultado.tirada.atributo == 2
		correcto = correcto and guardian.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0 and blanco.vida_actual == vida
		if resultado.tirada.exitosa:
			acierto = true
			correcto = correcto and blanco.obtener_estado(&"caido") == null
		else:
			fallo = true
			correcto = correcto and blanco.obtener_estado(&"caido") != null
			var guardado: Dictionary = JSON.parse_string(JSON.stringify(blanco.obtener_estado_persistente()))
			correcto = correcto and blanco.validar_estado_persistente(guardado) == &""
			correcto = correcto and servicio.avanzar_turno(blanco).exitosa and blanco.obtener_estado(&"caido") == null
	guardian.iniciar_turno()
	tablero.reubicar_interactuable(blanco, Vector2i(2, 0))
	var fuera := AccionBarridaGuardian.new(blanco, rondas)
	var resultado_fuera := gestor.procesar_accion(fuera.construir_contexto(guardian))
	correcto = correcto and not resultado_fuera.exitosa and guardian.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1
	correcto = correcto and acierto and fallo
	print("BarridaGuardián: ", "correcto" if correcto else "fallo")
	guardian.queue_free()
	blanco.queue_free()
	tablero.queue_free()
	gestor.queue_free()
	await process_frame
	quit(0 if correcto else 1)
