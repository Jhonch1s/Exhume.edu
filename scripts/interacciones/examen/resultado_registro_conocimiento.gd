class_name ResultadoRegistroConocimiento
extends RefCounted

var exitosa: bool:
	get:
		return _exitosa

var motivo: StringName:
	get:
		return _motivo

var ids_fragmentos_nuevos: Array[StringName]:
	get:
		return _ids_fragmentos_nuevos.duplicate()

var _exitosa: bool
var _motivo: StringName
var _ids_fragmentos_nuevos: Array[StringName]


func _init(
	exitosa_inicial: bool,
	motivo_inicial: StringName = &"",
	ids_nuevos_iniciales: Array[StringName] = []
) -> void:
	_exitosa = exitosa_inicial
	_motivo = &"" if exitosa_inicial else motivo_inicial
	_ids_fragmentos_nuevos = []
	if exitosa_inicial:
		_ids_fragmentos_nuevos = ids_nuevos_iniciales.duplicate()


static func crear_exito(
	ids_nuevos_iniciales: Array[StringName] = []
) -> ResultadoRegistroConocimiento:
	return ResultadoRegistroConocimiento.new(true, &"", ids_nuevos_iniciales)


static func crear_fallo(motivo_inicial: StringName) -> ResultadoRegistroConocimiento:
	var motivo := motivo_inicial if motivo_inicial != &"" else &"motivo_no_especificado"
	return ResultadoRegistroConocimiento.new(false, motivo)
