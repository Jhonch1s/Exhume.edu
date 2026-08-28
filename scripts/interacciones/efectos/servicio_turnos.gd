class_name ServicioTurnos
extends RefCounted

var gestor_acciones: GestorAcciones
var aplicador_efectos: AplicadorEfectos
var motor_dados: MotorDados
var _secuencia_turno: int = 0


func _init(
	gestor_inicial: GestorAcciones,
	aplicador_inicial: AplicadorEfectos = null,
	motor_inicial: MotorDados = null
) -> void:
	gestor_acciones = gestor_inicial
	aplicador_efectos = aplicador_inicial if aplicador_inicial != null else AplicadorEfectos.new()
	motor_dados = motor_inicial if motor_inicial != null else MotorDados.new()


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
		if not clave is StringName or clave not in [&"quemado", &"veneno", &"enredado", &"caido"]:
			return &"estado_persistente_no_admitido"
		var estado: Variant = contexto.actor.call(&"obtener_estado", clave)
		if clave == &"enredado":
			if not estado is EstadoActor or estado.magnitud != 1.0 or estado.ticks_pendientes != 0:
				return &"estado_persistente_invalido"
			continue
		if clave == &"caido":
			if not estado is EstadoActor or estado.magnitud != 1.0 or estado.ticks_pendientes != 1:
				return &"estado_persistente_invalido"
			continue
		if (
			not estado is EstadoActor
			or estado.clave != clave
			or estado.ticks_pendientes <= 0
			or (estado.magnitud <= 0.0 and estado.terminos_dano_tick.is_empty())
			or estado.magnitud != floorf(estado.magnitud)
		):
			return &"estado_persistente_invalido"
		var motivo_dados := motor_dados.validar_cantidad(
			estado.terminos_dano_tick,
			0,
			TiposTirada.Origen.AUTOMATICA,
			TiposTirada.Presentacion.SOLO_LOG
		) if not estado.terminos_dano_tick.is_empty() else &""
		if motivo_dados != &"":
			return motivo_dados
		var motivo := aplicador_efectos.validar(
			_crear_solicitud(contexto, estado, maxi(1, int(estado.magnitud)))
		)
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
	var terminos: Array[Dictionary] = []
	var rangos: Dictionary[StringName, Vector2i] = {}
	for clave in claves:
		var estado: EstadoActor = contexto.actor.call(&"obtener_estado", clave)
		if clave in [&"enredado", &"caido"]:
			continue
		if estado.terminos_dano_tick.is_empty():
			continue
		var inicio := terminos.size()
		terminos.append_array(estado.terminos_dano_tick)
		rangos[clave] = Vector2i(inicio, terminos.size())
	var tirada: ResultadoTirada = null
	if not terminos.is_empty():
		tirada = motor_dados.resolver(
			terminos,
			0,
			TiposTirada.Origen.AUTOMATICA,
			TiposTirada.Presentacion.SOLO_LOG
		)
		if not tirada.valida:
			return ResultadoAccion.crear_fallo(tirada.motivo)
	for clave in claves:
		var estado: EstadoActor = contexto.actor.call(&"obtener_estado", clave)
		if clave == &"enredado":
			continue
		if clave == &"caido":
			var cambio_caida: Variant = contexto.actor.call(&"consumir_tick_estado", clave)
			if not cambio_caida is Dictionary or cambio_caida.is_empty():
				return ResultadoAccion.crear_fallo(&"resultado_tick_estado_invalido")
			cambios.append(cambio_caida)
			mensajes.append(&"estado.levantado")
			continue
		var dano := int(estado.magnitud)
		if rangos.has(clave):
			dano = 0
			var rango: Vector2i = rangos[clave]
			for indice in range(rango.x, rango.y):
				var termino: Dictionary = tirada.terminos[indice]
				dano += termino[&"signo"] * termino[&"subtotal"]
			dano = maxi(0, dano)
		var aplicado: Variant = aplicador_efectos.aplicar(
			_crear_solicitud(contexto, estado, dano)
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
	var resultado := ResultadoAccion.crear_exito(mensajes, efectos, cambios)
	return resultado.con_tirada(tirada) if tirada != null else resultado


func _crear_solicitud(
	contexto: ContextoAccion,
	estado: EstadoActor,
	dano: int
) -> SolicitudEfecto:
	return SolicitudEfecto.new(
		estado.clave,
		&"dano",
		contexto.actor,
		contexto.id_evento,
		float(dano),
		0,
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
		estado
	)
