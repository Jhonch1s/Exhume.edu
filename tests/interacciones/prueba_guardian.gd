extends SceneTree


func _init() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var tablero := TableroGrid.new()
	var gestor := GestorAcciones.new()
	root.add_child(tablero)
	root.add_child(gestor)
	for x in range(4):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	gestor.configurar_validador_espacial(ValidadorEspacialTablero.new(tablero))
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"guardian_prueba"
	perfil.fuerza = 3
	perfil.destreza = 2
	perfil.voluntad = 3
	perfil.vida_maxima = 20
	perfil.puede_combatir = true
	perfil.estilo_combate = DefinicionPersonaje.EstiloCombate.GUARDIAN
	perfil.acciones_principales_por_turno = 2
	perfil.radio_agro = 6
	var guardian := PersonajeNPC.new()
	guardian.definicion = perfil
	guardian.id_instancia = &"guardian_prueba"
	root.add_child(guardian)
	tablero.registrar_interactuable(Vector2i.ZERO, guardian)
	var perfil_blanco := perfil.duplicate()
	perfil_blanco.vida_maxima = 500
	perfil_blanco.estilo_combate = DefinicionPersonaje.EstiloCombate.BASICO
	var blanco := PersonajeNPC.new()
	blanco.definicion = perfil_blanco
	blanco.id_instancia = &"blanco_prueba"
	root.add_child(blanco)
	tablero.registrar_interactuable(Vector2i(1, 0), blanco)
	var servicio := ServicioTurnos.new(gestor)
	var rondas := GestorRondas.new(servicio)
	rondas.iniciar([guardian, blanco])
	rondas.bandos[guardian.id_instancia] = GestorRondas.Bando.OPONENTE
	rondas.bandos[blanco.id_instancia] = GestorRondas.Bando.JUGADOR
	var buscador := PathFindingManager.new()
	root.add_child(buscador)
	buscador.inicializar(tablero.datos)
	var decisor := DecisorCombateNPC.new()
	decisor.set_scene_root_hint(root)
	root.add_child(decisor)
	var visibles: Array[Object] = [blanco]
	var correcto := true
	var escena := load("res://scenes/personajes/guardian.tscn") as PackedScene
	correcto = correcto and escena != null
	if escena != null:
		var prefab := escena.instantiate() as PersonajeNPC
		correcto = correcto and prefab != null and prefab.definicion.vida_maxima == 20 and prefab.definicion.acciones_principales_por_turno == 2
		prefab.free()
	var vio_piedra := false
	var vio_resistencia := false
	var vio_fallo := false
	for semilla in 100:
		guardian.estado_personaje = null
		blanco.estado_personaje = null
		guardian.iniciar_turno()
		blanco.iniciar_turno()
		correcto = correcto and decisor.elegir(guardian, tablero, buscador, visibles)["decision"] == &"picotazo_guardian"
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var ataque := AccionPicotazoGuardian.new(blanco, rondas)
		ataque.motor_dados = MotorDados.new(rng)
		var resultado := gestor.procesar_accion(ataque.construir_contexto(guardian))
		correcto = correcto and resultado.exitosa and guardian.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1
		correcto = correcto and decisor.elegir(guardian, tablero, buscador, visibles)["decision"] == &"barrida_guardian"
		correcto = correcto and not gestor.procesar_accion(ataque.construir_contexto(guardian)).exitosa
		if resultado.tirada_adicional == null:
			vio_fallo = true
			correcto = correcto and blanco.obtener_estado(&"petrificado") == null
		elif resultado.tirada_adicional.exitosa:
			vio_resistencia = true
			correcto = correcto and blanco.obtener_estado(&"petrificado") == null
		else:
			vio_piedra = true
			correcto = correcto and blanco.obtener_estado(&"petrificado") != null and not blanco.puede_moverse()
			var contraataque := AccionAtaqueNPC.new(guardian, rondas)
			correcto = correcto and gestor.procesar_accion(contraataque.construir_contexto(blanco)).motivo == &"actor_petrificado"
			correcto = correcto and guardian.obtener_estado(&"recarga_petrificacion") != null
			var datos_blanco: Dictionary = JSON.parse_string(JSON.stringify(blanco.obtener_estado_persistente()))
			var datos_guardian: Dictionary = JSON.parse_string(JSON.stringify(guardian.obtener_estado_persistente()))
			correcto = correcto and blanco.validar_estado_persistente(datos_blanco) == &"" and guardian.validar_estado_persistente(datos_guardian) == &""
			correcto = correcto and blanco.restaurar_estado_persistente(datos_blanco) == &"" and guardian.restaurar_estado_persistente(datos_guardian) == &""
			correcto = correcto and servicio.avanzar_turno(blanco).exitosa and blanco.obtener_estado(&"petrificado") == null
			correcto = correcto and servicio.avanzar_turno(guardian).exitosa
			for turno in 2:
				guardian.iniciar_turno()
				var durante_recarga := gestor.procesar_accion(ataque.construir_contexto(guardian))
				correcto = correcto and durante_recarga.exitosa and durante_recarga.tirada_adicional == null and blanco.obtener_estado(&"petrificado") == null
				correcto = correcto and servicio.avanzar_turno(guardian).exitosa
				if turno == 0:
					correcto = correcto and guardian.obtener_estado(&"recarga_petrificacion") != null
			correcto = correcto and guardian.obtener_estado(&"recarga_petrificacion") == null
	correcto = correcto and vio_piedra and vio_resistencia and vio_fallo
	print("Guardian: ", "correcto" if correcto else "fallo")
	guardian.queue_free()
	blanco.queue_free()
	tablero.queue_free()
	gestor.queue_free()
	buscador.queue_free()
	decisor.queue_free()
	await process_frame
	quit(0 if correcto else 1)
