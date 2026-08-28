class_name Lodo
extends RefCounted

var id_instancia: StringName
var familia: StringName
var tablero: TableroGrid
var coordenada_mapa: Vector2i
var motor_dados: MotorDados = MotorDados.new()


func _init(id_inicial: StringName, familia_inicial: StringName = &"lodo") -> void:
	id_instancia = id_inicial
	familia = familia_inicial


func configurar_registro(tablero_inicial: TableroGrid, coordenada: Vector2i) -> void:
	tablero = tablero_inicial
	coordenada_mapa = coordenada


func obtener_id_reaccion() -> StringName:
	return id_instancia


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
	return 0


func obtener_familia_superficie() -> StringName:
	return familia


func reacciona_automaticamente(tipo: TiposInteraccion.TipoAccion) -> bool:
	return tipo == TiposInteraccion.TipoAccion.ENTRAR


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.ENTRAR:
		return &"accion_no_admitida"
	if contexto.celda_objetivo != coordenada_mapa:
		return &"celda_objetivo_invalida"
	if not contexto.actor is Ficha:
		return &"actor_no_es_ficha"
	var destreza: int = contexto.actor.call(&"obtener_destreza")
	return &"" if destreza >= 1 and destreza <= 5 else &"destreza_actor_invalida"


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var salvacion := motor_dados.resolver_prueba(
		contexto.actor.call(&"obtener_destreza"), [], [],
		TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.SOLO_LOG
	)
	if not salvacion.valida:
		return ResultadoAccion.crear_bloqueo(salvacion.motivo)
	if salvacion.exitosa:
		return ResultadoAccion.crear_exito([&"estado.caida_evitada"]).con_tirada(salvacion)
	return ResultadoAccion.crear_exito(
		[], [], [], {}, true, false,
		[SolicitudEfecto.new(
			&"caido", &"estado", contexto.actor, contexto.id_evento,
			1.0, 1, TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR, self
		)]
	).con_tirada(salvacion)
