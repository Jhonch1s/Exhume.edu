class_name TerrenoDanino
extends RefCounted

var id_reaccion: StringName
var coordenada_mapa: Vector2i
var dano: int
var terminos_dano: Array[Dictionary]
var motor_dados: MotorDados


func _init(
	id_inicial: StringName,
	coordenada_inicial: Vector2i,
	dano_inicial: int,
	terminos_iniciales: Array[Dictionary] = [],
	motor_inicial: MotorDados = null
) -> void:
	id_reaccion = id_inicial
	coordenada_mapa = coordenada_inicial
	dano = dano_inicial
	terminos_dano = terminos_iniciales.duplicate(true)
	motor_dados = motor_inicial if motor_inicial != null else MotorDados.new()


func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo == TiposInteraccion.TipoAccion.ENTRAR


func obtener_id_reaccion() -> StringName:
	return StringName("terreno_%s_%d_%d" % [id_reaccion, coordenada_mapa.x, coordenada_mapa.y])


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
	return 0


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.ENTRAR:
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"terreno_danino_invalido"
	if terminos_dano.is_empty():
		return &"" if dano > 0 else &"terreno_danino_invalido"
	if dano != 0:
		return &"terreno_danino_invalido"
	var motivo_tirada := motor_dados.validar_cantidad(
		terminos_dano, 0, TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if motivo_tirada != &"":
		return motivo_tirada
	for termino in terminos_dano:
		if termino[&"signo"] != 1:
			return &"signo_dano_terreno_invalido"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var tirada: ResultadoTirada = null
	var dano_resuelto := dano
	if not terminos_dano.is_empty():
		tirada = motor_dados.resolver(
			terminos_dano, 0, TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
		)
		if not tirada.valida:
			return ResultadoAccion.crear_fallo(tirada.motivo)
		dano_resuelto = tirada.total_efectivo
	var resultado := ResultadoAccion.crear_exito(
		[],
		[],
		[],
		{},
		false,
		false,
		[SolicitudEfecto.new(
			id_reaccion,
			&"dano",
			contexto.actor,
			contexto.id_evento,
			float(dano_resuelto),
			0,
			TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
			self
		)]
	)
	return resultado.con_tirada(tirada) if tirada != null else resultado
