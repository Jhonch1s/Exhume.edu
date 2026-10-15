extends Node

const NEUTRAL := DefinicionPersonaje.ActitudInicialJugador.NEUTRAL
const AMISTOSA := DefinicionPersonaje.ActitudInicialJugador.AMISTOSA
const HOSTIL := DefinicionPersonaje.ActitudInicialJugador.HOSTIL
const RUTA := "user://prueba_actitud_npc_automatica.json"
const EscenarioSinRender := preload("res://tests/soporte/escenario_sin_render.gd")
var _fallos: Array[String] = []


func _ready() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	_probar_puntos_y_migracion()
	_probar_ataques()
	await _probar_escenario_y_dialogos()
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("ActitudNPC: puntos, migración, bloqueos, defensa, diálogos y K/C correctos.")
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _probar_puntos_y_migracion() -> void:
	var perfil := DefinicionPersonaje.new()
	perfil.vida_maxima = 15
	var estado := EstadoPersonajeNPC.new(perfil)
	var otro := EstadoPersonajeNPC.new(perfil)
	for paso in [[-2, -2, NEUTRAL], [-1, -3, HOSTIL], [1, -2, NEUTRAL], [5, 3, AMISTOSA], [-1, 2, NEUTRAL], [100, 10, AMISTOSA], [-100, -10, HOSTIL]]:
		estado.modificar_actitud_hacia_jugador(paso[0])
		_comprobar(estado.obtener_puntos_actitud() == paso[1] and estado.obtener_actitud_hacia_jugador() == paso[2], "Transición o límite incorrecto: %s." % [paso])
	_comprobar(otro.obtener_puntos_actitud() == 0 and perfil.actitud_inicial_jugador == NEUTRAL, "La relación pertenece a la instancia, no a la definición.")
	for inicial in [[NEUTRAL, 0], [AMISTOSA, 3], [HOSTIL, -3]]:
		perfil.actitud_inicial_jugador = inicial[0]
		var nuevo := EstadoPersonajeNPC.new(perfil)
		_comprobar(nuevo.obtener_puntos_actitud() == inicial[1], "Inicializar debe respetar la definición.")
		var antiguo := nuevo.obtener_estado_persistente()
		antiguo.erase("puntos_actitud")
		_comprobar(otro.restaurar_estado_persistente(antiguo) == &"" and otro.obtener_puntos_actitud() == inicial[1], "Un snapshot anterior debe migrar la actitud guardada.")
	var datos := estado.obtener_estado_persistente()
	var json: Dictionary = JSON.parse_string(JSON.stringify(datos))
	_comprobar(otro.restaurar_estado_persistente(json) == &"" and otro.obtener_puntos_actitud() == -10, "Los puntos deben conservarse en un roundtrip JSON.")
	for invalido in [11, -11, 1.5, true, "0", null, 0]:
		var corrupto := datos.duplicate(true)
		corrupto["puntos_actitud"] = invalido
		_comprobar(otro.restaurar_estado_persistente(corrupto) != &"" and otro.obtener_puntos_actitud() == -10, "Rechazar puntos inválidos o incoherentes sin mutar: %s." % str(invalido))
	perfil.actitud_inicial_jugador = NEUTRAL
	perfil.actitud_hacia_jugador_fija = true
	var fijo := EstadoPersonajeNPC.new(perfil)
	_comprobar(fijo.modificar_actitud_hacia_jugador(-20) == 0 and not fijo.establecer_actitud_hacia_jugador(HOSTIL) and fijo.obtener_actitud_hacia_jugador() == NEUTRAL, "La actitud fija debe rechazar cambios.")
	_comprobar(not fijo.obtener_estado_persistente().has("puntos_actitud") and fijo.validar_estado_persistente(datos) != &"", "La relación fija procede exclusivamente de la definición.")


