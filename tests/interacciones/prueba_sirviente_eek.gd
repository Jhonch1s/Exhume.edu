extends SceneTree

var _fallos: Array[String] = []
var _casos := 0
var tablero: TableroGrid
var gestor: GestorAcciones
var servicio: ServicioTurnos
var encuentro: GestorRondas
var eek: PersonajeNPC
var victima: PersonajeNPC
var buscador: PathFindingManager
var decisor: DecisorCombateNPC


func _init() -> void:
	call_deferred(&"_ejecutar")


func _ejecutar() -> void:
	tablero = TableroGrid.new()
	gestor = GestorAcciones.new()
	buscador = PathFindingManager.new()
	root.add_child(tablero)
	root.add_child(gestor)
	root.add_child(buscador)
	for x in range(-5, 6):
		for y in range(-5, 6):
			tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	gestor.configurar_validador_espacial(ValidadorEspacialTablero.new(tablero))
	gestor.configurar_proveedor_costes(ProveedorCostesFicha.new())
	servicio = ServicioTurnos.new(gestor)
	eek = load("res://scenes/personajes/sirviente_eek.tscn").instantiate()
	eek.id_instancia = &"eek_prueba"
	root.add_child(eek)
	_comprobar(tablero.registrar_interactuable(Vector2i.ZERO, eek), "Registrar prefab real.")
	var perfil := DefinicionPersonaje.new()
	perfil.id_definicion = &"victima_eek"
	perfil.vida_maxima = 99
	perfil.fuerza = 3
	perfil.destreza = 3
	perfil.voluntad = 3
	perfil.puede_combatir = true
	perfil.acciones_principales_por_turno = 3
	victima = PersonajeNPC.new()
	victima.definicion = perfil
	victima.id_instancia = &"victima"
	root.add_child(victima)
	_comprobar(tablero.registrar_interactuable(Vector2i(1, 0), victima), "Registrar víctima.")
	encuentro = GestorRondas.new(servicio)
	_comprobar(encuentro.iniciar([eek, victima]).exitoso, "Iniciar rondas reales.")
	encuentro.bandos[eek.id_instancia] = GestorRondas.Bando.OPONENTE
	encuentro.bandos[victima.id_instancia] = GestorRondas.Bando.JUGADOR
	buscador.inicializar(tablero.datos)
	decisor = DecisorCombateNPC.new()
	decisor.set_scene_root_hint(root)
	root.add_child(decisor)
	_probar_mordida_y_telarana()
	_probar_limites_y_rechazos()
	_probar_duracion_y_liberacion()
	_probar_ia()
	await _probar_ficha_y_persistencia()
	await _probar_escenario_real()
	root.remove_child(decisor)
	decisor.free()
	for nodo in [eek, victima, tablero, gestor, buscador]:
		nodo.queue_free()
	await process_frame
	for fallo in _fallos:
		push_error(fallo)
	print("SirvienteEek: %d comprobaciones, %d fallos." % [_casos, _fallos.size()])
	quit(0 if _fallos.is_empty() else 1)


func _reiniciar(distancia: int = 1) -> void:
	eek.estado_personaje = null
	victima.estado_personaje = null
	tablero.reubicar_interactuable(eek, Vector2i.ZERO)
	tablero.reubicar_interactuable(victima, Vector2i(distancia, 0))
	eek.iniciar_turno()
	victima.iniciar_turno()


func _motor(semilla: int) -> MotorDados:
	var generador := RandomNumberGenerator.new()
	generador.seed = semilla
	return MotorDados.new(generador)


func _habilidad(id: StringName, semilla: int = 0) -> ResultadoAccion:
	var accion := AccionSirvienteEek.new(victima, encuentro)
	accion.motor_dados = _motor(semilla)
	return gestor.procesar_accion(accion.construir_contexto(eek, id))


