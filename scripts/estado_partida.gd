extends Node

const CLASES_VALIDAS := ["Guerrero", "Ladrón", "Mago"]

var aventurero_pendiente: Dictionary = {}
var trompo_conocido: bool = false
var roffa_conocido: bool = false
var prision_derrumbe_visto: bool = false
var guardado_en_fogata_realizado: bool = false
var _triggers_consumidos: Dictionary = {}


func establecer_aventurero(datos: Dictionary) -> bool:
	if validar_aventurero(datos) != &"":
		return false
	aventurero_pendiente = datos.duplicate(true)
	trompo_conocido = false
	roffa_conocido = false
	prision_derrumbe_visto = false
	guardado_en_fogata_realizado = false
	_triggers_consumidos.clear()
	return true


func consumir_aventurero() -> Dictionary:
	var datos := aventurero_pendiente
	aventurero_pendiente = {}
	return datos


func obtener_estado_persistente() -> Dictionary:
	return {
		"trompo_conocido": trompo_conocido,
		"roffa_conocido": roffa_conocido,
		"prision_derrumbe_visto": prision_derrumbe_visto,
		"triggers_consumidos": _triggers_consumidos.duplicate(true),
	}


func trigger_consumido(id_zona: StringName, id_trigger: StringName) -> bool:
	return _triggers_consumidos.get(String(id_zona), []).has(String(id_trigger))


func consumir_trigger(id_zona: StringName, id_trigger: StringName) -> void:
	if id_zona == &"" or id_trigger == &"" or trigger_consumido(id_zona, id_trigger):
		return
	var zona := String(id_zona)
	if not _triggers_consumidos.has(zona):
		_triggers_consumidos[zona] = []
	_triggers_consumidos[zona].append(String(id_trigger))
	_triggers_consumidos[zona].sort()


func validar_estado_persistente(estado: Variant) -> StringName:
	if (
		not estado is Dictionary
		or not estado.get("trompo_conocido") is bool
	):
		return &"memoria_narrativa_guardada_invalida"
	for clave in estado:
		if clave not in ["trompo_conocido", "roffa_conocido", "prision_derrumbe_visto", "triggers_consumidos"]:
			return &"memoria_narrativa_guardada_invalida"
	for clave in ["roffa_conocido", "prision_derrumbe_visto"]:
		if estado.has(clave) and not estado[clave] is bool:
			return &"memoria_narrativa_guardada_invalida"
	var triggers: Variant = estado.get("triggers_consumidos", {})
	if not triggers is Dictionary:
		return &"triggers_guardados_invalidos"
	for zona in triggers:
		if not zona is String or zona.is_empty() or not triggers[zona] is Array:
			return &"triggers_guardados_invalidos"
		var vistos: Dictionary = {}
		for id in triggers[zona]:
			if not id is String or id.is_empty() or vistos.has(id):
				return &"triggers_guardados_invalidos"
			vistos[id] = true
	return &""


func restaurar_estado_persistente(estado: Variant) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	trompo_conocido = estado["trompo_conocido"]
	roffa_conocido = estado.get("roffa_conocido", false)
	prision_derrumbe_visto = estado.get("prision_derrumbe_visto", false)
	_triggers_consumidos = estado.get("triggers_consumidos", {}).duplicate(true)
	return &""


static func validar_aventurero(datos: Dictionary) -> StringName:
	if (
		not datos.get("nombre") is String or datos["nombre"].strip_edges().is_empty()
		or not datos.get("titulo") is String or datos["titulo"].strip_edges().is_empty()
		or not datos.get("clase") is String or datos["clase"] not in CLASES_VALIDAS
		or not datos.get("origen") is String or datos["origen"].is_empty()
	):
		return &"identidad_aventurero_invalida"
	for atributo in ["fuerza", "destreza", "voluntad"]:
		if not datos.get(atributo) is int or datos[atributo] < 2 or datos[atributo] > 5:
			return &"atributos_aventurero_invalidos"
	return &""
