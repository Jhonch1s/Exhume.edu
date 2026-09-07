@tool
class_name Interactuable
extends Node2D

signal coordenada_cambiada(anterior: Vector2i, nueva: Vector2i)
signal presencia_cambiada

@export_category("Identidad persistente")
@export var id_instancia: StringName = &""
@export var definicion: DefinicionInteractuable

@export_category("Presentacion")
@export_node_path("Sprite2D") var ruta_visual_resaltable: NodePath = ^"Sprite2D"
@export_node_path("Sprite2D") var ruta_fog_oculto: NodePath
@export_node_path("Sprite2D") var ruta_fog_explorado: NodePath
@export var color_resaltado: Color = Color.WHITE
@export_range(1.0, 4.0, 1.0) var grosor_resaltado: float = 1.0

@export_category("Edicion")
@export var ajustar_a_celda_en_editor: bool = false

@export_category("Huella")
@export var huella_celdas: Array[Vector2i] = [Vector2i.ZERO]

var coordenada_mapa: Vector2i
var tablero: TableroGrid
var servicio_examen: ServicioExamen
var resaltador_outline: ResaltadorOutline2D


func _ajustar_al_centro_celda() -> void:
	var capa := _obtener_capa_suelo()
	if capa == null:
		return
	var posicion_en_capa := capa.to_local(global_position)
	var centro := capa.to_global(capa.map_to_local(capa.local_to_map(posicion_en_capa)))
	if not global_position.is_equal_approx(centro):
		global_position = centro


func _obtener_capa_suelo() -> TileMapLayer:
	var ancestro := get_parent()
	while ancestro != null:
		var capa := ancestro.get_node_or_null(^"CapaSuelo") as TileMapLayer
		if capa != null:
			return capa
		ancestro = ancestro.get_parent()
	return null


func configurar_registro( tablero_inicial: TableroGrid, coordenada_inicial: Vector2i ) -> void:
	tablero = tablero_inicial
	coordenada_mapa = coordenada_inicial


func obtener_coordenadas_ocupadas(origen: Vector2i = coordenada_mapa) -> Array[Vector2i]:
	var coordenadas: Array[Vector2i] = []
	for desplazamiento in huella_celdas:
		var coordenada := origen + desplazamiento
		if coordenada not in coordenadas:
			coordenadas.append(coordenada)
	if coordenadas.is_empty():
		coordenadas.append(origen)
	return coordenadas


func ocupa_coordenada(coordenada: Vector2i) -> bool:
	return coordenada in obtener_coordenadas_ocupadas()


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


func actualizar_presentacion_visibilidad(estado: int) -> void:
	var fog_oculto := get_node_or_null(ruta_fog_oculto) as Sprite2D
	var fog_explorado := get_node_or_null(ruta_fog_explorado) as Sprite2D
	var usa_mascaras := fog_oculto != null and fog_explorado != null
	visible = usa_mascaras or estado != Celda.EstadoVisibilidad.OCULTO
	modulate = (
		Color.WHITE
		if usa_mascaras or estado == Celda.EstadoVisibilidad.VISIBLE
		else Color(0.4, 0.4, 0.4, 1.0)
	)
	if fog_oculto != null:
		fog_oculto.visible = estado == Celda.EstadoVisibilidad.OCULTO
	if fog_explorado != null:
		fog_explorado.visible = estado == Celda.EstadoVisibilidad.EXPLORADO


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


func obtener_opciones_accion(actor: Object = null) -> Array[OpcionAccion]:
	var opciones: Array[OpcionAccion] = []
	if (
		definicion != null
		and definicion.perfil_observacion != null
		and not definicion.fragmentos_informacion.is_empty()
	):
		opciones.append(OpcionAccion.crear_habilitada(
			&"examinar",
			TiposInteraccion.TipoAccion.EXAMINAR,
			&"interaccion.examinar",
			self,
			{},
			0,
			false,
			{},
			TiposInteraccion.TipoLineaEfecto.VISUAL
		))
	var inventario := _obtener_inventario_actor(actor)
	if inventario != null and not inventario.obtener_contenido().is_empty():
		opciones.append(OpcionAccion.crear_habilitada(
			&"usar_item",
			TiposInteraccion.TipoAccion.USAR_ITEM,
			&"interaccion.usar_item",
			self,
			{},
			5
		))
	return opciones


func obtener_fragmentos_informacion() -> Array[FragmentoInformacion]:
	if definicion == null:
		return []
	return definicion.fragmentos_informacion.duplicate()


func reacciona_automaticamente(_tipo: TiposInteraccion.TipoAccion) -> bool:
	return false


func admite_reaccion_dirigida(_tipo: TiposInteraccion.TipoAccion) -> bool:
	return false


func obtener_id_reaccion() -> StringName:
	return id_instancia


func obtener_coordenada_reaccion() -> Vector2i:
	return coordenada_mapa


func obtener_prioridad_reaccion(_tipo: TiposInteraccion.TipoAccion) -> int:
	return 0


func obtener_estado_persistente() -> Dictionary:
	return {}


func validar_estado_persistente(estado: Dictionary) -> StringName:
	return &"" if estado.is_empty() else &"estado_persistente_no_admitido"


func restaurar_estado_persistente(estado: Dictionary) -> StringName:
	return validar_estado_persistente(estado)


func permite_caminar_interactuable() -> bool:
	return true


