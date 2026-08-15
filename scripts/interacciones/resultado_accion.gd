class_name ResultadoAccion
extends RefCounted

var estado: TiposInteraccion.EstadoResolucion:
	get:
		return _estado

var motivo: StringName:
	get:
		return _motivo

var mensajes: Array[StringName]:
	get:
		return _mensajes.duplicate()

var efectos_aplicados: Array:
	get:
		return _efectos_aplicados.duplicate()

var cambios_estado: Array[Dictionary]:
	get:
		return _cambios_estado.duplicate(true)

var costes_consumidos: Dictionary[StringName, float]:
	get:
		return _costes_consumidos.duplicate()

var interrumpe_movimiento: bool:
	get:
		return _interrumpe_movimiento

var exitosa: bool:
	get:
		return _estado == TiposInteraccion.EstadoResolucion.EXITO

var _estado: TiposInteraccion.EstadoResolucion
var _motivo: StringName
var _mensajes: Array[StringName]
var _efectos_aplicados: Array
var _cambios_estado: Array[Dictionary]
var _costes_consumidos: Dictionary[StringName, float]
var _interrumpe_movimiento: bool


func _init(
	estado_inicial: TiposInteraccion.EstadoResolucion,
	motivo_inicial: StringName = &"",
	mensajes_iniciales: Array[StringName] = [],
	efectos_iniciales: Array = [],
	cambios_iniciales: Array[Dictionary] = [],
	costes_iniciales: Dictionary[StringName, float] = {},
	interrumpe_movimiento_inicial: bool = false
) -> void:
	_estado = estado_inicial
	if _estado == TiposInteraccion.EstadoResolucion.EXITO:
		_motivo = &""
	elif motivo_inicial == &"":
		_motivo = &"motivo_no_especificado"
	else:
		_motivo = motivo_inicial
	_mensajes = mensajes_iniciales.duplicate()

	if _estado == TiposInteraccion.EstadoResolucion.BLOQUEO:
		_efectos_aplicados = []
		_cambios_estado = []
		_costes_consumidos = {}
		_interrumpe_movimiento = false
		return

	_efectos_aplicados = efectos_iniciales.duplicate(true)
	_cambios_estado = cambios_iniciales.duplicate(true)
	_costes_consumidos = costes_iniciales.duplicate()
	_interrumpe_movimiento = interrumpe_movimiento_inicial


static func crear_exito(
	mensajes_iniciales: Array[StringName] = [],
	efectos_iniciales: Array = [],
	cambios_iniciales: Array[Dictionary] = [],
	costes_iniciales: Dictionary[StringName, float] = {},
	interrumpe_movimiento_inicial: bool = false
) -> ResultadoAccion:
	return ResultadoAccion.new(
		TiposInteraccion.EstadoResolucion.EXITO,
		&"",
		mensajes_iniciales,
		efectos_iniciales,
		cambios_iniciales,
		costes_iniciales,
		interrumpe_movimiento_inicial
	)


static func crear_fallo(
	motivo_inicial: StringName,
	mensajes_iniciales: Array[StringName] = [],
	efectos_iniciales: Array = [],
	cambios_iniciales: Array[Dictionary] = [],
	costes_iniciales: Dictionary[StringName, float] = {},
	interrumpe_movimiento_inicial: bool = false
) -> ResultadoAccion:
	return ResultadoAccion.new(
		TiposInteraccion.EstadoResolucion.FALLO,
		motivo_inicial,
		mensajes_iniciales,
		efectos_iniciales,
		cambios_iniciales,
		costes_iniciales,
		interrumpe_movimiento_inicial
	)


static func crear_bloqueo(
	motivo_inicial: StringName,
	mensajes_iniciales: Array[StringName] = []
) -> ResultadoAccion:
	return ResultadoAccion.new(
		TiposInteraccion.EstadoResolucion.BLOQUEO,
		motivo_inicial,
		mensajes_iniciales
	)


func consumio_accion() -> bool:
	return _costes_consumidos.get(&"accion", 0.0) > 0.0


func consumio_turno() -> bool:
	return _costes_consumidos.get(&"turno", 0.0) > 0.0


func con_costes_consumidos(
	nuevos_costes: Dictionary[StringName, float]
) -> ResultadoAccion:
	return ResultadoAccion.new(
		_estado,
		_motivo,
		_mensajes,
		_efectos_aplicados,
		_cambios_estado,
		nuevos_costes,
		_interrumpe_movimiento
	)
