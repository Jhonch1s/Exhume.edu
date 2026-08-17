class_name EvaluadorInformacion
extends RefCounted


func evaluar(
	fragmentos: Array[FragmentoInformacion],
	condiciones: CondicionesObservacion,
	perfil: PerfilObservacion
) -> ResultadoEvaluacionInformacion:
	var motivo_estructura := _validar_estructura(fragmentos, condiciones, perfil)
	if motivo_estructura != &"":
		return ResultadoEvaluacionInformacion.crear_bloqueo(motivo_estructura)

	if perfil.requiere_objetivo_visible and not condiciones.objetivo_visible:
		return ResultadoEvaluacionInformacion.crear_bloqueo(&"objetivo_no_visible")
	if perfil.requiere_linea_visual and not condiciones.linea_visual_valida:
		return ResultadoEvaluacionInformacion.crear_bloqueo(&"linea_visual_bloqueada")
	if condiciones.distancia > perfil.alcance_basico:
		return ResultadoEvaluacionInformacion.crear_bloqueo(&"fuera_alcance_examen")

	var disponibles: Array[FragmentoInformacion] = []
	for fragmento in fragmentos:
		if _fragmento_disponible(fragmento, condiciones, perfil):
			disponibles.append(fragmento)

	if disponibles.is_empty():
		return ResultadoEvaluacionInformacion.crear_bloqueo(&"sin_informacion_disponible")
	return ResultadoEvaluacionInformacion.crear_disponible(
		disponibles,
		condiciones.distancia <= perfil.alcance_detallado
	)


func _validar_estructura(
	fragmentos: Array[FragmentoInformacion],
	condiciones: CondicionesObservacion,
	perfil: PerfilObservacion
) -> StringName:
	if condiciones == null or not condiciones.es_valida():
		return &"condiciones_observacion_invalidas"
	if perfil == null or not perfil.es_valido():
		return &"perfil_observacion_invalido"

	var ids_vistos: Dictionary[StringName, bool] = {}
	for fragmento in fragmentos:
		if fragmento == null or not fragmento.es_valido():
			return &"fragmentos_informacion_invalidos"
		if ids_vistos.has(fragmento.id_fragmento):
			return &"fragmentos_informacion_duplicados"
		ids_vistos[fragmento.id_fragmento] = true
	return &""


func _fragmento_disponible(
	fragmento: FragmentoInformacion,
	condiciones: CondicionesObservacion,
	perfil: PerfilObservacion
) -> bool:
	if not _cumple_pistas(fragmento, condiciones):
		return false

	match fragmento.nivel:
		TiposInteraccion.NivelInformacion.VISIBLE, TiposInteraccion.NivelInformacion.BASICO:
			return condiciones.distancia <= perfil.alcance_basico
		TiposInteraccion.NivelInformacion.DETALLADO:
			return condiciones.distancia <= perfil.alcance_detallado
		TiposInteraccion.NivelInformacion.SECRETO:
			return condiciones.distancia <= perfil.alcance_secreto
	return false


func _cumple_pistas(
	fragmento: FragmentoInformacion,
	condiciones: CondicionesObservacion
) -> bool:
	for pista in fragmento.pistas_requeridas:
		if not condiciones.tiene_pista(pista):
			return false
	return true
