class_name AplicadorEfectos
extends RefCounted


func admite(solicitud: SolicitudEfecto) -> bool:
	return solicitud != null and solicitud.tipo in [&"dano", &"estado"]


func validar(solicitud: SolicitudEfecto) -> StringName:
	if not admite(solicitud):
		return &"tipo_efecto_no_admitido"
	if solicitud.tipo == &"estado":
		return _validar_estado(solicitud)
	if solicitud.duracion != 0:
		return &"dano_no_instantaneo"
	if solicitud.magnitud <= 0.0 or solicitud.magnitud != floorf(solicitud.magnitud):
		return &"magnitud_dano_invalida"
	if not solicitud.objetivo.has_method(&"recibir_danio"):
		return &"objetivo_no_recibe_dano"
	return &""


func _validar_estado(solicitud: SolicitudEfecto) -> StringName:
	if solicitud.clave not in [&"veneno", &"quemado", &"enredado", &"caido"]:
		return &"estado_no_admitido"
	if (
		solicitud.magnitud < 0.0
		or solicitud.magnitud != floorf(solicitud.magnitud)
		or solicitud.duracion <= 0
	):
		return &"configuracion_estado_invalida"
	if solicitud.magnitud == 0.0 and solicitud.terminos_dano.is_empty():
		return &"configuracion_estado_invalida"
	if not solicitud.terminos_dano.is_empty():
		var motivo := MotorDados.new().validar_cantidad(
			solicitud.terminos_dano,
			0,
			TiposTirada.Origen.AUTOMATICA,
			TiposTirada.Presentacion.SOLO_LOG
		)
		if motivo != &"":
			return motivo
		for termino in solicitud.terminos_dano:
			if termino[&"signo"] != 1:
				return &"signo_dano_tick_invalido"
	if (
		not solicitud.objetivo.has_method(&"aplicar_o_renovar_estado")
		or not solicitud.objetivo.has_method(&"recibir_danio")
	):
		return &"objetivo_no_admite_estado"
	return &""


func aplicar(solicitud: SolicitudEfecto) -> Variant:
	var motivo := validar(solicitud)
	if motivo != &"":
		return motivo
	if solicitud.tipo == &"estado":
		return _aplicar_estado(solicitud)
	var magnitud_aplicada: Variant = solicitud.objetivo.call(
		&"recibir_danio",
		int(solicitud.magnitud),
		solicitud.fuente
	)
	if not magnitud_aplicada is int or magnitud_aplicada < 0:
		return &"resultado_dano_invalido"
	return ResultadoEfectoAplicado.new(
		solicitud.clave,
		solicitud.tipo,
		solicitud.objetivo,
		float(magnitud_aplicada)
	)


func _aplicar_estado(solicitud: SolicitudEfecto) -> Variant:
	var cambio: Variant = solicitud.objetivo.call(
		&"aplicar_o_renovar_estado",
		solicitud.clave,
		solicitud.magnitud,
		solicitud.duracion,
		solicitud.duracion,
		solicitud.fuente,
		solicitud.terminos_dano
	)
	if not cambio is Dictionary or cambio.is_empty() or not cambio.has(&"creado"):
		return &"resultado_estado_invalido"
	var creado: bool = cambio[&"creado"]
	var mensaje_nuevo := &"estado.enredado"
	var mensaje_renovado := &"estado.enredado_renovado"
	if solicitud.clave == &"veneno":
		mensaje_nuevo = &"estado.envenenado"
		mensaje_renovado = &"estado.veneno_renovado"
	elif solicitud.clave == &"quemado":
		mensaje_nuevo = &"estado.quemado"
		mensaje_renovado = &"estado.quemado_renovado"
	elif solicitud.clave == &"caido":
		mensaje_nuevo = &"estado.caido"
		mensaje_renovado = &"estado.caido_renovado"
	return ResultadoEfectoAplicado.new(
		solicitud.clave,
		solicitud.tipo,
		solicitud.objetivo,
		solicitud.magnitud,
		[mensaje_nuevo if creado else mensaje_renovado],
		[cambio]
	)