func _probar_ataques() -> void:
	var ficha := Ficha.new()
	ficha.fue = 3
	ficha.des = 3
	add_child(ficha)
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"actitud_ataques"
	perfil.vida_maxima = 15
	perfil.fuerza = 3
	perfil.destreza = 3
	perfil.puede_combatir = true
	var npc := load("res://scenes/personajes/npc.tscn").instantiate() as PersonajeNPC
	npc.id_instancia = &"actitud_ataques"
	npc.definicion = perfil
	npc.coordenada_mapa = Vector2i(1, 0)
	add_child(npc)
	var gestor := GestorAcciones.new()
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	add_child(gestor)
	var opcion: OpcionAccion
	for candidata in npc.obtener_opciones_accion(ficha):
		if candidata.id == &"ataque_basico":
			opcion = candidata
	_comprobar(opcion != null, "Un neutral combatiente debe ofrecer Atacar.")
	if opcion == null:
		return
	var inicial := npc.obtener_estado_persistente()
	for dados in [[6], [2, 2], [2, 6]]:
		npc.restaurar_estado_persistente(inicial)
		npc.en_oposicion_encuentro = false
		ficha.iniciar_turno()
		var rng := _rng_para(dados)
		npc.motor_dados = MotorDados.new(rng)
		var contexto := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, Vector2i.ZERO, npc.coordenada_mapa) as ContextoAccion
		var resultado := gestor.procesar_accion(contexto)
		_comprobar(resultado.exitosa and npc.obtener_puntos_actitud() == -2 and npc.obtener_actitud_hacia_jugador() == NEUTRAL, "Fallado, esquivado y acertado deben penalizar una vez.")
		_comprobar(npc.en_oposicion_encuentro, "El neutral debe entrar en oposición.")
		var respuesta := AccionAtaqueNPC.new(ficha)
		_comprobar(respuesta.validar_accion(respuesta.construir_contexto(npc)) == &"", "La defensa neutral debe admitir el ataque NPC.")
		var estado_rng := rng.state
		_comprobar(gestor.procesar_accion(contexto).estado == TiposInteraccion.EstadoResolucion.BLOQUEO and npc.obtener_puntos_actitud() == -2 and rng.state == estado_rng, "Una acción agotada no repite tiradas ni relación.")
		var restaurado := npc.obtener_estado_persistente()
		npc.modificar_actitud_hacia_jugador(-2)
		_comprobar(npc.obtener_actitud_hacia_jugador() == HOSTIL, "La segunda agresión cruza a hostil.")
		_comprobar(npc.restaurar_estado_persistente(restaurado) == &"" and npc.obtener_puntos_actitud() == -2, "Restaurar no repite agresiones.")
	perfil.actitud_hacia_jugador_fija = true
	ficha.iniciar_turno()
	npc.motor_dados = MotorDados.new(_rng_para([6]))
	var contexto_fijo := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, Vector2i.ZERO, npc.coordenada_mapa) as ContextoAccion
	_comprobar(gestor.procesar_accion(contexto_fijo).exitosa and npc.obtener_actitud_hacia_jugador() == NEUTRAL and npc.en_oposicion_encuentro, "El fijo combatiente se defiende sin cambiar relación.")
	npc.en_oposicion_encuentro = false
	var sin_encuentro := AccionAtaqueNPC.new(ficha)
	_comprobar(sin_encuentro.validar_accion(sin_encuentro.construir_contexto(npc)) == &"npc_no_hostil", "El neutral fuera de encuentro no ataca al jugador.")
	ficha.queue_free()
	npc.queue_free()
	gestor.queue_free()