func _probar_mordida_y_telarana() -> void:
	var danos := {}
	var duraciones := {}
	for semilla in 80:
		_reiniciar()
		eek.atributos_actuales[&"fuerza"] = 5
		var resultado := _habilidad(AccionSirvienteEek.MORDIDA, semilla)
		_comprobar(resultado.exitosa and resultado.tirada.atributo == 3 and resultado.tirada_defensa == null, "Mordida: solo prueba de FUE de la víctima.")
		_comprobar(eek.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "Mordida paga acción, también al resistir.")
		if resultado.tirada.exitosa:
			_comprobar(victima.vida_actual == 99 and resultado.tirada_dano == null, "Resistir no tira daño.")
		else:
			var dano := resultado.tirada_dano.total_efectivo + 3
			danos[dano] = true
			_comprobar(99 - victima.vida_actual == dano and dano >= 4 and dano <= 9, "Mordida aplica 1d6+3 exacto, sin bono de atacante.")
		_comprobar(victima.obtener_estado(&"veneno") == null, "Mordida no inventa veneno periódico.")
		_reiniciar(3)
		resultado = _habilidad(AccionSirvienteEek.TELARANA, semilla)
		_comprobar(resultado.exitosa and resultado.tirada.atributo == 3 and resultado.tirada_dano == null, "Telaraña: DES sin daño.")
		_comprobar(eek.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "Telaraña paga acción al intentar.")
		if resultado.tirada.exitosa:
			_comprobar(victima.puede_moverse() and resultado.tirada_duracion == null, "Evitar no tira duración.")
		else:
			var duracion := resultado.tirada_duracion.total_efectivo
			duraciones[duracion] = true
			_comprobar(not victima.puede_moverse() and victima.puede_actuar(), "Inmovilizado sigue vivo y puede actuar.")
			_comprobar(victima.obtener_estado(&"inmovilizado").ticks_pendientes == duracion, "Duración resuelta conservada después del cobro.")
	_comprobar(danos.has(4) and danos.has(9), "Cubrir extremos reales de 1d6+3.")
	_comprobar(duraciones.size() == 3, "Cubrir duraciones 1, 2 y 3.")


func _probar_limites_y_rechazos() -> void:
	_reiniciar(4)
	var resultado := _habilidad(AccionSirvienteEek.TELARANA)
	_comprobar(resultado.motivo == &"fuera_de_alcance" and resultado.tirada == null, "Bloquear telaraña a 4 casillas sin tirar.")
	_comprobar(eek.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 1, "Bloqueo conserva acción.")
	_reiniciar(3)
	tablero.obtener_celda(Vector2i(1, 0)).altura = 2
	resultado = _habilidad(AccionSirvienteEek.TELARANA)
	_comprobar(resultado.motivo == &"linea_de_efecto_bloqueada" and resultado.tirada == null, "Bloqueo físico aunque se permita visión.")
	tablero.obtener_celda(Vector2i(1, 0)).altura = 0
	encuentro.bandos[victima.id_instancia] = GestorRondas.Bando.OPONENTE
	_comprobar(_habilidad(AccionSirvienteEek.TELARANA).motivo == &"npc_no_hostil", "Respetar bandos.")
	encuentro.bandos[victima.id_instancia] = GestorRondas.Bando.JUGADOR
	_reiniciar(2)
	_comprobar(_habilidad(AccionSirvienteEek.MORDIDA).motivo == &"fuera_de_alcance", "Mordida exige adyacencia.")
	tablero.reubicar_interactuable(victima, Vector2i(3, 3))
	_comprobar(_habilidad(AccionSirvienteEek.TELARANA).exitosa, "Alcance de cuadrícula coherente con otras habilidades a distancia.")
	_comprobar(AplicadorEfectos.new().validar(SolicitudEfecto.new(&"inmovilizado", &"estado", victima, &"invalido", 1, 4)) != &"", "Rechazar duración fuera del perfil 1d3.")


