class_name Interactuable
extends Node2D

#a futuro
signal coordenada_cambiada(anterior: Vector2i, nueva: Vector2i)

@export_category("Identidad persistente")
@export var id_instancia: StringName = &""
@export var definicion: DefinicionInteractuable

@export_category("Presentacion")
@export_node_path("Sprite2D") var ruta_visual_resaltable: NodePath = ^"Sprite2D"
@export var color_resaltado: Color = Color.WHITE
@export_range(1.0, 4.0, 1.0) var grosor_resaltado: float = 1.0

var coordenada_mapa: Vector2i
var tablero: TableroGrid
var servicio_examen: ServicioExamen
var resaltador_outline: ResaltadorOutline2D


func configurar_registro( tablero_inicial: TableroGrid, coordenada_inicial: Vector2i ) -> void:
	tablero = tablero_inicial
	coordenada_mapa = coordenada_inicial


func configurar_servicio_examen(nuevo_servicio: ServicioExamen) -> void:
	servicio_examen = nuevo_servicio


func obtener_id_objetivo_interaccion() -> StringName:
	return id_instancia


func obtener_nombre_interaccion() -> String:
	return definicion.nombre if definicion != null else "Interactuable"


func establecer_resaltado(activo: bool) -> void:
	var resaltador := _obtener_resaltador_outline()
	if resaltador != null:
		resaltador.establecer_activo(activo)


func esta_resaltado() -> bool:
	return (
		is_instance_valid(resaltador_outline)
		and resaltador_outline.esta_activo()
	)


func _obtener_resaltador_outline() -> ResaltadorOutline2D:
	if is_instance_valid(resaltador_outline):
		return resaltador_outline
	var visual := get_node_or_null(ruta_visual_resaltable) as Sprite2D
	if visual == null:
		return null
	resaltador_outline = ResaltadorOutline2D.new()
	resaltador_outline.name = "ResaltadorOutline2D"
	add_child(resaltador_outline)
	resaltador_outline.configurar(visual, color_resaltado, grosor_resaltado)
	return resaltador_outline


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	if (
		definicion == null
		or definicion.perfil_observacion == null
		or definicion.fragmentos_informacion.is_empty()
	):
		return []
	return [OpcionAccion.crear_habilitada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"interaccion.examinar",
		self,
		{},
		0,
		false,
		{},
		TiposInteraccion.TipoLineaEfecto.VISUAL
	)]


func obtener_fragmentos_informacion() -> Array[FragmentoInformacion]:
	if definicion == null:
		return []
	return definicion.fragmentos_informacion.duplicate()


func reacciona_automaticamente(_tipo: TiposInteraccion.TipoAccion) -> bool:
	return false


func obtener_id_reaccion() -> StringName:
	return id_instancia


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
	return 0


func construir_contexto_accion(
	opcion: OpcionAccion,
	actor: Object,
	origen: Vector2i,
	celda_objetivo: Vector2i
) -> ContextoAccion:
	if (
		opcion == null
		or opcion.objetivo != self
		or actor == null
		or not is_instance_valid(actor)
		or celda_objetivo != coordenada_mapa
	):
		return null

	var solicitud_examen: SolicitudExamen = null
	if opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		if not actor.has_method(&"obtener_id_observador"):
			return null
		var id_observador: Variant = actor.call(&"obtener_id_observador")
		if not id_observador is StringName or id_observador == &"":
			return null
		var id_observador_tipado: StringName = id_observador
		solicitud_examen = SolicitudExamen.new(id_observador_tipado)
	elif opcion.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return null

	return ContextoAccion.new(
		opcion.tipo,
		actor,
		origen,
		celda_objetivo,
		self,
		null,
		opcion.id if opcion.tipo == TiposInteraccion.TipoAccion.INTERACTUAR else &"",
		[],
		{},
		obtener_alcance_maximo_opcion(opcion),
		{},
		opcion.tipo_linea_efecto,
		opcion.costes_previstos,
		opcion.politica_cobro,
		solicitud_examen
	)


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if (
		opcion != null
		and opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR
		and definicion != null
		and definicion.perfil_observacion != null
	):
		return definicion.perfil_observacion.alcance_basico
	return -1.0


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		if servicio_examen == null:
			return &"servicio_examen_no_configurado"
		return servicio_examen.validar_examen(contexto, self)
	return &"accion_no_admitida"


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		if servicio_examen == null:
			return ResultadoAccion.crear_bloqueo(&"servicio_examen_no_configurado")
		return servicio_examen.resolver_examen(contexto, self)
	return ResultadoAccion.crear_bloqueo(&"accion_no_admitida")
