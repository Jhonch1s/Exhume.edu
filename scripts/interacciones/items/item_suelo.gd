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

var _item: ItemInstancia
var _coordenada_mapa: Variant = null
var _esta_registrado: bool = false
var _transferidor_items: TransferidorItems
var _representacion: Node2D


func _init(item_inicial: ItemInstancia) -> void:
	_item = item_inicial


func es_valido() -> bool:
	return _item != null and _item.es_valida()


func configurar_transferidor_items(nuevo_transferidor: TransferidorItems) -> void:
	_transferidor_items = nuevo_transferidor


func obtener_id_objetivo_interaccion() -> StringName:
	return _item.id_instancia if _item != null else &""


func obtener_nombre_interaccion() -> String:
	return _item.definicion.nombre if es_valido() else "Item"


func vincular_representacion(nueva_representacion: Node2D) -> void:
	_representacion = nueva_representacion


func obtener_representacion() -> Node2D:
	return _representacion if is_instance_valid(_representacion) else null


func establecer_resaltado(activo: bool) -> void:
	if is_instance_valid(_representacion) and _representacion.has_method(&"establecer_resaltado"):
		_representacion.call(&"establecer_resaltado", activo)


func obtener_opciones_accion(_actor: Object = null) -> Array[OpcionAccion]:
	if not _esta_registrado or _transferidor_items == null:
		return []
	return [OpcionAccion.crear_habilitada(
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
		or opcion.tipo != TiposInteraccion.TipoAccion.RECOGER
		or actor == null
		or not _coordenada_mapa is Vector2i
		or celda_objetivo != _coordenada_mapa
	):
		return null
	return _transferidor_items.construir_contexto_recoger(actor, self, origen)


func validar_accion(contexto: ContextoAccion) -> StringName:
	if _transferidor_items == null:
		return &"transferidor_items_no_configurado"
	return _transferidor_items.validar_recoger(contexto)


func resolver_accion(contexto: ContextoAccion) -> ResultadoAccion:
	if _transferidor_items == null:
		return ResultadoAccion.crear_bloqueo(&"transferidor_items_no_configurado")
	return _transferidor_items.recoger(contexto)


func _configurar_registro(coordenada: Vector2i) -> void:
	_coordenada_mapa = coordenada
	_esta_registrado = true


func _limpiar_registro() -> void:
	_coordenada_mapa = null
	_esta_registrado = false
