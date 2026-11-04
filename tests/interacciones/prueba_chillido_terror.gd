extends SceneTree

const Accion = preload("res://scripts/interacciones/combate/accion_chillido_terror.gd")

func _init() -> void:
	call_deferred("_probar")

func _probar() -> void:
	var tablero := TableroGrid.new()
	var gestor := GestorAcciones.new()
	root.add_child(tablero)
	root.add_child(gestor)
	for x in range(5):
		tablero.datos[Vector2i(x, 0)] = Celda.new()
	gestor.configurar_validador_espacial(ValidadorEspacialTablero.new(tablero))
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"terror_prueba"
	perfil.fuerza = 2
	perfil.destreza = 4
	perfil.voluntad = 2
	perfil.vida_maxima = 10
	perfil.puede_combatir = true
	perfil.estilo_combate = DefinicionPersonaje.EstiloCombate.TERROR_NOCTURNO
	perfil.radio_agro = 6
	var terror := PersonajeNPC.new()
	terror.definicion = perfil
	terror.id_instancia = &"terror_prueba"
	root.add_child(terror)
	tablero.registrar_interactuable(Vector2i.ZERO, terror)
	var blanco_perfil := perfil.duplicate()
	blanco_perfil.estilo_combate = DefinicionPersonaje.EstiloCombate.BASICO
	var blanco := PersonajeNPC.new()
	blanco.definicion = blanco_perfil
	blanco.id_instancia = &"blanco_prueba"
	root.add_child(blanco)
	tablero.registrar_interactuable(Vector2i(3, 0), blanco)
	var servicio := ServicioTurnos.new(gestor)
	var rondas := GestorRondas.new(servicio)
	rondas.iniciar([terror, blanco])
	rondas.bandos[terror.id_instancia] = GestorRondas.Bando.OPONENTE
	rondas.bandos[blanco.id_instancia] = GestorRondas.Bando.JUGADOR
	var buscador := PathFindingManager.new()
	root.add_child(buscador)
	buscador.inicializar(tablero.datos)
	var decisor := DecisorCombateNPC.new()
	decisor.set_scene_root_hint(root)
	root.add_child(decisor)
	var visibles: Array[Object] = [blanco]
	var plan := decisor.elegir(terror, tablero, buscador, visibles)
	var ia_correcta: bool = plan["decision"] == &"chillido_terror" and plan["objetivo"] == blanco
	var vio_exito := false
	var vio_fallo := false
	var correcto := true
	for semilla in 40:
		terror.estado_personaje = null
		blanco.estado_personaje = null
		terror.iniciar_turno()
		blanco.iniciar_turno()
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var accion = Accion.new(blanco, rondas)
		accion.motor_dados = MotorDados.new(rng)
		var resultado: ResultadoAccion = gestor.procesar_accion(accion.construir_contexto(terror))
		correcto = correcto and resultado.exitosa and resultado.tirada.atributo == 2 and terror.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0
		if resultado.tirada.exitosa:
			vio_exito = true
			correcto = correcto and blanco.obtener_estado(&"aturdido") == null
		else:
			vio_fallo = true
			correcto = correcto and blanco.obtener_estado(&"aturdido") != null
		correcto = correcto and terror.obtener_estado(&"recarga_chillido") != null
		var guardado: Dictionary = JSON.parse_string(JSON.stringify(terror.obtener_estado_persistente()))
		correcto = correcto and terror.validar_estado_persistente(guardado) == &""
		for turno in 3:
			correcto = correcto and servicio.avanzar_turno(terror).exitosa
		correcto = correcto and terror.obtener_estado(&"recarga_chillido") == null
	correcto = correcto and vio_exito and vio_fallo and ia_correcta
	print("ChillidoTerror: ", "correcto" if correcto else "fallo")
	terror.queue_free()
	blanco.queue_free()
	tablero.queue_free()
	gestor.queue_free()
	buscador.queue_free()
	decisor.queue_free()
	await process_frame
	quit(0 if correcto else 1)
