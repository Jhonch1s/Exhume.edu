class_name ReaccionCelda
extends RefCounted

var categoria: TiposInteraccion.CategoriaReaccion
var prioridad: int
var id_estable: StringName
var receptor: Object


func _init(
	categoria_inicial: TiposInteraccion.CategoriaReaccion,
	prioridad_inicial: int,
	id_inicial: StringName,
	receptor_inicial: Object
) -> void:
	categoria = categoria_inicial
	prioridad = prioridad_inicial
	id_estable = id_inicial
	receptor = receptor_inicial
