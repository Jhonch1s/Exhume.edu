class_name RegistroNarrativoSesion
extends RefCounted

signal entrada_agregada(entrada: EntradaRegistroNarrativo)

var _entradas: Array[EntradaRegistroNarrativo] = []


func registrar(
	categoria: EntradaRegistroNarrativo.Categoria,
	titulo: String,
	mensaje: String,
	detalles: Array[String] = [],
	visibilidad: EntradaRegistroNarrativo.Visibilidad = EntradaRegistroNarrativo.Visibilidad.VISIBLE
) -> EntradaRegistroNarrativo:
	var entrada := EntradaRegistroNarrativo.new(
		_entradas.size() + 1, categoria, titulo, mensaje, detalles, visibilidad
	)
	_entradas.append(entrada)
	entrada_agregada.emit(entrada)
	return entrada


func obtener_entradas_visibles() -> Array[EntradaRegistroNarrativo]:
	return _entradas.filter(func(entrada):
		return entrada.visibilidad == EntradaRegistroNarrativo.Visibilidad.VISIBLE
	).duplicate()


func limpiar() -> void:
	_entradas.clear()
