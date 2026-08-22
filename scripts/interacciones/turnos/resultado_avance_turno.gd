class_name ResultadoAvanceTurno
extends RefCounted

var exitoso: bool
var motivo: StringName
var ronda: int
var id_actor_finalizado: StringName
var id_actor_activo: StringName
var nueva_ronda: bool
var resultado_turno: ResultadoAccion


func _init(
	exitoso_inicial: bool,
	motivo_inicial: StringName = &"",
	ronda_inicial: int = 0,
	id_finalizado_inicial: StringName = &"",
	id_activo_inicial: StringName = &"",
	nueva_ronda_inicial: bool = false,
	resultado_inicial: ResultadoAccion = null
) -> void:
	exitoso = exitoso_inicial
	motivo = &"" if exitoso else motivo_inicial
	ronda = ronda_inicial
	id_actor_finalizado = id_finalizado_inicial
	id_actor_activo = id_activo_inicial
	nueva_ronda = nueva_ronda_inicial
	resultado_turno = resultado_inicial
