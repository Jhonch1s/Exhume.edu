class_name AdaptadorMenuContextual
extends RefCounted


func construir_entradas_acciones(
	opciones: Array[OpcionAccion],
	catalogo: CatalogoMensajesInteraccion
) -> Array[EntradaMenuContextual]:
	var opciones_visibles: Array[OpcionAccion] = []
	for opcion in opciones:
		if opcion == null or opcion.secreta:
			continue
		opciones_visibles.append(opcion)
	opciones_visibles.sort_custom(_ordenar_opciones)

	var entradas: Array[EntradaMenuContextual] = []
	for opcion in opciones_visibles:
		var motivo := ""
		if not opcion.habilitada:
			motivo = _resolver(catalogo, opcion.motivo_bloqueo)
		entradas.append(EntradaMenuContextual.desde_opcion(
			opcion,
			_resolver(catalogo, opcion.texto),
			motivo
		))
	entradas.append(EntradaMenuContextual.cancelar(
		_resolver(catalogo, &"interaccion.cancelar")
	))
	return entradas


func construir_entradas_objetivos(
	objetivos: Array[Interactuable],
	catalogo: CatalogoMensajesInteraccion
) -> Array[EntradaMenuContextual]:
	var objetivos_validos: Array[Interactuable] = []
	for objetivo in objetivos:
		if (
			objetivo == null
			or not is_instance_valid(objetivo)
			or objetivo.definicion == null
		):
			continue
		objetivos_validos.append(objetivo)
	objetivos_validos.sort_custom(_ordenar_objetivos)

	var entradas: Array[EntradaMenuContextual] = []
	for objetivo in objetivos_validos:
		entradas.append(EntradaMenuContextual.desde_objetivo(
			objetivo,
			objetivo.definicion.nombre
		))
	entradas.append(EntradaMenuContextual.cancelar(
		_resolver(catalogo, &"interaccion.cancelar")
	))
	return entradas


func _ordenar_opciones(izquierda: OpcionAccion, derecha: OpcionAccion) -> bool:
	if izquierda.prioridad != derecha.prioridad:
		return izquierda.prioridad < derecha.prioridad
	return String(izquierda.id) < String(derecha.id)


func _ordenar_objetivos(izquierdo: Interactuable, derecho: Interactuable) -> bool:
	return String(izquierdo.id_instancia) < String(derecho.id_instancia)


func _resolver(
	catalogo: CatalogoMensajesInteraccion,
	id_texto: StringName
) -> String:
	return catalogo.resolver(id_texto) if catalogo != null else String(id_texto)
