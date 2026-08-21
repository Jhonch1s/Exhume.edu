class_name ConsultorReaccionesCelda
extends RefCounted


func obtener_reacciones(
	celda: Celda,
	tipo: TiposInteraccion.TipoAccion,
	actor: Object = null,
	objetivo_prioritario: Object = null,
	incluir_dirigidas: bool = false
) -> Array[ReaccionCelda]:
	if celda == null:
		return []

	var reacciones: Array[ReaccionCelda] = []
	_agregar_fuente(
		reacciones,
		celda.reaccion_terreno,
		TiposInteraccion.CategoriaReaccion.TERRENO,
		tipo,
		objetivo_prioritario,
		incluir_dirigidas
	)
	_agregar_coleccion(
		reacciones,
		celda.efectos_superficie,
		TiposInteraccion.CategoriaReaccion.EFECTO_SUPERFICIE,
		tipo,
		objetivo_prioritario,
		incluir_dirigidas
	)
	_agregar_coleccion(
		reacciones,
		celda.interactuables,
		TiposInteraccion.CategoriaReaccion.INTERACTUABLE,
		tipo,
		objetivo_prioritario,
		incluir_dirigidas
	)
	_agregar_coleccion(
		reacciones,
		celda.items_suelo,
		TiposInteraccion.CategoriaReaccion.ITEM_SUELO,
		tipo,
		objetivo_prioritario,
		incluir_dirigidas
	)
	for ocupante in celda.ocupantes.duplicate():
		if ocupante != actor:
			_agregar_fuente(
				reacciones,
				ocupante,
				TiposInteraccion.CategoriaReaccion.OCUPANTE,
				tipo,
				objetivo_prioritario,
				incluir_dirigidas
			)

	var fuentes_encadenadas_visitadas: Dictionary[int, bool] = {}
	for reaccion in reacciones.duplicate():
		_agregar_reacciones_encadenadas(
			reacciones,
			reaccion.receptor,
			tipo,
			fuentes_encadenadas_visitadas
		)

	reacciones.sort_custom(_comparar_reacciones)
	if objetivo_prioritario != null:
		for indice in reacciones.size():
			if reacciones[indice].receptor == objetivo_prioritario:
				reacciones.push_front(reacciones.pop_at(indice))
				break
	return reacciones


func _agregar_coleccion(
	destino: Array[ReaccionCelda],
	fuentes: Array[Object],
	categoria: TiposInteraccion.CategoriaReaccion,
	tipo: TiposInteraccion.TipoAccion,
	objetivo_dirigido: Object = null,
	incluir_dirigidas: bool = false
) -> void:
	for fuente in fuentes.duplicate():
		_agregar_fuente(
			destino,
			fuente,
			categoria,
			tipo,
			objetivo_dirigido,
			incluir_dirigidas
		)


func _agregar_fuente(
	destino: Array[ReaccionCelda],
	fuente: Object,
	categoria: TiposInteraccion.CategoriaReaccion,
	tipo: TiposInteraccion.TipoAccion,
	objetivo_dirigido: Object = null,
	incluir_dirigidas: bool = false
) -> void:
	if fuente == null or not is_instance_valid(fuente):
		return
	if (
		not fuente.has_method(&"reacciona_automaticamente")
		or not fuente.has_method(&"obtener_id_reaccion")
		or not fuente.has_method(&"obtener_prioridad_reaccion")
		or not fuente.has_method(&"validar_accion")
		or not fuente.has_method(&"resolver_accion")
	):
		return
	var admite: Variant = fuente.call(&"reacciona_automaticamente", tipo)
	var admite_dirigida := false
	if fuente.has_method(&"admite_reaccion_dirigida"):
		var valor: Variant = fuente.call(&"admite_reaccion_dirigida", tipo)
		admite_dirigida = valor is bool and valor
	var id_reaccion: Variant = fuente.call(&"obtener_id_reaccion")
	var prioridad: Variant = fuente.call(&"obtener_prioridad_reaccion", tipo)
	if (
		not admite is bool
		or (
			not admite
			and not (
				admite_dirigida
				and (incluir_dirigidas or fuente == objetivo_dirigido)
			)
		)
		or not id_reaccion is StringName
		or id_reaccion == &""
		or not prioridad is int
	):
		return
	destino.append(ReaccionCelda.new(categoria, prioridad, id_reaccion, fuente))


func _agregar_reacciones_encadenadas(
	destino: Array[ReaccionCelda],
	fuente: Object,
	tipo: TiposInteraccion.TipoAccion,
	visitadas: Dictionary[int, bool]
) -> void:
	if fuente == null or not is_instance_valid(fuente):
		return
	var id_fuente := fuente.get_instance_id()
	if visitadas.has(id_fuente):
		return
	visitadas[id_fuente] = true
	if not fuente.has_method(&"obtener_reacciones_encadenadas"):
		return
	var encadenadas: Variant = fuente.call(&"obtener_reacciones_encadenadas", tipo)
	if not encadenadas is Array:
		return
	for encadenada in encadenadas:
		if (
			encadenada == null
			or not is_instance_valid(encadenada)
			or visitadas.has(encadenada.get_instance_id())
		):
			continue
		var cantidad_anterior := destino.size()
		_agregar_fuente(
			destino,
			encadenada,
			TiposInteraccion.CategoriaReaccion.INTERACTUABLE,
			tipo
		)
		if destino.size() > cantidad_anterior:
			_agregar_reacciones_encadenadas(destino, encadenada, tipo, visitadas)


func _comparar_reacciones(a: ReaccionCelda, b: ReaccionCelda) -> bool:
	if a.categoria != b.categoria:
		return a.categoria < b.categoria
	if a.prioridad != b.prioridad:
		return a.prioridad < b.prioridad
	return String(a.id_estable) < String(b.id_estable)
