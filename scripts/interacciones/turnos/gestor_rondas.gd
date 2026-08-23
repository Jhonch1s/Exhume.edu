class_name GestorRondas
extends RefCounted

var servicio_turnos: ServicioTurnos
var procesador_superficies: ProcesadorSuperficies
var ronda_actual: int = 0
var actor_activo: Object
var _actores: Array[Object] = []
var _indice_activo: int = -1


func _init(
	servicio_inicial: ServicioTurnos,
	procesador_inicial: ProcesadorSuperficies = null
) -> void:
	servicio_turnos = servicio_inicial
	procesador_superficies = procesador_inicial


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
	if procesador_superficies != null:
		var motivo_superficies := procesador_superficies.validar()
		if motivo_superficies != &"":
			return ResultadoAvanceTurno.new(false, motivo_superficies, ronda_actual)
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
	var resultado_superficies: ResultadoAccion = null
	if nueva_ronda:
		if procesador_superficies != null:
			resultado_superficies = procesador_superficies.procesar_fin_ronda()
			if not resultado_superficies.exitosa:
				return ResultadoAvanceTurno.new(
					false,
					resultado_superficies.motivo,
					ronda_actual,
					id_finalizado,
					id_finalizado,
					false,
					resultado,
					resultado_superficies
				)
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
		resultado,
		resultado_superficies
	)


func obtener_ids_ordenados() -> Array[StringName]:
	var ids: Array[StringName] = []
	for actor in _actores:
		ids.append(_id(actor))
	return ids


func obtener_estado_persistente() -> Variant:
	if actor_activo == null or _indice_activo < 0 or ronda_actual < 1:
		return null
	var orden: Array[String] = []
	for id_actor in obtener_ids_ordenados():
		orden.append(String(id_actor))
	return {
		"ronda": ronda_actual,
		"actor_activo_id": String(_id(actor_activo)),
		"orden_actores": orden,
	}


func validar_estado_persistente(estado: Variant) -> StringName:
	if estado == null:
		return &"" if _actores.is_empty() else &"estado_rondas_guardado_invalido"
	if not estado is Dictionary or not _es_numero_entero(estado.get("ronda")):
		return &"estado_rondas_guardado_invalido"
	var id_activo: Variant = estado.get("actor_activo_id")
	var orden: Variant = estado.get("orden_actores")
	if estado["ronda"] < 1 or not id_activo is String or not orden is Array:
		return &"estado_rondas_guardado_invalido"
	var actuales := obtener_ids_ordenados()
	if orden.size() != actuales.size():
		return &"actores_ronda_guardados_no_coinciden"
	var activo_encontrado := false
	for indice in range(orden.size()):
		if not orden[indice] is String or orden[indice] != String(actuales[indice]):
			return &"actores_ronda_guardados_no_coinciden"
		activo_encontrado = activo_encontrado or orden[indice] == id_activo
	return &"" if activo_encontrado else &"actor_activo_guardado_invalido"


func restaurar_estado_persistente(estado: Variant) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	if estado == null:
		return &""
	ronda_actual = int(estado["ronda"])
	for indice in range(_actores.size()):
		if String(_id(_actores[indice])) == estado["actor_activo_id"]:
			_indice_activo = indice
			actor_activo = _actores[indice]
			break
	return &""


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


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))
