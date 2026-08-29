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
var terminos_dano_tick: Array[Dictionary]:
	get: return _terminos_dano_tick.duplicate(true)

var _clave: StringName
var _magnitud: float
var _duracion_total: int
var _ticks_pendientes: int
var _terminos_dano_tick: Array[Dictionary]


func _init(
	clave_inicial: StringName,
	magnitud_inicial: float,
	duracion_inicial: int,
	ticks_iniciales: int,
	terminos_dano_iniciales: Array[Dictionary] = []
) -> void:
	_clave = clave_inicial
	_magnitud = magnitud_inicial
	_duracion_total = duracion_inicial
	_ticks_pendientes = ticks_iniciales
	_terminos_dano_tick = terminos_dano_iniciales.duplicate(true)


func renovar(
	magnitud_nueva: float,
	duracion_nueva: int,
	ticks_nuevos: int,
	terminos_dano_nuevos: Array[Dictionary] = []
) -> void:
	_magnitud = maxf(_magnitud, magnitud_nueva)
	_duracion_total = maxi(_duracion_total, duracion_nueva)
	_ticks_pendientes = maxi(_ticks_pendientes, ticks_nuevos)
	if not terminos_dano_nuevos.is_empty():
		_terminos_dano_tick = terminos_dano_nuevos.duplicate(true)


func consumir_tick() -> int:
	_ticks_pendientes = maxi(0, _ticks_pendientes - 1)
	return _ticks_pendientes
