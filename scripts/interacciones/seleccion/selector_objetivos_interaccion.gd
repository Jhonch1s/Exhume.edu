class_name SelectorObjetivosInteraccion
extends RefCounted


func obtener_objetivos_perceptibles(
	tablero: TableroGrid,
	coordenada: Vector2i,
	actor: Object = null,
	punto_global: Variant = null
) -> Array[Object]:
	var objetivos: Array[Object] = []
	if tablero == null:
		return objetivos

	var candidatos: Array[Object] = []
	var celda := tablero.obtener_celda(coordenada)
	if celda != null and celda.visibilidad == Celda.EstadoVisibilidad.VISIBLE:
		for interactuable in celda.interactuables:
			if not is_instance_valid(interactuable):
				continue
			# Los personajes y otros visuales altos se seleccionan por su sprite,
			# incluso cuando este sobresale de la celda que ocupan.
			if punto_global is Vector2 and interactuable.has_method(&"contiene_punto_visual"):
				continue
			candidatos.append(interactuable)
		if not punto_global is Vector2:
			candidatos.append_array(celda.items_suelo)

	if punto_global is Vector2:
		for interactuable in tablero.interactuables_por_id.values():
			if not is_instance_valid(interactuable):
				continue
			if not interactuable.has_method(&"contiene_punto_visual"):
				continue
			var celda_interactuable := tablero.obtener_celda(interactuable.coordenada_mapa)
			if (
				celda_interactuable != null
				and celda_interactuable.visibilidad == Celda.EstadoVisibilidad.VISIBLE
				and interactuable.call(&"contiene_punto_visual", punto_global)
				and interactuable not in candidatos
			):
				candidatos.append(interactuable)
		# ponytail: recorrido lineal; usar indice espacial solo si la cantidad de items lo exige.
		for item_suelo in tablero.items_suelo_por_id.values():
			var celda_item := tablero.obtener_celda(item_suelo.coordenada_mapa)
			if (
				celda_item != null
				and celda_item.visibilidad == Celda.EstadoVisibilidad.VISIBLE
				and item_suelo.contiene_punto_visual(punto_global)
			):
				candidatos.append(item_suelo)

	for contenido in candidatos:
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
		if contenido not in objetivos:
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
