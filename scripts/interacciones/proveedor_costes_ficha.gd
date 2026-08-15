class_name ProveedorCostesFicha
extends RefCounted

const COSTE_ENERGIA := &"energia"


func validar_costes(contexto: ContextoAccion) -> StringName:
	var ficha := contexto.actor as Ficha
	if ficha == null or not is_instance_valid(ficha):
		return &"actor_no_es_ficha"

	for clave in contexto.costes_solicitados:
		if clave != COSTE_ENERGIA:
			return &"coste_no_soportado"
		var cantidad := contexto.costes_solicitados[clave]
		if not is_equal_approx(cantidad, floorf(cantidad)):
			return &"coste_energia_no_entero"
		if cantidad > float(ficha.energia_actual):
			return &"costes_insuficientes"

	return &""


func consumir_costes(contexto: ContextoAccion) -> Variant:
	var motivo := validar_costes(contexto)
	if motivo != &"":
		return motivo

	var ficha := contexto.actor as Ficha
	var energia_solicitada: float = contexto.costes_solicitados.get(COSTE_ENERGIA, 0.0)
	var unidades_energia: int = roundi(energia_solicitada)
	ficha.energia_actual -= unidades_energia

	var costes_consumidos: Dictionary[StringName, float] = {}
	if energia_solicitada > 0.0:
		costes_consumidos[COSTE_ENERGIA] = float(unidades_energia)
	return costes_consumidos
