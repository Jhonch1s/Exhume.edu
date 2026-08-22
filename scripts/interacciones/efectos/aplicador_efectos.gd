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
	if solicitud.clave not in [&"veneno", &"quemado"]:
		return &"estado_no_admitido"
	if (
		solicitud.magnitud <= 0.0
		or solicitud.magnitud != floorf(solicitud.magnitud)
		or solicitud.duracion <= 0
	):
		return &"configuracion_estado_invalida"
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
	var aplica_dano_inmediato := solicitud.clave == &"quemado"
	var cambio: Variant = solicitud.objetivo.call(
		&"aplicar_o_renovar_estado",
		solicitud.clave,
		solicitud.magnitud,
		solicitud.duracion,
		solicitud.duracion - (1 if aplica_dano_inmediato else 0),
		solicitud.fuente
	)
	if not cambio is Dictionary or cambio.is_empty() or not cambio.has(&"creado"):
		return &"resultado_estado_invalido"
	var creado: bool = cambio[&"creado"]
	var dano_inmediato := 0
	if creado and aplica_dano_inmediato:
		var aplicado: Variant = solicitud.objetivo.call(
			&"recibir_danio", int(solicitud.magnitud), solicitud.fuente
		)
		if not aplicado is int or aplicado < 0:
			return &"resultado_dano_invalido"
		dano_inmediato = aplicado
	cambio[&"dano_inmediato"] = dano_inmediato
	var mensaje_nuevo := (
		&"estado.envenenado" if solicitud.clave == &"veneno" else &"estado.quemado"
	)
	var mensaje_renovado := (
		&"estado.veneno_renovado"
		if solicitud.clave == &"veneno"
		else &"estado.quemado_renovado"
	)
	return ResultadoEfectoAplicado.new(
		solicitud.clave,
		solicitud.tipo,
		solicitud.objetivo,
		solicitud.magnitud,
		[mensaje_nuevo if creado else mensaje_renovado],
		[cambio]
	)