func _probar_duracion_y_liberacion() -> void:
	for duracion in range(1, 4):
		_reiniciar()
		victima.aplicar_o_renovar_estado(&"inmovilizado", 1, duracion, duracion)
		servicio.avanzar_turno(eek)
		_comprobar(victima.obtener_estado(&"inmovilizado").ticks_pendientes == duracion, "El turno ajeno no consume inmovilización.")
		for restante in range(duracion - 1, -1, -1):
			var vida := victima.vida_actual
			var fin := servicio.avanzar_turno(victima)
			_comprobar(fin.exitosa and victima.vida_actual == vida and fin.efectos_aplicados.is_empty(), "Inmovilización expira sin causar daño.")
			_comprobar(victima.puede_moverse() == (restante == 0), "Bloquear exactamente N turnos propios.")
	_reiniciar()
	victima.aplicar_o_renovar_estado(&"inmovilizado", 1, 3, 3)
	victima.aplicar_o_renovar_estado(&"inmovilizado", 1, 1, 1)
	_comprobar(victima.obtener_estado(&"inmovilizado").ticks_pendientes == 3, "Renovar usa máximo, no suma ni reduce duración.")
	var accion := AccionDestrabarse.new()
	for semilla in 100:
		accion.motor_dados = _motor(semilla)
		var prueba := _motor(semilla).resolver_prueba(3)
		if not prueba.exitosa:
			break
	var intento := gestor.procesar_accion(accion.construir_contexto(victima))
	_comprobar(intento.exitosa and not intento.tirada.exitosa and victima.liberacion_telarana_intentada, "Registrar intento fallido.")
	var restante := victima.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL)
	var segundo := gestor.procesar_accion(accion.construir_contexto(victima))
	_comprobar(segundo.motivo == &"liberacion_telarana_ya_intentada" and segundo.tirada == null and restante == 2, "Una vez por turno aunque tenga varias acciones.")
	_comprobar(victima.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == restante, "Segundo intento bloqueado no cobra.")
	var guardado: Dictionary = JSON.parse_string(JSON.stringify(victima.obtener_estado_persistente()))
	_comprobar(victima.validar_estado_persistente(guardado) == &"", "Validar JSON con intento y duración.")
	victima.liberacion_telarana_intentada = false
	_comprobar(victima.restaurar_estado_persistente(guardado) == &"" and victima.liberacion_telarana_intentada, "Carga no permite reintento.")
	victima.iniciar_turno()
	_comprobar(gestor.procesar_accion(accion.construir_contexto(victima)).motivo == &"liberacion_telarana_ya_intentada", "Reponer recursos no borra intento lógico.")
	servicio.avanzar_turno(victima)
	_comprobar(not victima.liberacion_telarana_intentada, "El cierre propio habilita el siguiente intento.")
	for semilla in 100:
		if _motor(semilla).resolver_prueba(3).exitosa:
			accion.motor_dados = _motor(semilla)
			break
	intento = gestor.procesar_accion(accion.construir_contexto(victima))
	_comprobar(intento.tirada.exitosa and victima.puede_moverse(), "Liberación exitosa retira estado.")
	victima.aplicar_o_renovar_estado(&"inmovilizado", 1, 3, 3)
	_comprobar(gestor.procesar_accion(accion.construir_contexto(victima)).motivo == &"liberacion_telarana_ya_intentada", "Reaplicar en el mismo turno no concede otro intento.")
	victima.retirar_estado(&"inmovilizado")
	victima.aplicar_o_renovar_estado(&"enredado", 1, 1, 0)
	_comprobar(servicio.avanzar_turno(victima).exitosa and victima.obtener_estado(&"enredado") != null, "Telaraña ambiental conserva duración indefinida.")


func _probar_ia() -> void:
	_reiniciar(3)
	var visibles: Array[Object] = [victima]
	_comprobar(decisor.elegir(eek, tablero, buscador, visibles)["decision"] == AccionSirvienteEek.TELARANA, "IA lanza hasta 3 a objetivo móvil.")
	victima.aplicar_o_renovar_estado(&"inmovilizado", 1, 3, 3)
	_comprobar(decisor.elegir(eek, tablero, buscador, visibles)["decision"] == &"acercarse", "IA se acerca a presa ya atrapada sin renovar control.")
	tablero.reubicar_interactuable(victima, Vector2i(1, 0))
	_comprobar(decisor.elegir(eek, tablero, buscador, visibles)["decision"] == AccionSirvienteEek.MORDIDA, "IA muerde a presa atrapada adyacente.")
	eek.consumir_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL, 1)
	var plan := decisor.elegir(eek, tablero, buscador, visibles)
	_comprobar(plan["decision"] == &"retirarse" and plan["camino"].size() == 2, "Tras actuar se separa un paso pagable.")
	_comprobar(decisor.elegir(eek, tablero, buscador)["objetivo"] == null, "No atacar a quien no ve.")
	eek.aplicar_o_renovar_estado(&"inmovilizado", 1, 2, 2)
	_comprobar(decisor.elegir(eek, tablero, buscador, visibles)["decision"] == &"liberarse", "NPC atrapado prioriza liberarse.")


