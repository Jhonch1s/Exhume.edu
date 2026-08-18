class_name DefinicionItem
extends Resource

@export_category("Identidad")
@export var id_definicion: StringName = &""
@export var nombre: String = ""
@export var escena_mundo: PackedScene

@export_category("Semantica")
@export var etiquetas: Array[StringName] = []

@export_category("Apilado")
@export var apilable: bool = false
@export_range(1, 999, 1) var cantidad_maxima: int = 1


func es_valida() -> bool:
	if id_definicion == &"" or nombre.is_empty() or cantidad_maxima < 1:
		return false
	if not apilable and cantidad_maxima != 1:
		return false
	var etiquetas_vistas: Dictionary[StringName, bool] = {}
	for etiqueta in etiquetas:
		if etiqueta == &"" or etiquetas_vistas.has(etiqueta):
			return false
		etiquetas_vistas[etiqueta] = true
	return true
