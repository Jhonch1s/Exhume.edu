class_name CondicionesObservacion
extends RefCounted

var observador: Object:
	get:
		return _observador

var distancia: float:
	get:
		return _distancia

var objetivo_visible: bool:
	get:
		return _objetivo_visible

var linea_visual_valida: bool:
	get:
		return _linea_visual_valida

var pistas: Array[StringName]:
	get:
		return _pistas.duplicate()

var _observador: Object
var _distancia: float
var _objetivo_visible: bool
var _linea_visual_valida: bool
var _pistas: Array[StringName]


func _init(
	observador_inicial: Object,
	distancia_inicial: float,
	objetivo_visible_inicial: bool,
	linea_visual_valida_inicial: bool,
	pistas_iniciales: Array[StringName] = []
) -> void:
	_observador = observador_inicial
	_distancia = distancia_inicial
	_objetivo_visible = objetivo_visible_inicial
	_linea_visual_valida = linea_visual_valida_inicial
	_pistas = pistas_iniciales.duplicate()


func tiene_pista(pista: StringName) -> bool:
	return pista != &"" and pista in _pistas


func es_valida() -> bool:
	if _observador == null or not is_instance_valid(_observador):
		return false
	if _distancia < 0.0:
		return false
	var pistas_vistas: Dictionary[StringName, bool] = {}
	for pista in _pistas:
		if pista == &"" or pistas_vistas.has(pista):
			return false
		pistas_vistas[pista] = true
	return true