func _probar_ficha_y_persistencia() -> void:
	var ficha := load("res://scenes/ficha/ficha.tscn").instantiate() as Ficha
	root.add_child(ficha)
	ficha.texturas_por_direccion[0] = ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	ficha.aplicar_o_renovar_estado(&"inmovilizado", 1, 3, 3)
	ficha.liberacion_telarana_intentada = true
	var datos: Dictionary = JSON.parse_string(JSON.stringify(ficha.obtener_estado_persistente()))
	_comprobar(ficha.validar_estado_persistente(datos) == &"", "Validar ficha real con inmovilización e intento.")
	ficha.retirar_estado(&"inmovilizado")
	ficha.liberacion_telarana_intentada = false
	_comprobar(ficha.restaurar_estado_persistente(datos) == &"" and not ficha.puede_moverse() and ficha.liberacion_telarana_intentada, "Restaurar ficha sin ticks ni intentos nuevos.")
	datos["liberacion_telarana_intentada"] = "sí"
	_comprobar(ficha.validar_estado_persistente(datos) != &"", "Rechazar intento corrupto antes de mutar.")
	datos.erase("liberacion_telarana_intentada")
	_comprobar(ficha.restaurar_estado_persistente(datos) == &"" and not ficha.liberacion_telarana_intentada, "Compatibilidad con guardados sin campo nuevo.")
	ficha.queue_free()
	await process_frame


