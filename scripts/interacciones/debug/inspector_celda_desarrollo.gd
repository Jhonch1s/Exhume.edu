class_name InspectorCeldaDesarrollo
extends RefCounted


func describir(tablero: TableroGrid, coordenada: Vector2i) -> String:
	if tablero == null or not tablero.es_celda_valida(coordenada):
		return "[CELDA] coord=%s inexistente" % coordenada
	var celda := tablero.obtener_celda(coordenada)
	return (
		"[CELDA] coord=%s zona=%s altura=%d visibilidad=%s "
		+ "caminable=%s/%s vision=%s/%s proyectiles=%s coste=%d peso_ruta=%s\n"
		+ "  ocupantes=%s reservas=%s\n"
		+ "  interactuables=%s items=%s\n"
		+ "  superficies=%s iluminacion=%s terreno=%s"
	) % [
		coordenada,
		celda.zona,
		celda.altura,
		_nombre_visibilidad(celda.visibilidad),
		celda.caminable,
		celda.es_caminable_efectiva(),
		celda.bloquea_vision,
		celda.bloquea_vision_efectiva(),
		celda.bloquea_proyectiles_efectiva(),
		celda.calcular_coste_movimiento(),
		celda.calcular_peso_ruta(),
		_ids(celda.ocupantes),
		_ids(celda.reservas),
		_ids(celda.interactuables),
		_ids(celda.items_suelo),
		_superficies(celda.efectos_superficie),
		_ids(celda.iluminacion),
		_id(celda.reaccion_terreno),
	]


func _ids(contenidos: Array[Object]) -> String:
	var ids: Array[String] = []
	for contenido in contenidos:
		ids.append(_id(contenido))
	ids.sort()
	return "[" + ", ".join(ids) + "]"


func _superficies(superficies: Array[Object]) -> String:
	var datos: Array[String] = []
	for superficie in superficies:
		var texto := _id(superficie)
		if superficie != null and superficie.has_method(&"obtener_turnos_restantes_superficie"):
			texto += "(turnos=%s)" % superficie.call(&"obtener_turnos_restantes_superficie")
		datos.append(texto)
	datos.sort()
	return "[" + ", ".join(datos) + "]"


func _id(contenido: Object) -> String:
	if contenido == null or not is_instance_valid(contenido):
		return "invalido"
	for metodo in [
		&"obtener_id_objetivo_interaccion",
		&"obtener_id_actor",
		&"obtener_id_reaccion",
	]:
		if contenido.has_method(metodo):
			var valor: Variant = contenido.call(metodo)
			if valor is StringName and valor != &"":
				return String(valor)
	if contenido is Node:
		return String((contenido as Node).name)
	return contenido.get_class()


func _nombre_visibilidad(visibilidad: int) -> String:
	var nombres := Celda.EstadoVisibilidad.keys()
	return String(nombres[visibilidad]) if visibilidad >= 0 and visibilidad < nombres.size() else "DESCONOCIDA"
