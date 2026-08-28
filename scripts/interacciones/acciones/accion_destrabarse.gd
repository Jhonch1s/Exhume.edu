class_name AccionDestrabarse
extends RefCounted

var motor_dados: MotorDados = MotorDados.new()


func construir_contexto(ficha: Ficha) -> ContextoAccion:
	return ContextoAccion.new(
		TiposInteraccion.TipoAccion.INTERACTUAR,
		ficha, ficha.coordenada_mapa, ficha.coordenada_mapa, self,
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
	if not contexto.actor is Ficha or contexto.actor.obtener_estado(&"enredado") == null:
		return &"actor_no_enredado"
	return &""


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	var motivo := validar_accion(contexto)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var tirada := motor_dados.resolver_prueba(
		contexto.actor.obtener_destreza(), [], [],
		TiposTirada.Origen.SOLICITADA, TiposTirada.Presentacion.PRIMER_PLANO
	)
	if tirada.exitosa:
		contexto.actor.retirar_estado(&"enredado")
		return ResultadoAccion.crear_exito([&"estado.destrabado"]).con_tirada(tirada)
	return ResultadoAccion.crear_exito([&"estado.sigue_enredado"]).con_tirada(tirada)
