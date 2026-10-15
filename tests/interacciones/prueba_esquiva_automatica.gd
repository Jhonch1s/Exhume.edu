extends Node

var _fallos: Array[String] = []
var _ficha: Ficha
var _npc: PersonajeNPC
var _gestor: GestorAcciones
var _escenario: Node2D
var _opcion: OpcionAccion
var _casos: int = 0
var _estado_npc_inicial: Dictionary


func _ready() -> void:
	_ficha = Ficha.new()
	_ficha.fue = 3
	_ficha.des = 3
	add_child(_ficha)
	_ficha.texturas_por_direccion[0] = load("res://icon.svg")
	_ficha._aplicar_visual_clase()
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"enemigo_esquiva"
	perfil.nombre = "Enemigo de prueba"
	perfil.vida_maxima = 4
	perfil.fuerza = 3
	perfil.destreza = 3
	perfil.puede_combatir = true
	perfil.actitud_inicial_jugador = DefinicionPersonaje.ActitudInicialJugador.HOSTIL
	_npc = load("res://scenes/personajes/npc.tscn").instantiate() as PersonajeNPC
	_npc.definicion = perfil
	_npc.id_instancia = &"enemigo_esquiva"
	_npc.coordenada_mapa = Vector2i(1, 0)
	add_child(_npc)
	_estado_npc_inicial = _npc.obtener_estado_persistente()
	for opcion in _npc.obtener_opciones_accion(_ficha):
		if opcion.id == &"ataque_basico":
			_opcion = opcion
	_gestor = GestorAcciones.new()
	_gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	add_child(_gestor)
	_escenario = load("res://scenes/escenario_base/escenario_base.gd").new()
	_escenario.add_child(_escenario.tablero)
	_escenario.add_child(_escenario.pathfinding)
	_escenario.add_child(_escenario.gestor_acciones)
	_escenario.ficha_jugador = _ficha
	_escenario.catalogo_mensajes = load("res://assets/interactuables/mensajes_interacciones.tres")
	for jugador in [true, false]:
		for dados in [[2, 2], [2, 5], [1, 1], [1, 6], [6], [4], [3, 3]]:
			_probar_intercambio(jugador, dados)
		_probar_bloqueos(jugador)
	_escenario.free()
	_ficha.queue_free()
	_npc.queue_free()
	_gestor.queue_free()
	await get_tree().process_frame
	for fallo in _fallos:
		push_error(fallo)
	if _fallos.is_empty():
		print("EsquivaAutomatica: %d casos correctos para jugador y NPC." % _casos)
	get_tree().call_deferred(&"quit", 0 if _fallos.is_empty() else 1)


func _reiniciar() -> void:
	_ficha.pv_actual = _ficha.pv_max
	_ficha.des = 3
	_ficha.iniciar_turno()
	_npc.restaurar_estado_persistente(_estado_npc_inicial)
	_npc.atributos_actuales[&"destreza"] = 3
	_npc.coordenada_mapa = Vector2i(1, 0)
	_npc.iniciar_turno()


func _contexto(jugador: bool, motor: MotorDados) -> ContextoAccion:
	if jugador:
		_npc.motor_dados = motor
		return ConstructorContextoAccion.new().construir_desde_opcion(
			_opcion, _ficha, _ficha.coordenada_mapa, _npc.coordenada_mapa
		) as ContextoAccion
	var accion := AccionAtaqueNPC.new(_ficha)
	accion.motor_dados = motor
	return accion.construir_contexto(_npc)


func _semilla_para(dados: Array) -> int:
	var rng := RandomNumberGenerator.new()
	for semilla in range(1, 10000):
		rng.seed = semilla
		var coincide := true
		for dado in dados:
			if rng.randi_range(1, 6) != dado:
				coincide = false
				break
		if coincide:
			return semilla
	assert(false, "No se encontró una semilla para la secuencia de prueba.")
	return -1


