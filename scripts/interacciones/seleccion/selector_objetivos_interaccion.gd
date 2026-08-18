class_name SelectorObjetivosInteraccion
extends RefCounted


func obtener_objetivos_perceptibles(
	tablero: TableroGrid,
	coordenada: Vector2i,
	actor: Object = null
) -> Array[Object]:
	var objetivos: Array[Object] = []
	if tablero == null or not tablero.es_celda_valida(coordenada):
		return objetivos

	var celda := tablero.obtener_celda(coordenada)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return objetivos

	for contenido in celda.interactuables + celda.items_suelo:
		if not is_instance_valid(contenido):
			continue
		if (
			not contenido.has_method(&"obtener_id_objetivo_interaccion")
			or not contenido.has_method(&"obtener_opciones_accion")
			or contenido.call(&"obtener_id_objetivo_interaccion") == &""
		):
			continue
		if contenido.call(&"obtener_opciones_accion", actor).is_empty():
			continue
		objetivos.append(contenido)

	objetivos.sort_custom(_ordenar_por_id_estable)
	return objetivos


func _ordenar_por_id_estable(
	izquierdo: Object,
	derecho: Object
) -> bool:
	return String(izquierdo.call(&"obtener_id_objetivo_interaccion")) < String(
		derecho.call(&"obtener_id_objetivo_interaccion")
	)
