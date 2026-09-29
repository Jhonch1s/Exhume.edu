extends Node

const RUTA := "user://prueba_estado_npc_persistente.json"

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_comprobar(
		not EstadoPartida.trompo_conocido,
		"Un proceso nuevo debe iniciar sin memoria narrativa previa."
	)
	var zona := (load("res://scenes/zona1/zona_1.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(zona)
	var tablero := TableroGrid.new()
	get_tree().root.add_child(tablero)
	tablero.generar_desde_zona(zona)
	tablero.registrar_interactuables_desde_zona(zona, zona.get_node("CapaSuelo"))
	var ficha := (load("res://scenes/ficha/ficha.tscn") as PackedScene).instantiate() as Ficha
	get_tree().root.add_child(ficha)
	ficha.inicializar(Vector2i(2, 1), zona.get_node("CapaSuelo"))
	var conocimiento := RegistroConocimiento.new()
	var trompo := (load("res://scenes/personajes/npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	trompo.id_instancia = &"goblin_001"
	zona.add_child(trompo)
	_comprobar(
		tablero.registrar_interactuable(Vector2i(2, 1), trompo)
		and tablero.obtener_interactuable(&"goblin_001") == trompo,
		"El NPC debe registrarse y resolverse por su ID estable."
	)
	if tablero.obtener_interactuable(&"goblin_001") != trompo:
		zona.queue_free()
		tablero.queue_free()
		ficha.queue_free()
		_finalizar()
		return
	_comprobar(
		trompo.vida_actual == 15 and trompo.nivel_actual == 3
		and trompo.obtener_actitud_hacia_jugador()
		== DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
		and not trompo.establecer_actitud_hacia_jugador(
			DefinicionPersonaje.ActitudInicialJugador.HOSTIL
		),
		"Trompo inicia desde su definición y su actitud fija no cambia."
	)
	var cambios_vida: Array[int] = []
	var cambios_derrota: Array[bool] = []
	trompo.puntos_vida_cambiados.connect(
		func(actual: int, _maximo: int): cambios_vida.append(actual)
	)
	trompo.derrota_cambiada.connect(
		func(derrotado: bool): cambios_derrota.append(derrotado)
	)
	_comprobar(
		trompo.recibir_danio(5) == 5 and trompo.recibir_danio(20) == 10
		and trompo.recibir_danio(1) == 0 and trompo.esta_derrotado()
		and trompo.curar(3) == 3 and trompo.curar(99) == 12
		and trompo.vida_actual == 15
		and cambios_vida == [10, 0, 3, 15]
		and cambios_derrota == [true, false]
		and trompo.obtener_actitud_hacia_jugador()
		== DefinicionPersonaje.ActitudInicialJugador.NEUTRAL,
		"Daño y curación respetan límites, derrota, señales y actitud fija."
	)
	var solicitud := SolicitudEfecto.new(
		&"prueba", &"dano", trompo, &"impacto_npc_prueba", 2.0
	)
	_comprobar(
		AplicadorEfectos.new().aplicar(solicitud) is ResultadoEfectoAplicado
		and trompo.vida_actual == 13,
		"AplicadorEfectos debe poder causar daño a un NPC."
	)

	trompo.vida_actual = 0
	trompo.nivel_actual = 4
	trompo.atributos_actuales[&"fuerza"] = 7
	EstadoPartida.trompo_conocido = true
	var persistencia := PersistenciaPartida.new()
	var snapshot := persistencia.crear_snapshot(
		tablero, &"zona1", ficha, conocimiento
	)
	var archivos := ArchivoPartida.new()
	_comprobar(archivos.guardar(RUTA, snapshot) == &"", "El archivo debe guardarse.")
	var datos_archivo: Variant = archivos.cargar(RUTA)
	if not datos_archivo is Dictionary:
		_comprobar(false, "El archivo guardado debe poder leerse.")
		zona.queue_free()
		tablero.queue_free()
		ficha.queue_free()
		_finalizar()
		return
	var copia_json: Dictionary = datos_archivo
	_comprobar(
		snapshot.get("version") == 2
		and persistencia.validar_restauracion(
			copia_json, tablero, &"zona1", ficha, conocimiento
		) == &"",
		"El estado del NPC y la memoria narrativa deben producir JSON válido."
	)

	trompo.vida_actual = 15
	trompo.nivel_actual = 3
	trompo.atributos_actuales[&"fuerza"] = 5
	EstadoPartida.trompo_conocido = false
	_comprobar(
		persistencia.restaurar(
			copia_json, tablero, &"zona1", ficha, conocimiento
		) == &"",
		"La restauración completa debe aceptar el snapshot."
	)
	_comprobar(
		trompo.esta_derrotado() and trompo.vida_actual == 0
		and trompo.nivel_actual == 4 and trompo.atributos_actuales[&"fuerza"] == 7
		and EstadoPartida.trompo_conocido,
		"PV cero, nivel, atributo y memoria narrativa deben restaurarse."
	)

	var invalido := copia_json.duplicate(true)
	invalido["memoria_narrativa"]["trompo_conocido"] = "sí"
	_comprobar(
		persistencia.restaurar(
			invalido, tablero, &"zona1", ficha, conocimiento
		) == &"memoria_narrativa_guardada_invalida"
		and trompo.vida_actual == 0 and EstadoPartida.trompo_conocido,
		"La memoria inválida debe rechazarse sin mutar la partida."
	)
	var npc_invalido := copia_json.duplicate(true)
	for datos: Dictionary in npc_invalido["interactuables"]:
		if datos["id"] == "goblin_001":
			datos["estado"]["vida_actual"] = 16
	_comprobar(
		persistencia.restaurar(
			npc_invalido, tablero, &"zona1", ficha, conocimiento
		) == &"estado_npc_guardado_invalido"
		and trompo.vida_actual == 0 and EstadoPartida.trompo_conocido,
		"PV fuera del máximo debe rechazarse sin restauración parcial."
	)

	var anterior := copia_json.duplicate(true)
	anterior["version"] = 1
	anterior.erase("memoria_narrativa")
	for datos: Dictionary in anterior["interactuables"]:
		if datos["id"] == "goblin_001":
			datos["estado"] = {}
	_comprobar(
		persistencia.restaurar(
			anterior, tablero, &"zona1", ficha, conocimiento
		) == &""
		and trompo.vida_actual == 15 and trompo.nivel_actual == 3
		and trompo.atributos_actuales[&"fuerza"] == 5
		and not EstadoPartida.trompo_conocido,
		"Un guardado v1 debe recuperar los valores iniciales del NPC y memoria falsa."
	)

	var definicion_dinamica := DefinicionPersonaje.new()
	definicion_dinamica.vida_maxima = 10
	var estado_dinamico := EstadoPersonajeNPC.new(definicion_dinamica)
	var estado_dinamico_restaurado := EstadoPersonajeNPC.new(definicion_dinamica)
	_comprobar(
		estado_dinamico.establecer_actitud_hacia_jugador(
			DefinicionPersonaje.ActitudInicialJugador.HOSTIL
		)
		and estado_dinamico.obtener_estado_persistente()["actitud_hacia_jugador"]
		== DefinicionPersonaje.ActitudInicialJugador.HOSTIL
		and estado_dinamico_restaurado.restaurar_estado_persistente(
			estado_dinamico.obtener_estado_persistente()
		) == &""
		and estado_dinamico_restaurado.obtener_actitud_hacia_jugador()
		== DefinicionPersonaje.ActitudInicialJugador.HOSTIL,
		"La actitud de un NPC dinámico debe poder cambiarse y restaurarse."
	)
	var definicion_enemigo := DefinicionPersonaje.new()
	definicion_enemigo.id_definicion = &"enemigo_prueba"
	definicion_enemigo.nombre = "Enemigo de prueba"
	definicion_enemigo.vida_maxima = 3
	definicion_enemigo.puede_combatir = true
	definicion_enemigo.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	var enemigo := (load("res://scenes/personajes/npc.tscn") as PackedScene).instantiate() as PersonajeNPC
	enemigo.definicion = definicion_enemigo
	enemigo.id_instancia = &"enemigo_prueba"
	zona.add_child(enemigo)
	_comprobar(
		tablero.registrar_interactuable(Vector2i(2, 2), enemigo),
		"El enemigo de prueba debe ocupar una celda válida."
	)
	var opcion_ataque: OpcionAccion = null
	for opcion in enemigo.obtener_opciones_accion(ficha):
		if opcion.id == &"ataque_basico":
			opcion_ataque = opcion
	_comprobar(
		opcion_ataque != null
		and not trompo.obtener_opciones_accion(ficha).any(
			func(opcion: OpcionAccion): return opcion.id == &"ataque_basico"
		),
		"Solo el NPC hostil combatiente ofrece el ataque básico."
	)
	enemigo.establecer_actitud_hacia_jugador(DefinicionPersonaje.ActitudInicialJugador.NEUTRAL)
	_comprobar(
		not enemigo.obtener_opciones_accion(ficha).any(
			func(opcion: OpcionAccion): return opcion.id == &"ataque_basico"
		),
		"Un NPC que deja de ser hostil retira la opción de ataque."
	)
	enemigo.establecer_actitud_hacia_jugador(DefinicionPersonaje.ActitudInicialJugador.HOSTIL)
	if opcion_ataque != null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1234
		enemigo.motor_dados = MotorDados.new(rng)
		ficha.fue = 5
		ficha.iniciar_turno()
		var construccion: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
			opcion_ataque, ficha, ficha.coordenada_mapa, enemigo.coordenada_mapa
		)
		_comprobar(construccion is ContextoAccion, "El ataque debe construir un contexto coherente.")
		if construccion is ContextoAccion:
			var gestor := GestorAcciones.new()
			get_tree().root.add_child(gestor)
			gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
			var contexto_lejano: Variant = ConstructorContextoAccion.new().construir_desde_opcion(
				opcion_ataque, ficha, Vector2i(2, 4), enemigo.coordenada_mapa
			)
			if contexto_lejano is ContextoAccion:
				var fuera_de_alcance := gestor.procesar_accion(contexto_lejano)
				_comprobar(
					fuera_de_alcance.motivo == &"fuera_de_alcance"
					and enemigo.vida_actual == 3
					and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1.0,
					"Un ataque fuera de alcance se bloquea sin daño ni coste."
				)
			else:
				_comprobar(false, "El ataque lejano debe construir un contexto válido.")
			var resultado := gestor.procesar_accion(construccion)
			_comprobar(
				resultado.exitosa and resultado.tirada is ResultadoPrueba
				and resultado.tirada.exitosa and enemigo.vida_actual == 2
				and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0,
				"El ataque acertado debe tirar FUE, causar 1 PV y consumir una acción."
			)
			var rng_fallo := RandomNumberGenerator.new()
			for semilla in range(1, 100):
				rng_fallo.seed = semilla
				if rng_fallo.randi_range(1, 6) == 6:
					rng_fallo.seed = semilla
					break
			enemigo.motor_dados = MotorDados.new(rng_fallo)
			ficha.iniciar_turno()
			var resultado_fallo := gestor.procesar_accion(construccion)
			_comprobar(
				resultado_fallo.exitosa and resultado_fallo.tirada is ResultadoPrueba
				and not resultado_fallo.tirada.exitosa and enemigo.vida_actual == 2
				and ficha.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0,
				"Un ataque fallido no causa daño y también consume una acción."
			)
			enemigo.recibir_danio(2)
			_comprobar(
				enemigo.esta_derrotado()
				and not enemigo.obtener_opciones_accion(ficha).any(
					func(opcion: OpcionAccion): return opcion.id == &"ataque_basico"
				),
				"Un enemigo derrotado deja de ofrecer la opción de ataque."
			)
			gestor.queue_free()

	zona.queue_free()
	tablero.queue_free()
	ficha.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	await get_tree().process_frame
	_finalizar()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)


func _finalizar() -> void:
	if _fallos.is_empty():
		print("EstadoNPCPersistente: 21 grupos correctos.")
		get_tree().quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	get_tree().quit(1)
