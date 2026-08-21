class_name ReaccionImpactoSuperficie
extends Resource

@export var escena_superficie: PackedScene
@export_range(0, 8, 1) var radio: int = 0
@export var id_mensaje: StringName = &""


func validar_impacto(
	tablero: TableroGrid,
	contexto: ContextoAccion,
	coordenada: Vector2i,
	prefijo_id: StringName
) -> StringName:
	if (
		tablero == null
		or escena_superficie == null
		or contexto == null
		or contexto.item == null
		or contexto.item.definicion.reaccion_impacto != self
		or prefijo_id == &""
		or tablero.zona_referencia == null
		or tablero.capa_referencia == null
		or tablero.zona_referencia.get_node_or_null("EfectosSuperficie") == null
	):
		return &"reaccion_impacto_item_no_configurada"
	var celda := tablero.obtener_celda(coordenada)
	if celda == null or not celda.caminable:
		return &"celda_efecto_impacto_invalida"
	var id_efecto := StringName("%s_%d_%d" % [prefijo_id, coordenada.x, coordenada.y])
	if tablero.efectos_superficie_por_id.has(id_efecto):
		return &"id_efecto_superficie_duplicado"
	return &""


func resolver_impacto(
	tablero: TableroGrid,
	contexto: ContextoAccion,
	coordenada: Vector2i,
	prefijo_id: StringName
) -> ResultadoAccion:
	var motivo := validar_impacto(tablero, contexto, coordenada, prefijo_id)
	if motivo != &"":
		return ResultadoAccion.crear_bloqueo(motivo)
	var afectadas := tablero.desplegar_efecto_superficie(
		escena_superficie,
		coordenada,
		radio,
		prefijo_id
	)
	if afectadas.is_empty():
		return ResultadoAccion.crear_fallo(&"superficie_impacto_no_desplegada")
	var cambios: Array[Dictionary] = []
	for afectada in afectadas:
		cambios.append({
			&"tipo": &"superficie_desplegada",
			&"coordenada": afectada,
		})
	var mensajes: Array[StringName] = []
	if id_mensaje != &"":
		mensajes.append(id_mensaje)
	return ResultadoAccion.crear_exito(
		mensajes,
		[],
		cambios,
		{},
		false,
		false,
		[],
		TiposInteraccion.DestinoItem.CONSUMIR
	)
