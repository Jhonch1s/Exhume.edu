class_name ConstructorContextoAccion
extends RefCounted


func construir_desde_opcion(
	opcion: OpcionAccion,
	actor: Object,
	origen: Vector2i,
	celda_objetivo: Vector2i
) -> Variant:
	if opcion == null:
		return &"opcion_accion_invalida"
	if actor == null or not is_instance_valid(actor):
		return &"actor_invalido"
	if opcion.objetivo == null or not is_instance_valid(opcion.objetivo):
		return &"objetivo_invalido"
	if not opcion.objetivo.has_method(&"construir_contexto_accion"):
		return &"objetivo_no_construye_contexto"

	var contexto: Variant = opcion.objetivo.call(
		&"construir_contexto_accion",
		opcion,
		actor,
		origen,
		celda_objetivo
	)
	if not contexto is ContextoAccion:
		return &"contrato_constructor_contexto_invalido"
	if not _es_coherente(contexto, opcion, actor, origen, celda_objetivo):
		return &"contexto_construido_incoherente"
	return contexto


func _es_coherente(
	contexto: ContextoAccion,
	opcion: OpcionAccion,
	actor: Object,
	origen: Vector2i,
	celda_objetivo: Vector2i
) -> bool:
	if (
		contexto.tipo != opcion.tipo
		or contexto.actor != actor
		or contexto.objetivo != opcion.objetivo
		or not contexto.tiene_origen()
		or contexto.origen != origen
		or not contexto.tiene_celda_objetivo()
		or contexto.celda_objetivo != celda_objetivo
		or contexto.tipo_linea_efecto != opcion.tipo_linea_efecto
		or contexto.costes_solicitados != opcion.costes_previstos
		or contexto.politica_cobro != opcion.politica_cobro
	):
		return false
	if contexto.tipo == TiposInteraccion.TipoAccion.INTERACTUAR:
		return contexto.id_accion == opcion.id
	return contexto.id_accion == &""
