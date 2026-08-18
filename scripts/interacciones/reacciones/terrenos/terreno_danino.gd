class_name TerrenoDanino
extends RefCounted

var id_reaccion: StringName
var coordenada_mapa: Vector2i
var dano: int


func _init(id_inicial: StringName, coordenada_inicial: Vector2i, dano_inicial: int) -> void:
	id_reaccion = id_inicial
	coordenada_mapa = coordenada_inicial
	dano = dano_inicial


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
	if contexto.celda_objetivo != coordenada_mapa or dano <= 0:
		return &"terreno_danino_invalido"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	return ResultadoAccion.crear_exito(
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
			float(dano),
			0,
			TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR,
			self
		)]
	)
