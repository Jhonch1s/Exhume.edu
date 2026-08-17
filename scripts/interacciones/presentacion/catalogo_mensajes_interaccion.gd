class_name CatalogoMensajesInteraccion
extends Resource

@export var mensajes: Dictionary = {}


func resolver(id_mensaje: StringName) -> String:
	var texto: Variant = mensajes.get(id_mensaje)
	if texto is String and not texto.is_empty():
		return texto
	return String(id_mensaje)


func es_valido() -> bool:
	for id_mensaje in mensajes:
		if not id_mensaje is StringName or id_mensaje == &"":
			return false
		var texto: Variant = mensajes[id_mensaje]
		if not texto is String or texto.is_empty():
			return false
	return true
