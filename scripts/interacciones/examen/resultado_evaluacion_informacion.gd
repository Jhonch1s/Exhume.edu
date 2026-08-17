class_name ResultadoEvaluacionInformacion
extends RefCounted

var bloqueada: bool:
	get:
		return _bloqueada

var motivo: StringName:
	get:
		return _motivo

var fragmentos_disponibles: Array[FragmentoInformacion]:
	get:
		return _fragmentos_disponibles.duplicate()

var permite_detalle: bool:
	get:
		return _permite_detalle

var _bloqueada: bool
var _motivo: StringName
var _fragmentos_disponibles: Array[FragmentoInformacion]
var _permite_detalle: bool


func _init(
	bloqueada_inicial: bool,
	motivo_inicial: StringName,
	fragmentos_iniciales: Array[FragmentoInformacion] = [],
	permite_detalle_inicial: bool = false
) -> void:
	_bloqueada = bloqueada_inicial
	_motivo = motivo_inicial if bloqueada_inicial else &""
	_fragmentos_disponibles = fragmentos_iniciales.duplicate()
	_permite_detalle = permite_detalle_inicial if not bloqueada_inicial else false


static func crear_bloqueo(motivo_inicial: StringName) -> ResultadoEvaluacionInformacion:
	var motivo := motivo_inicial if motivo_inicial != &"" else &"motivo_no_especificado"
	return ResultadoEvaluacionInformacion.new(true, motivo)


static func crear_disponible(
	fragmentos_iniciales: Array[FragmentoInformacion],
	permite_detalle_inicial: bool
) -> ResultadoEvaluacionInformacion:
	return ResultadoEvaluacionInformacion.new(
		false,
		&"",
		fragmentos_iniciales,
		permite_detalle_inicial
	)
