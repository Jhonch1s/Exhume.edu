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
var pasos_antorchas: Array[int] = []


func _init(
	id_inicial: StringName,
	definicion_inicial: DefinicionItem,
	cantidad_inicial: int = 1
) -> void:
	_id_instancia = id_inicial
	_definicion = definicion_inicial
	_cantidad = cantidad_inicial
	if _definicion is DefinicionAntorcha and _cantidad > 0 and _cantidad <= _definicion.cantidad_maxima:
		pasos_antorchas.resize(_cantidad)
		pasos_antorchas.fill(obtener_duracion_antorcha())


func es_valida() -> bool:
	return (
		_id_instancia != &""
		and _definicion != null
		and _definicion.es_valida()
		and _cantidad >= 1
		and _cantidad <= _definicion.cantidad_maxima
		and (_definicion.apilable or _cantidad == 1)
		and validar_pasos_antorchas(pasos_antorchas)
	)


func _establecer_cantidad(nueva_cantidad: int) -> void:
	if _definicion is DefinicionAntorcha:
		if nueva_cantidad < _cantidad:
			pasos_antorchas = pasos_antorchas.slice(_cantidad - nueva_cantidad)
		else:
			for indice in range(_cantidad, nueva_cantidad):
				pasos_antorchas.append(obtener_duracion_antorcha())
	_cantidad = nueva_cantidad


func obtener_duracion_antorcha() -> int:
	return int(_definicion.magnitudes.get(&"duracion", 80.0))


func crear_porcion(nuevo_id: StringName, unidades: int) -> ItemInstancia:
	var porcion := ItemInstancia.new(nuevo_id, _definicion, unidades)
	porcion.pasos_antorchas = pasos_antorchas.slice(0, unidades)
	return porcion


func validar_pasos_antorchas(datos: Variant) -> bool:
	if not datos is Array:
		return false
	if not _definicion is DefinicionAntorcha:
		return datos.is_empty()
	if datos.size() != _cantidad:
		return false
	for pasos: Variant in datos:
		if not (pasos is int or (pasos is float and is_finite(pasos) and pasos == floor(pasos))):
			return false
		if pasos < 1 or pasos > obtener_duracion_antorcha():
			return false
	return true


func restaurar_pasos_antorchas(datos: Array) -> void:
	pasos_antorchas.clear()
	for pasos: Variant in datos:
		pasos_antorchas.append(int(pasos))


func obtener_estado_persistente() -> Dictionary:
	var datos := {
		"id": String(id_instancia),
		"definicion_id": String(definicion.id_definicion),
		"definicion_path": definicion.resource_path,
		"cantidad": cantidad,
	}
	if not pasos_antorchas.is_empty():
		datos["pasos_antorchas"] = pasos_antorchas.duplicate()
	return datos


func obtener_peso_total() -> float:
	if _definicion != null:
		return _definicion.obtener_peso() * float(_cantidad)
	return 0.0
