class_name EstadoActor
extends RefCounted

var clave: StringName:
	get: return _clave
var magnitud: float:
	get: return _magnitud
var duracion_total: int:
	get: return _duracion_total
var ticks_pendientes: int:
	get: return _ticks_pendientes

var _clave: StringName
var _magnitud: float
var _duracion_total: int
var _ticks_pendientes: int


func _init(
	clave_inicial: StringName,
	magnitud_inicial: float,
	duracion_inicial: int,
	ticks_iniciales: int
) -> void:
	_clave = clave_inicial
	_magnitud = magnitud_inicial
	_duracion_total = duracion_inicial
	_ticks_pendientes = ticks_iniciales


func renovar(magnitud_nueva: float, duracion_nueva: int, ticks_nuevos: int) -> void:
	_magnitud = maxf(_magnitud, magnitud_nueva)
	_duracion_total = maxi(_duracion_total, duracion_nueva)
	_ticks_pendientes = maxi(_ticks_pendientes, ticks_nuevos)
