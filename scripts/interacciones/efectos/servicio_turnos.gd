class_name ServicioTurnos
extends RefCounted

var gestor_acciones: GestorAcciones
var aplicador_efectos: AplicadorEfectos
var _secuencia_turno: int = 0


func _init(
	gestor_inicial: GestorAcciones,
	aplicador_inicial: AplicadorEfectos = null
) -> void:
	gestor_acciones = gestor_inicial
	aplicador_efectos = aplicador_inicial if aplicador_inicial != null else AplicadorEfectos.new()


func avanzar_turno(actor: Object) -> ResultadoAccion:
	if gestor_acciones == null or not is_instance_valid(gestor_acciones):
		return ResultadoAccion.crear_bloqueo(&"gestor_acciones_no_configurado")
	_secuencia_turno += 1
	return gestor_acciones.procesar_accion(ContextoAccion.new(
		TiposInteraccion.TipoAccion.FIN_TURNO,
		actor,
		null,
		null,
		self,
		null,
		&"",
		[],
		{},
		-1.0,
		{},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{},
		TiposInteraccion.PoliticaCobro.SOLO_EXITO,
		null,
		StringName("fin_turno_%d" % _secuencia_turno)
	))


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.FIN_TURNO:
		return &"accion_no_admitida"
	if (
		not contexto.actor.has_method(&"obtener_claves_estado")
		or not contexto.actor.has_method(&"obtener_estado")
		or not contexto.actor.has_method(&"consumir_tick_estado")
		or not contexto.actor.has_method(&"recibir_danio")
	):
		return &"actor_no_admite_estados_persistentes"
	var claves: Variant = contexto.actor.call(&"obtener_claves_estado")
	if not claves is Array:
		return &"resultado_estados_actor_invalido"
	for clave in claves:
		if not clave is StringName or clave not in [&"quemado", &"veneno"]:
			return &"estado_persistente_no_admitido"
		var estado: Variant = contexto.actor.call(&"obtener_estado", clave)
		if (
			not estado is EstadoActor
			or estado.clave != clave
			or estado.ticks_pendientes <= 0
			or estado.magnitud <= 0.0
			or estado.magnitud != floorf(estado.magnitud)
		):
			return &"estado_persistente_invalido"
		var motivo := aplicador_efectos.validar(_crear_solicitud(contexto, estado))
		if motivo != &"":
			return motivo
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var claves: Array[StringName] = contexto.actor.call(&"obtener_claves_estado")
	if claves.is_empty():
		return ResultadoAccion.crear_exito()
	var efectos: Array = []
	var cambios: Array[Dictionary] = []
	var mensajes: Array[StringName] = []
	for clave in claves:
		var estado: EstadoActor = contexto.actor.call(&"obtener_estado", clave)
		var aplicado: Variant = aplicador_efectos.aplicar(
			_crear_solicitud(contexto, estado)
		)
		if aplicado is StringName:
			return ResultadoAccion.crear_fallo(aplicado)
		var cambio: Variant = contexto.actor.call(&"consumir_tick_estado", clave)
		if not cambio is Dictionary or cambio.is_empty():
			return ResultadoAccion.crear_fallo(&"resultado_tick_estado_invalido")
		efectos.append(aplicado)
		cambios.append(cambio)
		mensajes.append(StringName("estado.%s_tick" % clave))
		if cambio[&"expirado"]:
			mensajes.append(StringName("estado.%s_expirado" % clave))
	return ResultadoAccion.crear_exito(mensajes, efectos, cambios)


func _crear_solicitud(
	contexto: ContextoAccion,
	estado: EstadoActor
) -> SolicitudEfecto:
	return SolicitudEfecto.new(
		estado.clave,
		&"dano",
		contexto.actor,
		contexto.id_evento,
		estado.magnitud,
		0,
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
		estado
	)
