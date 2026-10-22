class_name AccionDestrabarse
extends RefCounted

var motor_dados: MotorDados = MotorDados.new()


func construir_contexto(actor: Node2D) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		actor, actor.coordenada_mapa, actor.coordenada_mapa, self,
		null, &"destrabarse", [], {}, 0.0, {},
		TiposInteraccion.TipoLineaEfecto.NINGUNA,
		{RecursosTurnoActor.ACCION_PRINCIPAL: 1.0},
		TiposInteraccion.PoliticaCobro.AL_INTENTAR
	)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto == null or contexto.objetivo != self:
		return &"objetivo_no_coincide"
	if contexto.tipo != TiposInteraccion.TipoAccion.INTERACTUAR or contexto.id_accion != &"destrabarse":
		return &"accion_no_admitida"
	if (
		contexto.actor == null or not contexto.actor.has_method(&"obtener_estado")
		or not contexto.actor.has_method(&"retirar_estado")
		or not contexto.actor.has_method(&"obtener_destreza")
		or not contexto.actor.has_method(&"puede_actuar")
		or not contexto.actor.puede_actuar()
		or contexto.actor.obtener_estado(&"enredado") == null
	):
		return &"actor_no_enredado"
	var destreza: Variant = EfectosEquipo.base(contexto.actor, "destreza")
	if not destreza is int or destreza < 1 or destreza > 5:
		return &"destreza_actor_invalida"
	if (
		contexto.origen != contexto.actor.coordenada_mapa
		or contexto.celda_objetivo != contexto.actor.coordenada_mapa
		or contexto.alcance_maximo != 0.0 or contexto.item != null
		or contexto.costes_solicitados != {RecursosTurnoActor.ACCION_PRINCIPAL: 1.0}
		or contexto.politica_cobro != TiposInteraccion.PoliticaCobro.AL_INTENTAR
	):
		return &"contexto_destrabarse_invalido"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var es_jugador := contexto.actor is Ficha
	var tirada := EfectosEquipo.resolver_prueba(
		motor_dados, contexto.actor, "destreza", TiposTirada.Origen.SOLICITADA if es_jugador else TiposTirada.Origen.AUTOMATICA, TiposTirada.Presentacion.PRIMER_PLANO if es_jugador else TiposTirada.Presentacion.SOLO_LOG
	)
	if not tirada.valida:
		return ResultadoAccion.crear_fallo(tirada.motivo)
	if tirada.exitosa:
		contexto.actor.retirar_estado(&"enredado")
		return ResultadoAccion.crear_exito([&"estado.destrabado"]).con_tirada(tirada)
	return ResultadoAccion.crear_exito([&"estado.sigue_enredado"]).con_tirada(tirada)
