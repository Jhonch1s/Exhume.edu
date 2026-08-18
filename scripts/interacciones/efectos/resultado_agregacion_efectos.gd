class_name ResultadoAgregacionEfectos
extends RefCounted

var valido: bool:
	get: return _valido
var motivo: StringName:
	get: return _motivo
var solicitudes: Array[SolicitudEfecto]:
	get:
		return _solicitudes.duplicate()

var _solicitudes: Array[SolicitudEfecto]
var _valido: bool
var _motivo: StringName


func _init(
	valido_inicial: bool,
	motivo_inicial: StringName = &"",
	solicitudes_iniciales: Array[SolicitudEfecto] = []
) -> void:
	_valido = valido_inicial
	_motivo = motivo_inicial
	_solicitudes = solicitudes_iniciales.duplicate()
