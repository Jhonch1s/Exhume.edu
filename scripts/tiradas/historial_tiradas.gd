class_name HistorialTiradas
extends RefCounted

var _entradas: Array[String] = []


func registrar(resultado: Variant) -> bool:
	if resultado is ResultadoPrueba and resultado.valida:
		_entradas.append(_formatear_prueba(resultado))
		return true
	if resultado is ResultadoTirada and resultado.valida:
		_entradas.append(_formatear_cantidad(resultado))
		return true
	return false


func obtener_entradas() -> Array[String]:
	return _entradas.duplicate()


func limpiar() -> void:
	_entradas.clear()


func _formatear_prueba(resultado: ResultadoPrueba) -> String:
	return "%s | %s | dados=%s seleccionado=%d atributo=%d | %s | %s | ventaja=%s desventaja=%s" % [
		_nombre(TiposTirada.Origen, resultado.origen),
		_nombre(TiposTirada.Presentacion, resultado.presentacion),
		str(resultado.dados),
		resultado.dado_seleccionado,
		resultado.atributo,
		_nombre(ResultadoPrueba.Clasificacion, resultado.clasificacion),
		"EXITO" if resultado.exitosa else "FALLO",
		_formatear_fuentes(resultado.fuentes_ventaja),
		_formatear_fuentes(resultado.fuentes_desventaja),
	]


func _formatear_cantidad(resultado: ResultadoTirada) -> String:
	return "%s | %s | terminos=%s | total=%d efectivo=%d" % [
		_nombre(TiposTirada.Origen, resultado.origen),
		_nombre(TiposTirada.Presentacion, resultado.presentacion),
		_formatear_terminos(resultado.terminos),
		resultado.total_calculado,
		resultado.total_efectivo,
	]


func _nombre(catalogo: Dictionary, valor: int) -> String:
	for nombre: String in catalogo:
		if catalogo[nombre] == valor:
			return nombre
	return "DESCONOCIDO"


func _formatear_fuentes(fuentes: Array[StringName]) -> String:
	var nombres: Array[String] = []
	for fuente in fuentes:
		nombres.append(String(fuente))
	return "[" + ", ".join(nombres) + "]"


func _formatear_terminos(terminos: Array[Dictionary]) -> String:
	var partes: Array[String] = []
	for termino in terminos:
		partes.append("%s%dd%d=%s" % [
			"+" if termino[&"signo"] > 0 else "-",
			termino[&"cantidad"],
			termino[&"caras"],
			str(termino[&"resultados"]),
		])
	return " ".join(partes)
