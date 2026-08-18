class_name ContextoAccion
extends RefCounted

var tipo: TiposInteraccion.TipoAccion:
	get:
		return _tipo

var id_accion: StringName:
	get:
		return _id_accion

var actor: Object:
	get:
		return _actor

var origen: Variant:
	get:
		return _origen

var celda_objetivo: Variant:
	get:
		return _celda_objetivo

var objetivo: Object:
	get:
		return _objetivo

var item: Object:
	get:
		return _item

var etiquetas: Array[StringName]:
	get:
		return _etiquetas.duplicate()

var magnitudes: Dictionary[StringName, float]:
	get:
		return _magnitudes.duplicate()

var alcance_maximo: float:
	get:
		return _alcance_maximo

var metadatos: Dictionary:
	get:
		return _metadatos.duplicate(true)

var tipo_linea_efecto: TiposInteraccion.TipoLineaEfecto:
	get:
		return _tipo_linea_efecto

var costes_solicitados: Dictionary[StringName, float]:
	get:
		return _costes_solicitados.duplicate()

var politica_cobro: TiposInteraccion.PoliticaCobro:
	get:
		return _politica_cobro

var solicitud_examen: SolicitudExamen:
	get:
		return _solicitud_examen

var id_evento: StringName:
	get:
		return _id_evento

var cantidad_item: int:
	get:
		return _cantidad_item

var id_item_resultante: StringName:
	get:
		return _id_item_resultante

var _tipo: TiposInteraccion.TipoAccion
var _id_accion: StringName
var _actor: Object
var _origen: Variant
var _celda_objetivo: Variant
var _objetivo: Object
var _item: Object
var _etiquetas: Array[StringName]
var _magnitudes: Dictionary[StringName, float]
var _alcance_maximo: float
var _metadatos: Dictionary
var _tipo_linea_efecto: TiposInteraccion.TipoLineaEfecto
var _costes_solicitados: Dictionary[StringName, float]
var _politica_cobro: TiposInteraccion.PoliticaCobro
var _solicitud_examen: SolicitudExamen
var _id_evento: StringName
var _cantidad_item: int
var _id_item_resultante: StringName


func _init(
	tipo_inicial: TiposInteraccion.TipoAccion,
	actor_inicial: Object = null,
	origen_inicial: Variant = null,
	celda_objetivo_inicial: Variant = null,
	objetivo_inicial: Object = null,
	item_inicial: Object = null,
	id_accion_inicial: StringName = &"",
	etiquetas_iniciales: Array[StringName] = [],
	magnitudes_iniciales: Dictionary[StringName, float] = {},
	alcance_maximo_inicial: float = -1.0,
	metadatos_iniciales: Dictionary = {},
	tipo_linea_efecto_inicial: TiposInteraccion.TipoLineaEfecto = (
		TiposInteraccion.TipoLineaEfecto.NINGUNA
	),
	costes_solicitados_iniciales: Dictionary[StringName, float] = {},
	politica_cobro_inicial: TiposInteraccion.PoliticaCobro = (
		TiposInteraccion.PoliticaCobro.SOLO_EXITO
	),
	solicitud_examen_inicial: SolicitudExamen = null,
	id_evento_inicial: StringName = &"",
	cantidad_item_inicial: int = -1,
	id_item_resultante_inicial: StringName = &""
) -> void:
	_tipo = tipo_inicial
	_actor = actor_inicial
	_origen = origen_inicial
	_celda_objetivo = celda_objetivo_inicial
	_objetivo = objetivo_inicial
	_item = item_inicial
	_id_accion = id_accion_inicial
	_etiquetas = etiquetas_iniciales.duplicate()
	_magnitudes = magnitudes_iniciales.duplicate()
	_alcance_maximo = alcance_maximo_inicial
	_metadatos = metadatos_iniciales.duplicate(true)
	_tipo_linea_efecto = tipo_linea_efecto_inicial
	_costes_solicitados = costes_solicitados_iniciales.duplicate()
	_politica_cobro = politica_cobro_inicial
	_solicitud_examen = solicitud_examen_inicial
	_id_evento = id_evento_inicial
	_cantidad_item = cantidad_item_inicial
	_id_item_resultante = id_item_resultante_inicial


func tiene_origen() -> bool:
	return _origen is Vector2i


func tiene_celda_objetivo() -> bool:
	return _celda_objetivo is Vector2i
