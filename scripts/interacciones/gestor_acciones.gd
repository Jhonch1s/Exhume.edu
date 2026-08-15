class_name GestorAcciones
extends Node

signal accion_iniciada(contexto: ContextoAccion)
signal accion_resuelta(contexto: ContextoAccion, resultado: ResultadoAccion)
signal accion_finalizada(contexto: ContextoAccion, resultado: ResultadoAccion)

var validador_espacial: Object
var proveedor_costes: Object


func configurar_validador_espacial(nuevo_validador: Object) -> void:
	validador_espacial = nuevo_validador


func configurar_proveedor_costes(nuevo_proveedor: Object) -> void:
	proveedor_costes = nuevo_proveedor


func procesar_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto == null:
		return ResultadoAccion.crear_bloqueo(&"contexto_invalido")

	accion_iniciada.emit(contexto)

	if contexto.actor == null or not is_instance_valid(contexto.actor):
		return _finalizar(
			contexto,
			ResultadoAccion.crear_bloqueo(&"actor_invalido")
		)

	if contexto.objetivo == null or not is_instance_valid(contexto.objetivo):
		return _finalizar(
			contexto,
			ResultadoAccion.crear_bloqueo(&"objetivo_invalido")
		)

	if contexto.alcance_maximo >= 0.0:
		if not contexto.tiene_origen() or not contexto.tiene_celda_objetivo():
			return _finalizar(
				contexto,
				ResultadoAccion.crear_bloqueo(&"coordenadas_incompletas")
			)
		if _calcular_distancia(contexto.origen, contexto.celda_objetivo) > contexto.alcance_maximo:
			return _finalizar(
				contexto,
				ResultadoAccion.crear_bloqueo(&"fuera_de_alcance")
			)

	if contexto.tipo_linea_efecto != TiposInteraccion.TipoLineaEfecto.NINGUNA:
		var resultado_espacial := _validar_linea_efecto(contexto)
		if resultado_espacial != null:
			return _finalizar(contexto, resultado_espacial)

	if (
		not contexto.objetivo.has_method(&"validar_accion")
		or not contexto.objetivo.has_method(&"resolver_accion")
	):
		return _finalizar(
			contexto,
			ResultadoAccion.crear_bloqueo(&"objetivo_no_es_receptor")
		)

	var motivo_validacion: Variant = contexto.objetivo.call(&"validar_accion", contexto)
	if not motivo_validacion is StringName:
		return _finalizar(
			contexto,
			ResultadoAccion.crear_bloqueo(&"contrato_receptor_invalido")
		)
	if motivo_validacion != &"":
		return _finalizar(
			contexto,
			ResultadoAccion.crear_bloqueo(motivo_validacion)
		)

	if not contexto.costes_solicitados.is_empty():
		var resultado_costes := _validar_costes(contexto)
		if resultado_costes != null:
			return _finalizar(contexto, resultado_costes)

	var resultado_receptor: Variant = contexto.objetivo.call(&"resolver_accion", contexto)
	if not resultado_receptor is ResultadoAccion:
		return _finalizar(
			contexto,
			ResultadoAccion.crear_fallo(&"resultado_receptor_invalido")
		)

	var resultado_final: ResultadoAccion = resultado_receptor
	if _debe_consumir_costes(contexto, resultado_receptor):
		resultado_final = _consumir_costes(contexto, resultado_receptor)
	accion_resuelta.emit(contexto, resultado_receptor)
	accion_finalizada.emit(contexto, resultado_final)
	return resultado_final


func _validar_linea_efecto(contexto: ContextoAccion) -> ResultadoAccion:
	if validador_espacial == null or not is_instance_valid(validador_espacial):
		return ResultadoAccion.crear_bloqueo(&"validador_espacial_no_configurado")
	if not validador_espacial.has_method(&"validar_linea_efecto"):
		return ResultadoAccion.crear_bloqueo(&"contrato_validador_espacial_invalido")

	var motivo: Variant = validador_espacial.call(&"validar_linea_efecto", contexto)
	if not motivo is StringName:
		return ResultadoAccion.crear_bloqueo(&"contrato_validador_espacial_invalido")
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return null


func _validar_costes(contexto: ContextoAccion) -> ResultadoAccion:
	for coste in contexto.costes_solicitados.values():
		if coste < 0.0:
			return ResultadoAccion.crear_bloqueo(&"costes_invalidos")

	if proveedor_costes == null or not is_instance_valid(proveedor_costes):
		return ResultadoAccion.crear_bloqueo(&"proveedor_costes_no_configurado")
	if (
		not proveedor_costes.has_method(&"validar_costes")
		or not proveedor_costes.has_method(&"consumir_costes")
	):
		return ResultadoAccion.crear_bloqueo(&"contrato_proveedor_costes_invalido")

	var motivo: Variant = proveedor_costes.call(&"validar_costes", contexto)
	if not motivo is StringName:
		return ResultadoAccion.crear_bloqueo(&"contrato_proveedor_costes_invalido")
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return null


func _debe_consumir_costes(
	contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> bool:
	if contexto.costes_solicitados.is_empty():
		return false
	if resultado.estado == TiposInteraccion.EstadoResolucion.EXITO:
		return true
	return (
		resultado.estado == TiposInteraccion.EstadoResolucion.FALLO
		and contexto.politica_cobro == TiposInteraccion.PoliticaCobro.AL_INTENTAR
	)


func _consumir_costes(
	contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> ResultadoAccion:
	var costes_confirmados: Variant = proveedor_costes.call(&"consumir_costes", contexto)
	if costes_confirmados is StringName:
		var motivo: StringName = costes_confirmados
		if motivo == &"":
			motivo = &"consumo_costes_invalido"
		return ResultadoAccion.crear_fallo(motivo)
	if not costes_confirmados is Dictionary:
		return ResultadoAccion.crear_fallo(&"consumo_costes_invalido")

	var costes_tipados: Dictionary[StringName, float] = {}
	for clave in costes_confirmados:
		var valor: Variant = costes_confirmados[clave]
		if not clave is StringName or not valor is float or valor < 0.0:
			return ResultadoAccion.crear_fallo(&"consumo_costes_invalido")
		costes_tipados[clave] = valor
	return resultado.con_costes_consumidos(costes_tipados)


func _calcular_distancia(origen: Vector2i, destino: Vector2i) -> float:
	return float(abs(destino.x - origen.x) + abs(destino.y - origen.y))


func _finalizar(
	contexto: ContextoAccion,
	resultado: ResultadoAccion
) -> ResultadoAccion:
	accion_resuelta.emit(contexto, resultado)
	accion_finalizada.emit(contexto, resultado)
	return resultado
