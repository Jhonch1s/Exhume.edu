extends RefCounted

var recursos: Dictionary[StringName, float]


func _init(recursos_iniciales: Dictionary[StringName, float] = {}) -> void:
	recursos = recursos_iniciales.duplicate()


func validar_costes(contexto: ContextoAccion) -> StringName:
	for clave in contexto.costes_solicitados:
		if recursos.get(clave, 0.0) < contexto.costes_solicitados[clave]:
			return &"costes_insuficientes"
	return &""


func consumir_costes(contexto: ContextoAccion) -> Dictionary[StringName, float]:
	var costes_consumidos: Dictionary[StringName, float] = {}
	for clave in contexto.costes_solicitados:
		var cantidad := contexto.costes_solicitados[clave]
		recursos[clave] = recursos.get(clave, 0.0) - cantidad
		costes_consumidos[clave] = cantidad
	return costes_consumidos