func _probar_intercambio(jugador: bool, dados: Array) -> void:
	_reiniciar()
	var atacante: Object = _ficha if jugador else _npc
	var defensor: Object = _npc if jugador else _ficha
	defensor.consumir_recurso_turno(RecursosTurnoActor.REACCION, 1)
	var vida_antes: int = _npc.vida_actual if jugador else _ficha.pv_actual
	var rng := RandomNumberGenerator.new()
	var semilla := _semilla_para(dados)
	rng.seed = semilla
	for _dado in dados:
		rng.randi_range(1, 6)
	var estado_esperado := rng.state
	rng.seed = semilla
	var contexto := _contexto(jugador, MotorDados.new(rng))
	var resultado := _gestor.procesar_accion(contexto)
	var acierto: bool = dados[0] <= 3
	var esquivado: bool = acierto and dados[1] <= 3
	var vida_despues: int = _npc.vida_actual if jugador else _ficha.pv_actual
	_comprobar(resultado.exitosa and resultado.tirada.dado_seleccionado == dados[0], "El ataque debe conservar su tirada de FUE.")
	_comprobar(rng.state == estado_esperado, "Debe tirar DES sólo tras acertar y una sola vez.")
	_comprobar(vida_despues == vida_antes - int(acierto and not esquivado), "Sólo un acierto no esquivado debe causar daño.")
	_comprobar(atacante.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "Atacar debe gastar acción aunque falle o se esquive.")
	_comprobar(defensor.obtener_recurso_turno(RecursosTurnoActor.REACCION) == 0 and defensor.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1, "Esquivar con reacción agotada no debe gastar ni reponer recursos.")
	if acierto:
		_comprobar(
			resultado.tirada_defensa != null and resultado.tirada_defensa.dado_seleccionado == dados[1]
			and resultado.tirada_defensa.atributo == 3 and resultado.tirada_defensa.exitosa == esquivado
			and resultado.tirada_defensa.origen == TiposTirada.Origen.AUTOMATICA
			and resultado.tirada_defensa.presentacion == TiposTirada.Presentacion.SOLO_LOG,
			"La esquiva debe ser una prueba automática de DES, incluso ante un crítico."
		)
		_comprobar(resultado.con_tirada(resultado.tirada).tirada_defensa == resultado.tirada_defensa, "Copiar una tirada no debe perder la defensa.")
	else:
		_comprobar(resultado.tirada_defensa == null, "Un ataque fallido no debe provocar esquiva.")
	_escenario.registro_narrativo.limpiar()
	_escenario._registrar_resultado_narrativo("Ataque", resultado, EntradaRegistroNarrativo.Categoria.DANO, "FUE")
	var entrada: EntradaRegistroNarrativo = _escenario.registro_narrativo.obtener_entradas_visibles()[0]
	_comprobar(entrada.detalles.size() == (2 if acierto else 1), "El registro debe mostrar FUE y, si corresponde, DES.")
	if esquivado:
		_comprobar("esquiv" in entrada.mensaje.to_lower() and resultado.efectos_aplicados.is_empty(), "Una esquiva debe explicarse sin mostrar daño.")
	elif acierto:
		_comprobar(("Infliges" if jugador else "Recibes") in entrada.mensaje, "El mensaje de daño debe distinguir quién lo recibe.")
	var estado_antes_repetir := rng.state
	var repetido := _gestor.procesar_accion(contexto)
	_comprobar(repetido.motivo == &"recursos_turno_insuficientes" and rng.state == estado_antes_repetir, "Una acción gastada no permite repetir el ataque ni su esquiva.")
	_casos += 1


func _probar_bloqueos(jugador: bool) -> void:
	for bloqueo in ["destreza", "alcance", "derrota"]:
		_reiniciar()
		if bloqueo == "destreza":
			if jugador:
				_npc.atributos_actuales[&"destreza"] = 0
			else:
				_ficha.des = 0
		elif bloqueo == "alcance":
			_npc.coordenada_mapa = Vector2i(3, 0)
		elif jugador:
			_npc.vida_actual = 0
		else:
			_ficha.pv_actual = 0
		var rng := RandomNumberGenerator.new()
		rng.seed = 100
		var estado_rng := rng.state
		var resultado := _gestor.procesar_accion(_contexto(jugador, MotorDados.new(rng)))
		var atacante: Object = _ficha if jugador else _npc
		_comprobar(
			resultado.estado == TiposInteraccion.EstadoResolucion.BLOQUEO
			and rng.state == estado_rng and resultado.tirada == null and resultado.tirada_defensa == null
			and atacante.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1,
			"Un bloqueo por %s debe conservar dados y recursos." % bloqueo
		)
		_casos += 1


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
