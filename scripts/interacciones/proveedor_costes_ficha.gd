class_name ProveedorCostesFicha
extends RefCounted

const COSTE_ENERGIA := &"energia"


func validar_costes(contexto: ContextoAccion) -> StringName:
	var ficha := contexto.actor as Ficha
	if ficha == null or not is_instance_valid(ficha):
		return &"actor_no_es_ficha"

	for clave in contexto.costes_solicitados:
		var cantidad := contexto.costes_solicitados[clave]
		if not is_equal_approx(cantidad, floorf(cantidad)):
			return &"coste_energia_no_entero" if clave == COSTE_ENERGIA else &"coste_no_entero"
		if clave == COSTE_ENERGIA:
			if cantidad > float(ficha.energia_actual):
				return &"costes_insuficientes"
			continue
		var motivo := ficha.validar_coste_turno(clave, roundi(cantidad))
		if motivo == &"recurso_turno_no_soportado":
			return &"coste_no_soportado"
		if motivo != &"":
			return motivo

	return &""


func consumir_costes(contexto: ContextoAccion) -> Variant:
	var motivo := validar_costes(contexto)
	if motivo != &"":
		return motivo

	var ficha := contexto.actor as Ficha
	var costes_consumidos: Dictionary[StringName, float] = {}
	for clave in contexto.costes_solicitados:
		var unidades := roundi(contexto.costes_solicitados[clave])
		if clave == COSTE_ENERGIA:
			ficha.energia_actual -= unidades
		elif not ficha.consumir_recurso_turno(clave, unidades):
			return &"consumo_costes_invalido"
		if unidades > 0:
			costes_consumidos[clave] = float(unidades)
	return costes_consumidos
