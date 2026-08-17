class_name SolicitudExamen
extends RefCounted

var id_observador: StringName:
	get:
		return _id_observador

var pistas: Array[StringName]:
	get:
		return _pistas.duplicate()

var _id_observador: StringName
var _pistas: Array[StringName]


func _init(
	id_observador_inicial: StringName,
	pistas_iniciales: Array[StringName] = []
) -> void:
	_id_observador = id_observador_inicial
	_pistas = pistas_iniciales.duplicate()


func es_valida(actor: Object) -> bool:
	if _id_observador == &"" or actor == null or not is_instance_valid(actor):
		return false
	if not actor.has_method(&"obtener_id_observador"):
		return false
	var id_actor: Variant = actor.call(&"obtener_id_observador")
	if not id_actor is StringName or id_actor != _id_observador:
		return false
	var pistas_vistas: Dictionary[StringName, bool] = {}
	for pista in _pistas:
		if pista == &"" or pistas_vistas.has(pista):
			return false
		pistas_vistas[pista] = true
	return true
