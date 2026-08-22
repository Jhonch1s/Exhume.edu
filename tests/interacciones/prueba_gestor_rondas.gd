extends SceneTree

var _fallos: Array[String] = []


func _init() -> void:
	call_deferred(&"_ejecutar_pruebas")


func _ejecutar_pruebas() -> void:
	await _probar_orden_avance_y_ronda()
	await _probar_ids_invalidos()
	if _fallos.is_empty():
		print("GestorRondas: pruebas correctas.")
		quit()
		return
	for fallo in _fallos:
		push_error(fallo)
	quit(1)


func _probar_orden_avance_y_ronda() -> void:
	var gestor_acciones := GestorAcciones.new()
	root.add_child(gestor_acciones)
	var gestor := GestorRondas.new(ServicioTurnos.new(gestor_acciones))
	var actor_a := _crear_actor(&"a", 10)
	var actor_b := _crear_actor(&"b", 10)
	var actor_c := _crear_actor(&"c", 5)
	var inicio := gestor.iniciar([actor_c, actor_b, actor_a])
	_comprobar(
		inicio.exitoso
		and inicio.ronda == 1
		and inicio.id_actor_activo == &"a"
		and gestor.obtener_ids_ordenados() == [&"a", &"b", &"c"],
		"La iniciativa debe descender y desempatar por ID estable."
	)
	actor_a.consumir_recurso_turno(RecursosTurnoActor.MOVIMIENTO, 3)
	var avance_b := gestor.finalizar_turno_activo()
	_comprobar(
		avance_b.id_actor_finalizado == &"a"
		and avance_b.id_actor_activo == &"b"
		and not avance_b.nueva_ronda,
		"Debe avanzar al siguiente actor de la misma ronda."
	)
	AplicadorEfectos.new().aplicar(SolicitudEfecto.new(
		&"veneno", &"estado", actor_b, &"veneno_b", 1.0, 2
	))
	var vida_b := actor_b.pv_actual
	actor_c.pv_actual = 0
	var avance_ronda := gestor.finalizar_turno_activo()
	_comprobar(
		avance_ronda.exitoso
		and avance_ronda.id_actor_activo == &"a"
		and avance_ronda.ronda == 2
		and avance_ronda.nueva_ronda,
		"Debe omitir muertos y comenzar una ronda nueva."
	)
	_comprobar(
		actor_b.pv_actual == vida_b - 1
		and avance_ronda.resultado_turno.efectos_aplicados.size() == 1,
		"FIN_TURNO debe procesar sólo los estados del actor finalizado."
	)
	_comprobar(
		actor_a.obtener_recurso_turno(RecursosTurnoActor.MOVIMIENTO) == 7,
		"El actor que comienza la nueva ronda debe reponer sus recursos."
	)
	_liberar([actor_a, actor_b, actor_c], gestor_acciones)
	await process_frame


func _probar_ids_invalidos() -> void:
	var gestor_acciones := GestorAcciones.new()
	root.add_child(gestor_acciones)
	var gestor := GestorRondas.new(ServicioTurnos.new(gestor_acciones))
	var actor_a := _crear_actor(&"duplicado", 1)
	var actor_b := _crear_actor(&"duplicado", 2)
	var resultado := gestor.iniciar([actor_a, actor_b])
	_comprobar(
		not resultado.exitoso
		and resultado.motivo == &"id_actor_ronda_invalido"
		and gestor.actor_activo == null,
		"IDs duplicados deben bloquear antes de iniciar la ronda."
	)
	_liberar([actor_a, actor_b], gestor_acciones)
	await process_frame


func _crear_actor(id: StringName, iniciativa: int) -> Ficha:
	var actor := Ficha.new()
	actor.id_actor = id
	actor.iniciativa_base = iniciativa
	root.add_child(actor)
	return actor


func _liberar(actores: Array, gestor_acciones: GestorAcciones) -> void:
	for actor in actores:
		actor.queue_free()
	gestor_acciones.queue_free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
