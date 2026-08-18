class_name ResultadoEfectoAplicado
extends RefCounted

var clave: StringName:
	get: return _clave
var tipo: StringName:
	get: return _tipo
var objetivo: Object:
	get: return _objetivo
var magnitud: float:
	get: return _magnitud
var mensajes: Array[StringName]:
	get: return _mensajes.duplicate()
var cambios_estado: Array[Dictionary]:
	get: return _cambios_estado.duplicate(true)

var _clave: StringName
var _tipo: StringName
var _objetivo: Object
var _magnitud: float
var _mensajes: Array[StringName]
var _cambios_estado: Array[Dictionary]


func _init(
	clave_inicial: StringName,
	tipo_inicial: StringName,
	objetivo_inicial: Object,
	magnitud_inicial: float,
	mensajes_iniciales: Array[StringName] = [],
	cambios_iniciales: Array[Dictionary] = []
) -> void:
	_clave = clave_inicial
	_tipo = tipo_inicial
	_objetivo = objetivo_inicial
	_magnitud = magnitud_inicial
	_mensajes = mensajes_iniciales.duplicate()
	_cambios_estado = cambios_iniciales.duplicate(true)
