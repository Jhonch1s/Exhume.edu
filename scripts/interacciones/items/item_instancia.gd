class_name ItemInstancia
extends RefCounted

var id_instancia: StringName:
	get:
		return _id_instancia

var definicion: DefinicionItem:
	get:
		return _definicion

var cantidad: int:
	get:
		return _cantidad

var _id_instancia: StringName
var _definicion: DefinicionItem
var _cantidad: int


func _init(
	id_inicial: StringName,
	definicion_inicial: DefinicionItem,
	cantidad_inicial: int = 1
) -> void:
	_id_instancia = id_inicial
	_definicion = definicion_inicial
	_cantidad = cantidad_inicial


func es_valida() -> bool:
	return (
		_id_instancia != &""
		and _definicion != null
		and _definicion.es_valida()
		and _cantidad >= 1
		and _cantidad <= _definicion.cantidad_maxima
		and (_definicion.apilable or _cantidad == 1)
	)


func _establecer_cantidad(nueva_cantidad: int) -> void:
	_cantidad = nueva_cantidad
