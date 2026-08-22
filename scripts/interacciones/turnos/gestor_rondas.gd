class_name GestorRondas
extends RefCounted

var servicio_turnos: ServicioTurnos
var ronda_actual: int = 0
var actor_activo: Object
var _actores: Array[Object] = []
var _indice_activo: int = -1


func _init(servicio_inicial: ServicioTurnos) -> void:
	servicio_turnos = servicio_inicial


func iniciar(actores: Array[Object]) -> ResultadoAvanceTurno:
	var motivo := _validar_actores(actores)
	if motivo != &"":
		return ResultadoAvanceTurno.new(false, motivo)
	var ordenados := actores.duplicate()
	ordenados.sort_custom(_va_antes)
	var primer_indice := _buscar_activo(ordenados, -1)
	if primer_indice < 0:
		return ResultadoAvanceTurno.new(false, &"sin_actores_activos")
	_actores = ordenados
	_indice_activo = primer_indice
	actor_activo = _actores[_indice_activo]
	ronda_actual = 1
	actor_activo.call(&"iniciar_turno")
	return ResultadoAvanceTurno.new(
		true, &"", ronda_actual, &"", _id(actor_activo), true
	)


func finalizar_turno_activo() -> ResultadoAvanceTurno:
	if actor_activo == null or _indice_activo < 0:
		return ResultadoAvanceTurno.new(false, &"sin_actor_activo", ronda_actual)
	var id_finalizado := _id(actor_activo)
	var resultado := servicio_turnos.avanzar_turno(actor_activo)
	if not resultado.exitosa:
		return ResultadoAvanceTurno.new(
			false,
			resultado.motivo,
			ronda_actual,
			id_finalizado,
			id_finalizado,
			false,
			resultado
		)
	var siguiente := _buscar_activo(_actores, _indice_activo)
	if siguiente < 0:
		actor_activo = null
		_indice_activo = -1
		return ResultadoAvanceTurno.new(
			true, &"", ronda_actual, id_finalizado, &"", false, resultado
		)
	var nueva_ronda := siguiente <= _indice_activo
	if nueva_ronda:
		ronda_actual += 1
	_indice_activo = siguiente
	actor_activo = _actores[_indice_activo]
	actor_activo.call(&"iniciar_turno")
	return ResultadoAvanceTurno.new(
		true,
		&"",
		ronda_actual,
		id_finalizado,
		_id(actor_activo),
		nueva_ronda,
		resultado
	)


func obtener_ids_ordenados() -> Array[StringName]:
	var ids: Array[StringName] = []
	for actor in _actores:
		ids.append(_id(actor))
	return ids


func _validar_actores(actores: Array[Object]) -> StringName:
	if servicio_turnos == null or actores.is_empty():
		return &"configuracion_ronda_invalida"
	var ids: Dictionary[StringName, bool] = {}
	for actor in actores:
		if actor == null or not is_instance_valid(actor):
			return &"actor_ronda_invalido"
		if (
			not actor.has_method(&"obtener_id_actor")
			or not actor.has_method(&"obtener_iniciativa")
			or not actor.has_method(&"puede_actuar")
			or not actor.has_method(&"iniciar_turno")
		):
			return &"contrato_actor_ronda_invalido"
		var id_actor: Variant = actor.call(&"obtener_id_actor")
		var iniciativa: Variant = actor.call(&"obtener_iniciativa")
		var activo: Variant = actor.call(&"puede_actuar")
		if not id_actor is StringName or id_actor == &"" or ids.has(id_actor):
			return &"id_actor_ronda_invalido"
		if not iniciativa is int or not activo is bool:
			return &"contrato_actor_ronda_invalido"
		ids[id_actor] = true
	return &""


func _buscar_activo(actores: Array[Object], desde: int) -> int:
	for desplazamiento in range(1, actores.size() + 1):
		var indice := (desde + desplazamiento) % actores.size()
		if actores[indice].call(&"puede_actuar"):
			return indice
	return -1


func _va_antes(a: Object, b: Object) -> bool:
	var iniciativa_a: int = a.call(&"obtener_iniciativa")
	var iniciativa_b: int = b.call(&"obtener_iniciativa")
	if iniciativa_a != iniciativa_b:
		return iniciativa_a > iniciativa_b
	return String(_id(a)) < String(_id(b))


func _id(actor: Object) -> StringName:
	return actor.call(&"obtener_id_actor") as StringName
