extends RefCounted

var motivo: StringName


func _init(motivo_inicial: StringName = &"") -> void:
	motivo = motivo_inicial


func validar_linea_efecto(_contexto: ContextoAccion) -> StringName:
	return motivo
