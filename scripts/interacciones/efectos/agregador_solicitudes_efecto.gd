class_name AgregadorSolicitudesEfecto
extends RefCounted


func agregar(solicitudes: Array[SolicitudEfecto]) -> ResultadoAgregacionEfectos:
	for solicitud in solicitudes:
		var motivo := _validar(solicitud)
		if motivo != &"":
			return ResultadoAgregacionEfectos.new(false, motivo)

	var agregadas: Array[SolicitudEfecto] = []
	var indices: Dictionary[String, int] = {}
	for solicitud in solicitudes:
		var identidad := _crear_identidad(solicitud)
		if not indices.has(identidad):
			indices[identidad] = agregadas.size()
			agregadas.append(solicitud)
			continue

		var indice: int = indices[identidad]
		var anterior := agregadas[indice]
		if anterior.tipo != solicitud.tipo:
			return ResultadoAgregacionEfectos.new(false, &"solicitudes_incompatibles")
		var usar_nueva := solicitud.magnitud > anterior.magnitud
		agregadas[indice] = SolicitudEfecto.new(
			solicitud.clave,
			solicitud.tipo,
			solicitud.objetivo,
			solicitud.id_evento,
			maxf(anterior.magnitud, solicitud.magnitud),
			maxi(anterior.duracion, solicitud.duracion),
			solicitud.politica_apilado,
			solicitud.fuente if usar_nueva else anterior.fuente,
			solicitud.terminos_dano if usar_nueva else anterior.terminos_dano
		)
	return ResultadoAgregacionEfectos.new(true, &"", agregadas)


func _validar(solicitud: SolicitudEfecto) -> StringName:
	if solicitud == null:
		return &"solicitud_efecto_invalida"
	if solicitud.clave == &"" or solicitud.tipo == &"" or solicitud.id_evento == &"":
		return &"solicitud_efecto_invalida"
	if solicitud.objetivo == null or not is_instance_valid(solicitud.objetivo):
		return &"objetivo_efecto_invalido"
	if not is_finite(solicitud.magnitud) or solicitud.magnitud < 0.0:
		return &"magnitud_efecto_invalida"
	if solicitud.duracion < 0:
		return &"duracion_efecto_invalida"
	if solicitud.politica_apilado != TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR:
		return &"politica_apilado_no_admitida"
	return &""


func _crear_identidad(solicitud: SolicitudEfecto) -> String:
	return "%s\u001f%s\u001f%d" % [
		solicitud.id_evento,
		solicitud.clave,
		solicitud.objetivo.get_instance_id(),
	]