func _probar_escenario_y_dialogos() -> void:
	var escena: Node2D = load("res://tests/interacciones/escena_actitud_npc.tscn").instantiate()
	var escenario: Node2D = escena.get_node("Escenario")
	escenario.set_script(EscenarioSinRender)
	add_child(escena)
	var npc: PersonajeNPC
	for _intento in range(200):
		await get_tree().create_timer(0.02).timeout
		npc = escenario.tablero.obtener_interactuable(&"npc_hostil_prueba_001") as PersonajeNPC
		if npc != null and escena.get("_enemigos").size() == 3:
			break
	if npc == null:
		_comprobar(false, "La escena manual debe iniciar.")
		return
	escenario.set_process(false)
	var fijo := escenario.tablero.obtener_interactuable(&"npc_hostil_prueba_002") as PersonajeNPC
	var trompo := escenario.tablero.obtener_interactuable(&"npc_hostil_prueba_003") as PersonajeNPC
	var ficha: Ficha = escenario.ficha_jugador
	var opcion: OpcionAccion
	for candidata in npc.obtener_opciones_accion(ficha):
		if candidata.id == &"ataque_basico":
			opcion = candidata
	var lejano := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, ficha.coordenada_mapa, npc.coordenada_mapa) as ContextoAccion
	_comprobar(escenario._procesar_accion_contextual(lejano).motivo == &"fuera_de_alcance" and not escenario.en_combate and not npc.en_oposicion_encuentro and npc.obtener_puntos_actitud() == 0, "Un ataque fuera de alcance no abre defensa.")
	ficha.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	_comprobar(escenario._procesar_accion_contextual(lejano).motivo == &"recursos_turno_insuficientes" and not escenario.en_combate and not npc.en_oposicion_encuentro, "Sin recursos no se inicia encuentro.")
	ficha.iniciar_turno()
	var dialogos := get_tree().root.get_node("DialogueManager")
	var recurso := load("res://dialogues/personajes/prueba_actitud.dialogue") as DialogueResource
	await dialogos.get_next_dialogue_line(recurso, "mejorar", [npc, escenario.ficha_jugador])
	_comprobar(npc.obtener_puntos_actitud() == 1, "Dialogue Manager debe llamar la operación compartida.")
	await dialogos.get_next_dialogue_line(recurso, "empeorar", [npc, escenario.ficha_jugador])
	_comprobar(npc.obtener_puntos_actitud() == 0, "El diálogo negativo debe empeorar relación.")
	await dialogos.get_next_dialogue_line(recurso, "empeorar", [trompo, escenario.ficha_jugador])
	_comprobar(trompo.obtener_puntos_actitud() == 0 and not trompo.obtener_definicion_personaje().puede_combatir, "El diálogo no cambia la excepción de Trompo.")
	npc.obtener_definicion_personaje().radio_agro = 20
	_comprobar(not npc.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial), "El neutral no inicia agro antes de la agresión.")
	_comprobar(escenario._iniciar_combate(npc) and npc.en_oposicion_encuentro and not fijo.en_oposicion_encuentro, "La oposición sólo pertenece a los participantes.")
	_comprobar(npc.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial), "El defensor neutral debe detectar durante el encuentro.")
	npc.modificar_actitud_hacia_jugador(-2)
	npc.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	var orden: Dictionary = escenario.gestor_rondas.obtener_estado_persistente()
	_comprobar(escenario.guardar_partida(RUTA) == &"", "Guardar debe conservar un defensor neutral.")
	npc.modificar_actitud_hacia_jugador(5)
	_comprobar(npc.en_oposicion_encuentro, "Mejorar relación no cancela el encuentro.")
	for _carga in range(2):
		_comprobar(escenario.cargar_partida(RUTA) == &"", "Cargar debe restaurar el encuentro neutral.")
		_comprobar(npc.obtener_puntos_actitud() == -2 and npc.en_oposicion_encuentro and npc.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0 and escenario.gestor_rondas.obtener_estado_persistente() == orden, "Cargar no repite penalizaciones, turnos ni iniciativa.")
	escenario._terminar_combate(false, true)
	_comprobar(not npc.en_oposicion_encuentro and npc.obtener_ultima_posicion_conocida() == null and not npc.puede_detectar_jugador(escenario.ficha_jugador, escenario.validador_espacial), "Terminar elimina defensa y persecución del no hostil.")
	_comprobar(escenario.guardar_partida(RUTA) == &"", "Guardar exploración debe conservar relación.")
	escenario._iniciar_combate(fijo)
	npc.modificar_actitud_hacia_jugador(-2)
	_comprobar(escenario.cargar_partida(RUTA) == &"" and not npc.en_oposicion_encuentro and not fijo.en_oposicion_encuentro and npc.obtener_puntos_actitud() == -2 and not escenario.en_combate, "Cargar exploración limpia oposición de otro encuentro.")
	var snapshot: Dictionary = escenario.persistencia_partida.crear_snapshot(escenario.tablero, &"zona1", escenario.ficha_jugador, escenario.registro_conocimiento)
	for entrada in snapshot["interactuables"]:
		if entrada["id"] == String(npc.id_instancia):
			entrada["estado"]["puntos_actitud"] = 99
	var vida: int = escenario.ficha_jugador.pv_actual
	_comprobar(escenario.persistencia_partida.restaurar(snapshot, escenario.tablero, &"zona1", escenario.ficha_jugador, escenario.registro_conocimiento) != &"" and npc.obtener_puntos_actitud() == -2 and escenario.ficha_jugador.pv_actual == vida, "Un guardado corrupto debe rechazarse antes de mutar.")
	# Ejecutar el árbol y el turno reales del neutral, ya junto al jugador.
	var vecino: Variant = null
	for direccion in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var candidata: Vector2i = npc.coordenada_mapa + direccion
		if escenario.tablero.puede_entrar(candidata, ficha) and npc.puede_ver_coordenada(candidata, escenario.validador_espacial):
			vecino = candidata
			break
	_comprobar(vecino != null, "Debe haber una casilla adyacente para comprobar defensa real.")
	if vecino != null:
		escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
		ficha.inicializar(vecino, escenario.tablero.capa_referencia)
		escenario.tablero.ocupar_celda(vecino, ficha)
		npc.establecer_actitud_hacia_jugador(NEUTRAL)
		ficha.iniciar_turno()
		var respuestas: Array[ResultadoAccion] = []
		escenario.gestor_acciones.accion_finalizada.connect(func(contexto: ContextoAccion, resultado: ResultadoAccion):
			if contexto.id_accion == &"ataque_basico_npc":
				respuestas.append(resultado)
		)
		var cercano := ConstructorContextoAccion.new().construir_desde_opcion(opcion, ficha, ficha.coordenada_mapa, npc.coordenada_mapa) as ContextoAccion
		var intento: ResultadoAccion = escenario._procesar_accion_contextual(cercano)
		_comprobar(intento.exitosa and escenario.en_combate and npc.obtener_actitud_hacia_jugador() == NEUTRAL, "Una orden válida activa defensa conservando neutralidad.")
		escenario.ejecutar_turnos = true
		if escenario._es_turno_jugador():
			escenario._finalizar_turno_combate()
		else:
			escenario._programar_turno_npc()
		for _espera in range(60):
			await get_tree().create_timer(0.05).timeout
			if not respuestas.is_empty():
				break
		_comprobar(not respuestas.is_empty() and respuestas[0].tirada != null and respuestas[0].exitosa and npc.obtener_actitud_hacia_jugador() == NEUTRAL, "El árbol real debe ejecutar defensa de un neutral en su turno.")
		escenario._terminar_combate(false)
	escena.queue_free()
	await get_tree().process_frame


func _rng_para(dados: Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	for semilla in range(1, 10000):
		rng.seed = semilla
		var coincide := true
		for dado in dados:
			if rng.randi_range(1, 6) != dado:
				coincide = false
				break
		if coincide:
			rng.seed = semilla
			return rng
	assert(false, "No hay semilla para el caso de prueba.")
	return rng


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
