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
