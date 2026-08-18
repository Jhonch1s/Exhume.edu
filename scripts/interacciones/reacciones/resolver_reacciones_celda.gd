class_name ResolverReaccionesCelda
extends RefCounted

var gestor_acciones: GestorAcciones
var aplicador_efectos: AplicadorEfectos
var _secuencia_evento: int = 0


func _init(
	gestor_inicial: GestorAcciones,
	aplicador_inicial: AplicadorEfectos = null
) -> void:
	gestor_acciones = gestor_inicial
	aplicador_efectos = aplicador_inicial if aplicador_inicial != null else AplicadorEfectos.new()


func resolver(
	tipo: TiposInteraccion.TipoAccion,
	actor: Object,
	origen: Vector2i,
	destino: Vector2i,
	reacciones: Array[ReaccionCelda]
) -> ResultadoReacciones:
	var agregado := ResultadoReacciones.new()
	if gestor_acciones == null or not is_instance_valid(gestor_acciones):
		return agregado
	_secuencia_evento += 1
	var id_evento := StringName("reacciones_%d" % _secuencia_evento)

	var receptores_procesados: Dictionary[int, bool] = {}
	for reaccion in reacciones.duplicate():
		if reaccion == null or not is_instance_valid(reaccion.receptor):
			continue
		var id_receptor: int = reaccion.receptor.get_instance_id()
		if receptores_procesados.has(id_receptor):
			continue
		receptores_procesados[id_receptor] = true
		var celda_objetivo := destino
		if reaccion.receptor.has_method(&"obtener_coordenada_reaccion"):
			var coordenada: Variant = reaccion.receptor.call(&"obtener_coordenada_reaccion")
			if coordenada is Vector2i:
				celda_objetivo = coordenada
		var contexto := ContextoAccion.new(
			tipo,
			actor,
			origen,
			celda_objetivo,
			reaccion.receptor,
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
			id_evento
		)
		agregado.agregar(gestor_acciones.procesar_accion(contexto))
		if agregado.terminal:
			break
	agregado.finalizar_solicitudes()
	agregado.aplicar_efectos(aplicador_efectos)
	return agregado
