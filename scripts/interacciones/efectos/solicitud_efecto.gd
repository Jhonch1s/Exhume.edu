class_name SolicitudEfecto
extends RefCounted

var clave: StringName:
	get: return _clave
var tipo: StringName:
	get: return _tipo
var fuente: Object:
	get: return _fuente
var objetivo: Object:
	get: return _objetivo
var magnitud: float:
	get: return _magnitud
var duracion: int:
	get: return _duracion
var politica_apilado: TiposInteraccion.PoliticaApilado:
	get: return _politica_apilado
var id_evento: StringName:
	get: return _id_evento
var terminos_dano: Array[Dictionary]:
	get: return _terminos_dano.duplicate(true)

var _clave: StringName
var _tipo: StringName
var _fuente: Object
var _objetivo: Object
var _magnitud: float
var _duracion: int
var _politica_apilado: TiposInteraccion.PoliticaApilado
var _id_evento: StringName
var _terminos_dano: Array[Dictionary]


func _init(
	clave_inicial: StringName,
	tipo_inicial: StringName,
	objetivo_inicial: Object,
	id_evento_inicial: StringName,
	magnitud_inicial: float = 0.0,
	duracion_inicial: int = 0,
	politica_inicial: TiposInteraccion.PoliticaApilado = (
		TiposInteraccion.PoliticaApilado.NO_APILAR_Y_RENOVAR
	),
	fuente_inicial: Object = null,
	terminos_dano_iniciales: Array[Dictionary] = []
) -> void:
	_clave = clave_inicial
	_tipo = tipo_inicial
	_objetivo = objetivo_inicial
	_id_evento = id_evento_inicial
	_magnitud = magnitud_inicial
	_duracion = duracion_inicial
	_politica_apilado = politica_inicial
	_fuente = fuente_inicial
	_terminos_dano = terminos_dano_iniciales.duplicate(true)
