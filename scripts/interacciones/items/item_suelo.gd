class_name ItemSuelo
extends RefCounted

var item: ItemInstancia:
	get:
		return _item

var coordenada_mapa: Variant:
	get:
		return _coordenada_mapa

var esta_registrado: bool:
	get:
		return _esta_registrado

var desplazamiento_visual: Vector2:
	get:
		return _desplazamiento_visual

var _item: ItemInstancia
var _coordenada_mapa: Variant = null
var _esta_registrado: bool = false
var _desplazamiento_visual := Vector2.ZERO
var _transferidor_items: TransferidorItems
var _representacion: Node2D
var variante_visual: int = -1


func _init(item_inicial: ItemInstancia) -> void:
	_item = item_inicial


func es_valido() -> bool:
	return _item != null and _item.es_valida()


func configurar_transferidor_items(nuevo_transferidor: TransferidorItems) -> void:
	_transferidor_items = nuevo_transferidor


func configurar_desplazamiento_visual(nuevo_desplazamiento: Vector2) -> void:
	_desplazamiento_visual = nuevo_desplazamiento


func obtener_id_objetivo_interaccion() -> StringName:
	return _item.id_instancia if _item != null else &""


func obtener_nombre_interaccion() -> String:
	return _item.definicion.nombre if es_valido() else "Item"


func vincular_representacion(nueva_representacion: Node2D) -> void:
	_representacion = nueva_representacion
	if nueva_representacion is RepresentacionItemSuelo:
		variante_visual = nueva_representacion.variante_visual


func obtener_representacion() -> Node2D:
	return _representacion if is_instance_valid(_representacion) else null


func establecer_resaltado(activo: bool) -> void:
	if is_instance_valid(_representacion) and _representacion.has_method(&"establecer_resaltado"):
		_representacion.call(&"establecer_resaltado", activo)


func contiene_punto_visual(punto_global: Vector2) -> bool:
	return (
		is_instance_valid(_representacion)
		and _representacion.has_method(&"contiene_punto_global")
		and _representacion.call(&"contiene_punto_global", punto_global)
	)


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	if not _esta_registrado or _transferidor_items == null:
		return []
	return [OpcionAccion.crear_habilitada(
		&"examinar",
		TiposInteraccion.TipoAccion.EXAMINAR,
		&"interaccion.examinar",
		self
	), OpcionAccion.crear_habilitada(
		&"recoger",
		TiposInteraccion.TipoAccion.RECOGER,
		&"interaccion.recoger",
		self,
		{},
		10
	)]


func construir_contexto_accion(
	opcion: OpcionAccion,
	actor: Object,
	origen: Vector2i,
	celda_objetivo: Vector2i,
	_item_seleccionado: ItemInstancia = null
) -> ContextoAccion:
	if (
		opcion == null
		or opcion.objetivo != self
		or opcion.tipo not in [TiposInteraccion.TipoAccion.EXAMINAR, TiposInteraccion.TipoAccion.RECOGER]
		or actor == null
		or not _coordenada_mapa is Vector2i
		or celda_objetivo != _coordenada_mapa
	):
		return null
	if opcion.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return ContextoAccion.new(opcion.tipo, actor, origen, celda_objetivo, self)
	return _transferidor_items.construir_contexto_recoger(actor, self, origen)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		return &"" if _esta_registrado and contexto.objetivo == self and contexto.celda_objetivo == _coordenada_mapa and es_valido() else &"item_suelo_invalido"
	if _transferidor_items == null:
		return &"transferidor_items_no_configurado"
	return _transferidor_items.validar_recoger(contexto)


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if contexto != null and contexto.tipo == TiposInteraccion.TipoAccion.EXAMINAR:
		var motivo := validar_accion(contexto)
		return ResultadoAccion.crear_exito() if motivo == &"" else ResultadoAccion.crear_bloqueo(motivo)
	if _transferidor_items == null:
		return ResultadoAccion.crear_bloqueo(&"transferidor_items_no_configurado")
	return _transferidor_items.recoger(contexto)


func _configurar_registro(coordenada: Vector2i) -> void:
	_coordenada_mapa = coordenada
	_esta_registrado = true


func _limpiar_registro() -> void:
	_coordenada_mapa = null
	_esta_registrado = false