func _probar_escenario_real() -> void:
	var escena: Node2D = load("res://tests/interacciones/escena_sirviente_eek.tscn").instantiate()
	var escenario: Node2D = escena.get_node("Escenario")
	escenario.set_script(load("res://tests/interacciones/prueba_actitud_npc.gd").EscenarioSinRender)
	root.add_child(escena)
	for _intento in 200:
		await create_timer(0.02).timeout
		if escena.get("_enemigos").size() == 1:
			break
	_comprobar(escena.get("_enemigos").size() == 1, "La escena F6 prepara al sirviente real.")
	if escena.get("_enemigos").is_empty():
		escena.queue_free()
		return
	escenario.set_process(false)
	escenario._terminar_combate(false)
	var arana: PersonajeNPC = escena.get("_enemigos")[0]
	var ficha: Ficha = escenario.ficha_jugador
	var suelo := escenario.get_node("Zona/CapaSuelo") as TileMapLayer
	for x in range(95, 106):
		for y in range(95, 106):
			escenario.tablero.datos[Vector2i(x, y)] = Celda.new(&"piso_vacio", true, 0, Celda.EstadoVisibilidad.VISIBLE)
	escenario.tablero.liberar_celda(ficha.coordenada_mapa, ficha)
	ficha.coordenada_mapa = Vector2i(100, 100)
	escenario.tablero.ocupar_celda(ficha.coordenada_mapa, ficha)
	ficha.global_position = suelo.to_global(suelo.map_to_local(ficha.coordenada_mapa))
	ficha.fue = 3
	ficha.des = 3
	ficha.vol = 3
	ficha.pv_max = 9
	ficha.pv_actual = 9
	escenario.tablero.reubicar_interactuable(arana, Vector2i(103, 100))
	arana.global_position = suelo.to_global(suelo.map_to_local(arana.coordenada_mapa))
	escenario.pathfinding.inicializar(escenario.tablero.datos)
	_comprobar(escenario._iniciar_combate(arana, false), "Iniciar combate de escenario con la criatura.")
	_activar_arana(escenario, arana)
	var conteo := {"telarana": 0, "mordida": 0}
	var controlar := func(contexto: ContextoAccion) -> void:
		if contexto.objetivo is AccionSirvienteEek:
			conteo["telarana" if contexto.id_accion == AccionSirvienteEek.TELARANA else "mordida"] += 1
			for semilla in 100:
				var motor := _motor(semilla)
				if not motor.resolver_prueba(3).exitosa and motor.resolver([{&"cantidad": 1, &"caras": 6, &"signo": 1}]).total_efectivo <= 3:
					contexto.objetivo.motor_dados = _motor(semilla)
					break
	escenario.gestor_acciones.accion_iniciada.connect(controlar)
	escenario.ejecutar_turnos = true
	escenario._programar_turno_npc()
	for _intento in 250:
		await create_timer(0.02).timeout
		if escenario.gestor_rondas.actor_activo == ficha:
			break
	escenario.ejecutar_turnos = false
	_comprobar(conteo.telarana == 1 and conteo.mordida == 0 and ficha.obtener_estado(&"inmovilizado") != null, "Ejecutor real lanza telaraña y devuelve el turno a la víctima.")
	_comprobar(arana.obtener_recurso_turno(RecursosTurnoActor.ACCION_PRINCIPAL) == 0, "Ejecutor cobra una sola principal.")
	var archivo := "user://prueba_integracion_eek.json"
	escenario.accion_destrabarse.motor_dados = _motor(0)
	for semilla in 100:
		if not _motor(semilla).resolver_prueba(3).exitosa:
			escenario.accion_destrabarse.motor_dados = _motor(semilla)
			break
	var liberar: ResultadoAccion = escenario.gestor_acciones.procesar_accion(escenario.accion_destrabarse.construir_contexto(ficha))
	_comprobar(liberar.exitosa and not liberar.tirada.exitosa, "La ficha intenta liberarse dentro del encuentro real.")
	var ticks: int = ficha.obtener_estado(&"inmovilizado").ticks_pendientes
	_comprobar(escenario.guardar_partida(archivo) == &"", "Guardar encuentro con telaraña e intento gastado.")
	ficha.liberacion_telarana_intentada = false
	_comprobar(escenario.cargar_partida(archivo) == &"" and ficha.liberacion_telarana_intentada and ficha.obtener_estado(&"inmovilizado").ticks_pendientes == ticks, "Carga completa no repite habilidad, duración ni liberación.")
	escenario.tablero.reubicar_interactuable(arana, Vector2i(101, 100))
	arana.global_position = suelo.to_global(suelo.map_to_local(arana.coordenada_mapa))
	_activar_arana(escenario, arana)
	var vida := ficha.pv_actual
	escenario.ejecutar_turnos = true
	escenario._programar_turno_npc()
	for _intento in 250:
		await create_timer(0.02).timeout
		if escenario.gestor_rondas.actor_activo == ficha:
			break
	escenario.ejecutar_turnos = false
	_comprobar(conteo.mordida == 1 and vida - ficha.pv_actual >= 4 and vida - ficha.pv_actual <= 6, "Ejecutor real usa mordida con daño exacto.")
	_comprobar(arana.coordenada_mapa != Vector2i(101, 100), "Ejecutor realiza retirada pagada tras morder.")
	var entradas: int = escenario.registro_narrativo.obtener_entradas_visibles().size()
	escenario._terminar_combate(false)
	escenario._registrar_resultado_narrativo("Telaraña", ResultadoAccion.crear_exito([&"eek.telarana_evitada"]), EntradaRegistroNarrativo.Categoria.ESTADO, "DES", arana)
	_comprobar(escenario.registro_narrativo.obtener_entradas_visibles().size() == entradas, "Acciones NPC siguen silenciadas fuera de combate.")
	escena.queue_free()
	await process_frame


func _activar_arana(escenario: Node2D, arana: PersonajeNPC) -> void:
	escenario._secuencia_turno_npc += 1
	# Orden fijo: la iniciativa por ronda puede conceder dos turnos NPC consecutivos.
	var actores: Array[Object] = [arana, escenario.ficha_jugador]
	escenario.gestor_rondas.set("_actores", actores)
	escenario.gestor_rondas.actor_activo = arana
	escenario.gestor_rondas.set("_indice_activo", 0)
	arana.iniciar_turno()


func _comprobar(condicion: bool, mensaje: String) -> void:
	_casos += 1
	if not condicion:
		_fallos.append(mensaje)
