extends Node

const CLASES_VALIDAS := ["Guerrero", "Ladrón", "Mago"]

var aventurero_pendiente: Dictionary = {}
var trompo_conocido: bool = false


func establecer_aventurero(datos: Dictionary) -> bool:
	if validar_aventurero(datos) != &"":
		return false
	aventurero_pendiente = datos.duplicate(true)
	trompo_conocido = false
	return true


func consumir_aventurero() -> Dictionary:
	var datos := aventurero_pendiente
	aventurero_pendiente = {}
	return datos


func obtener_estado_persistente() -> Dictionary:
	return {"trompo_conocido": trompo_conocido}


func validar_estado_persistente(estado: Variant) -> StringName:
	if (
		not estado is Dictionary or estado.size() != 1
		or not estado.get("trompo_conocido") is bool
	):
		return &"memoria_narrativa_guardada_invalida"
	return &""


func restaurar_estado_persistente(estado: Variant) -> StringName:
	var motivo := validar_estado_persistente(estado)
	if motivo != &"":
		return motivo
	trompo_conocido = estado["trompo_conocido"]
	return &""


func validar_aventurero(datos: Dictionary) -> StringName:
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
