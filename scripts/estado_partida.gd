extends Node

const CLASES_VALIDAS := ["Guerrero", "Ladrón", "Mago"]

var aventurero_pendiente: Dictionary = {}


func establecer_aventurero(datos: Dictionary) -> bool:
	if validar_aventurero(datos) != &"":
		return false
	aventurero_pendiente = datos.duplicate(true)
	return true


func consumir_aventurero() -> Dictionary:
	var datos := aventurero_pendiente
	aventurero_pendiente = {}
	return datos


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
