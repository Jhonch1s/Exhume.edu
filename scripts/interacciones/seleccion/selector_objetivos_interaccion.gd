class_name SelectorObjetivosInteraccion
extends RefCounted


func obtener_objetivos_perceptibles(
	tablero: TableroGrid,
	coordenada: Vector2i,
	actor: Object = null
) -> Array[Interactuable]:
	var objetivos: Array[Interactuable] = []
	if tablero == null or not tablero.es_celda_valida(coordenada):
		return objetivos

	var celda := tablero.obtener_celda(coordenada)
	if celda == null or celda.visibilidad != Celda.EstadoVisibilidad.VISIBLE:
		return objetivos

	for contenido in celda.interactuables:
		if not contenido is Interactuable or not is_instance_valid(contenido):
			continue
		if contenido.id_instancia == &"":
			continue
		if contenido.obtener_opciones_accion(actor).is_empty():
			continue
		objetivos.append(contenido)

	objetivos.sort_custom(_ordenar_por_id_estable)
	return objetivos


func _ordenar_por_id_estable(
	izquierdo: Interactuable,
	derecho: Interactuable
) -> bool:
	return String(izquierdo.id_instancia) < String(derecho.id_instancia)
