class_name RegistroConocimiento
extends RefCounted

var _descubrimientos: Dictionary[StringName, Dictionary] = {}


func registrar_descubrimientos(
	id_observador: StringName,
	id_objetivo: StringName,
	fragmentos: Array[FragmentoInformacion]
) -> ResultadoRegistroConocimiento:
	var motivo := validar_registro(id_observador, id_objetivo, fragmentos)
	if motivo != &"":
		return ResultadoRegistroConocimiento.crear_fallo(motivo)

	var por_objetivo: Dictionary = _descubrimientos.get(id_observador, {})
	var conocidos: Dictionary = por_objetivo.get(id_objetivo, {})
	var ids_nuevos: Array[StringName] = []
	for fragmento in fragmentos:
		if not fragmento.se_recuerda or conocidos.has(fragmento.id_fragmento):
			continue
		conocidos[fragmento.id_fragmento] = true
		ids_nuevos.append(fragmento.id_fragmento)

	if not ids_nuevos.is_empty():
		por_objetivo[id_objetivo] = conocidos
		_descubrimientos[id_observador] = por_objetivo
	return ResultadoRegistroConocimiento.crear_exito(ids_nuevos)


func validar_registro(
	id_observador: StringName,
	id_objetivo: StringName,
	fragmentos: Array[FragmentoInformacion]
) -> StringName:
	if id_observador == &"":
		return &"id_observador_vacio"
	if id_objetivo == &"":
		return &"id_objetivo_vacio"

	var ids_vistos: Dictionary[StringName, bool] = {}
	for fragmento in fragmentos:
		if fragmento == null or not fragmento.es_valido():
			return &"fragmentos_descubrimiento_invalidos"
		if ids_vistos.has(fragmento.id_fragmento):
			return &"fragmentos_descubrimiento_duplicados"
		ids_vistos[fragmento.id_fragmento] = true
	return &""


func conoce_fragmento(
	id_observador: StringName,
	id_objetivo: StringName,
	id_fragmento: StringName
) -> bool:
	if id_observador == &"" or id_objetivo == &"" or id_fragmento == &"":
		return false
	var por_objetivo: Dictionary = _descubrimientos.get(id_observador, {})
	var conocidos: Dictionary = por_objetivo.get(id_objetivo, {})
	return conocidos.has(id_fragmento)


func obtener_ids_conocidos(
	id_observador: StringName,
	id_objetivo: StringName
) -> Array[StringName]:
	var ids: Array[StringName] = []
	if id_observador == &"" or id_objetivo == &"":
		return ids
	var por_objetivo: Dictionary = _descubrimientos.get(id_observador, {})
	var conocidos: Dictionary = por_objetivo.get(id_objetivo, {})
	for id_fragmento in conocidos:
		ids.append(id_fragmento)
	ids.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			return String(a) < String(b)
	)
	return ids


func obtener_estado_persistente() -> Array[Dictionary]:
	var entradas: Array[Dictionary] = []
	var observadores: Array[StringName] = []
	observadores.assign(_descubrimientos.keys())
	observadores.sort_custom(func(a, b): return String(a) < String(b))
	for id_observador in observadores:
		var objetivos: Array[StringName] = []
		objetivos.assign((_descubrimientos[id_observador] as Dictionary).keys())
		objetivos.sort_custom(func(a, b): return String(a) < String(b))
		for id_objetivo in objetivos:
			var fragmentos: Array[String] = []
			for id_fragmento in obtener_ids_conocidos(id_observador, id_objetivo):
				fragmentos.append(String(id_fragmento))
			entradas.append({
				"observador_id": String(id_observador),
				"objetivo_id": String(id_objetivo),
				"fragmentos": fragmentos,
			})
	return entradas


func validar_estado_persistente(entradas: Variant) -> StringName:
	if not entradas is Array:
		return &"conocimiento_guardado_invalido"
	var pares: Dictionary[String, bool] = {}
	for entrada: Variant in entradas:
		if not entrada is Dictionary:
			return &"conocimiento_guardado_invalido"
		var observador: Variant = entrada.get("observador_id")
		var objetivo: Variant = entrada.get("objetivo_id")
		var fragmentos: Variant = entrada.get("fragmentos")
		if (
			not observador is String or observador.is_empty()
			or not objetivo is String or objetivo.is_empty()
			or not fragmentos is Array or fragmentos.is_empty()
		):
			return &"conocimiento_guardado_invalido"
		var par := "%s\n%s" % [observador, objetivo]
		if pares.has(par):
			return &"conocimiento_guardado_duplicado"
		pares[par] = true
		var vistos: Dictionary[String, bool] = {}
		for fragmento: Variant in fragmentos:
			if not fragmento is String or fragmento.is_empty() or vistos.has(fragmento):
				return &"conocimiento_guardado_invalido"
			vistos[fragmento] = true
	return &""


func restaurar_estado_persistente(entradas: Variant) -> StringName:
	var motivo := validar_estado_persistente(entradas)
	if motivo != &"":
		return motivo
	var restaurados: Dictionary[StringName, Dictionary] = {}
	for entrada: Dictionary in entradas:
		var id_observador := StringName(entrada["observador_id"])
		var id_objetivo := StringName(entrada["objetivo_id"])
		var por_objetivo: Dictionary = restaurados.get(id_observador, {})
		var conocidos: Dictionary[StringName, bool] = {}
		for fragmento: String in entrada["fragmentos"]:
			conocidos[StringName(fragmento)] = true
		por_objetivo[id_objetivo] = conocidos
		restaurados[id_observador] = por_objetivo
	_descubrimientos = restaurados
	return &""