func bloquea_vision_interactuable() -> bool:
	return false


func bloquea_proyectiles_interactuable() -> bool:
	return false


func _resolver_receptores_mecanismo(
	ids_receptores: Array[StringName],
	activa: bool
) -> Variant:
	var receptores: Array[Interactuable] = []
	if ids_receptores.is_empty():
		return receptores
	if tablero == null:
		return &"tablero_mecanismo_no_configurado"

	var ids := ids_receptores.duplicate()
	ids.sort()
	var ids_vistos: Dictionary[StringName, bool] = {}
	for id_receptor in ids:
		if id_receptor == &"":
			return &"id_receptor_mecanismo_vacio"
		if ids_vistos.has(id_receptor):
			return &"id_receptor_mecanismo_duplicado"
		ids_vistos[id_receptor] = true
		var receptor := tablero.obtener_interactuable(id_receptor)
		if receptor == null:
			return &"receptor_mecanismo_inexistente"
		if (
			not receptor.has_method(&"validar_cambio_mecanismo")
			or not receptor.has_method(&"aplicar_cambio_mecanismo")
		):
			return &"receptor_mecanismo_incompatible"
		var motivo_receptor: Variant = receptor.call(
			&"validar_cambio_mecanismo", id_instancia, activa
		)
		if not motivo_receptor is StringName:
			return &"contrato_receptor_mecanismo_invalido"
		if motivo_receptor != &"":
			return motivo_receptor
		receptores.append(receptor)
	return receptores


func construir_contexto_accion(
	opcion: OpcionAccion,
	actor: Object,
	origen: Vector2i,
	celda_objetivo: Vector2i,
	item_seleccionado: ItemInstancia = null
) -> ContextoAccion:
	if (
		opcion == null
		or opcion.objetivo != self
		or actor == null
		or not is_instance_valid(actor)
		or not ocupa_coordenada(celda_objetivo)
	):
		return null

	var solicitud_examen: SolicitudExamen = null
	var etiquetas: Array[StringName] = []
	var magnitudes: Dictionary[StringName, float] = {}
	var cantidad_item := -1
	if opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		if not actor.has_method(&"obtener_id_observador"):
			return null
		var id_observador: Variant = actor.call(&"obtener_id_observador")
		if not id_observador is StringName or id_observador == &"":
			return null
		var id_observador_tipado: StringName = id_observador
		solicitud_examen = SolicitudExamen.new(id_observador_tipado)
	elif opcion.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		if _validar_item_del_actor(actor, item_seleccionado) != &"":
			return null
		etiquetas = item_seleccionado.definicion.etiquetas.duplicate()
		magnitudes = item_seleccionado.definicion.magnitudes.duplicate()
		cantidad_item = 1
	elif opcion.tipo != TiposInteraccion.TipoAccion.INTERACTUAR:
		return null

	return ContextoAccion.new(
		opcion.tipo,
		actor,
		origen,
		celda_objetivo,
		self,
		item_seleccionado,
		opcion.id if opcion.tipo == TiposInteraccion.TipoAccion.INTERACTUAR else &"",
		etiquetas,
		magnitudes,
		obtener_alcance_maximo_opcion(opcion),
		{},
		opcion.tipo_linea_efecto,
		opcion.costes_previstos,
		opcion.politica_cobro,
		solicitud_examen,
		&"",
		cantidad_item
	)


func obtener_alcance_maximo_opcion(opcion: OpcionAccion) -> float:
	if opcion == null:
		return -1.0
	if opcion.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		return 1.0
	if (
		opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR
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
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		if contexto.objetivo != self or not ocupa_coordenada(contexto.celda_objetivo):
			return &"objetivo_no_coincide"
		var motivo_item := _validar_item_del_actor(contexto.actor, contexto.item)
		if motivo_item != &"":
			return motivo_item
		if (
			contexto.cantidad_item != 1
			or contexto.id_item_resultante != &""
			or contexto.etiquetas != contexto.item.definicion.etiquetas
			or contexto.magnitudes != contexto.item.definicion.magnitudes
		):
			return &"capacidades_item_incoherentes"
		return &""
	return &"accion_no_admitida"


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		if servicio_examen == null:
			return ResultadoAccion.crear_bloqueo(&"servicio_examen_no_configurado")
		return servicio_examen.resolver_examen(contexto, self)
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.USAR_ITEM:
		var motivo := validar_accion(contexto)
		if motivo != &"":
			return ResultadoAccion.crear_bloqueo(motivo)
		return ResultadoAccion.crear_bloqueo(&"reaccion_item_no_implementada")
	return ResultadoAccion.crear_bloqueo(&"accion_no_admitida")


func _validar_item_del_actor(actor: Object, item: Variant) -> StringName:
	if not item is ItemInstancia or not item.es_valida():
		return &"item_invalido"
	var inventario := _obtener_inventario_actor(actor)
	if inventario == null:
		return &"actor_sin_inventario"
	if inventario.obtener_por_id(item.id_instancia) != item:
		return &"item_no_pertenece_inventario"
	return &""


func _obtener_inventario_actor(actor: Object) -> Inventario:
	if actor == null or not is_instance_valid(actor) or not actor.has_method(&"obtener_inventario"):
		return null
	var inventario: Variant = actor.call(&"obtener_inventario")
	return inventario if inventario is Inventario else null
