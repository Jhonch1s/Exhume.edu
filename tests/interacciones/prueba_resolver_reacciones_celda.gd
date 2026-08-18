extends SceneTree

class ReceptorAutomaticoPrueba extends RefCounted:
	var resultado: ResultadoAccion
	var resoluciones: int = 0
	var ultimo_contexto: ContextoAccion

	func _init(resultado_inicial: ResultadoAccion) -> void:
		resultado = resultado_inicial

	func validar_accion(contexto: ContextoAccion) -> StringName:
		return &"" if contexto.objetivo == self else &"objetivo_no_coincide"

	func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
		resoluciones += 1
		ultimo_contexto = contexto
		return resultado


var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_prueba")


func _ejecutar_prueba() -> void:
	var gestor := GestorAcciones.new()
	root.add_child(gestor)
	var ciclos_finalizados := [0]
	gestor.accion_finalizada.connect(
		func(_contexto: ContextoAccion, _resultado: ResultadoAccion) -> void:
			ciclos_finalizados[0] += 1
	)
	var actor := RefCounted.new()
	var solicitud_debil := SolicitudEfecto.new(
		&"veneno", &"estado", actor, &"reacciones_1", 1.0, 5
	)
	var solicitud_fuerte := SolicitudEfecto.new(
		&"veneno", &"estado", actor, &"reacciones_1", 2.0, 7
	)

	var primero := ReceptorAutomaticoPrueba.new(ResultadoAccion.crear_exito(
		[&"primero"],
		[&"efecto_primero"],
		[{&"id": &"primero"}],
		{},
		false,
		false,
		[solicitud_debil]
	))
	var segundo := ReceptorAutomaticoPrueba.new(ResultadoAccion.crear_fallo(
		&"fallo_controlado",
		[&"segundo"],
		[&"efecto_segundo"],
		[],
		{},
		true,
		false,
		[solicitud_fuerte]
	))
	var terminal := ReceptorAutomaticoPrueba.new(ResultadoAccion.crear_exito(
		[&"terminal"],
		[],
		[],
		{},
		false,
		true
	))
	var omitido := ReceptorAutomaticoPrueba.new(ResultadoAccion.crear_exito(
		[&"omitido"]
	))
	var reacciones: Array[ReaccionCelda] = [
		ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.TERRENO, 0, &"a", primero),
		ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.TERRENO, 1, &"duplicada", primero),
		ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.EFECTO_SUPERFICIE, 0, &"b", segundo),
		ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.INTERACTUABLE, 0, &"c", terminal),
		ReaccionCelda.new(TiposInteraccion.CategoriaReaccion.OCUPANTE, 0, &"d", omitido),
	]
	var agregado := ResolverReaccionesCelda.new(gestor).resolver(
		TiposInteraccion.TipoAccion.ENTRAR,
		actor,
		Vector2i.ZERO,
		Vector2i(1, 0),
		reacciones
	)

	_comprobar(
		agregado.mensajes == [&"primero", &"segundo", &"terminal"],
		"Debe agregar en orden y detenerse después del resultado terminal."
	)
	_comprobar(agregado.cambios_estado.size() == 1, "Debe conservar cambios previos.")
	_comprobar(
		agregado.efectos_aplicados == [&"efecto_primero", &"efecto_segundo"],
		"Debe conservar los efectos confirmados en orden."
	)
	_comprobar(agregado.interrumpe_movimiento, "La interrupción debe combinarse con OR.")
	_comprobar(agregado.terminal, "Debe conservar la terminalidad agregada.")
	_comprobar(agregado.solicitudes_validas, "El lote de solicitudes debe ser válido.")
	_comprobar(
		agregado.solicitudes_efecto.size() == 1
		and agregado.solicitudes_efecto[0].magnitud == 2.0
		and agregado.solicitudes_efecto[0].duracion == 7,
		"Debe deduplicar las solicitudes antes de devolver el evento."
	)
	_comprobar(primero.resoluciones == 1, "Un receptor duplicado debe resolverse una vez.")
	_comprobar(omitido.resoluciones == 0, "No debe resolver receptores posteriores al terminal.")
	_comprobar(ciclos_finalizados[0] == 3, "Cada receptor resuelto debe usar GestorAcciones.")
	_comprobar(
		segundo.ultimo_contexto.tipo == TiposInteraccion.TipoAccion.ENTRAR
		and segundo.ultimo_contexto.origen == Vector2i.ZERO
		and segundo.ultimo_contexto.celda_objetivo == Vector2i(1, 0),
		"El contexto automático debe conservar tipo y coordenadas del paso."
	)
	_comprobar(
		primero.ultimo_contexto.id_evento != &""
		and primero.ultimo_contexto.id_evento == segundo.ultimo_contexto.id_evento,
		"Todos los receptores deben compartir el ID del evento automático."
	)

	primero.ultimo_contexto = null
	segundo.ultimo_contexto = null
	terminal.ultimo_contexto = null
	gestor.queue_free()
	call_deferred(&"_finalizar")


func _finalizar() -> void:
	if _fallos.is_empty():
		print("ResolverReaccionesCelda: prueba correcta.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
