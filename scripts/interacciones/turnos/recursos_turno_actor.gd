class_name RecursosTurnoActor
extends RefCounted

const MOVIMIENTO := &"movimiento"
const ACCION_PRINCIPAL := &"accion_principal"
const ACCION_ADICIONAL := &"accion_adicional"
const REACCION := &"reaccion"

var _maximos: Dictionary[StringName, int]
var _restantes: Dictionary[StringName, int]


func _init(
	movimiento: int = 7,
	acciones_principales: int = 1,
	acciones_adicionales: int = 1,
	reacciones: int = 1
) -> void:
	_maximos = {
		MOVIMIENTO: maxi(0, movimiento),
		ACCION_PRINCIPAL: maxi(0, acciones_principales),
		ACCION_ADICIONAL: maxi(0, acciones_adicionales),
		REACCION: maxi(0, reacciones),
	}
	reponer()


func reponer() -> void:
	_restantes = _maximos.duplicate()


func obtener(clave: StringName) -> int:
	return _restantes.get(clave, -1)


func obtener_maximo(clave: StringName) -> int:
	return _maximos.get(clave, -1)


func obtener_restantes() -> Dictionary:
	return _restantes.duplicate()


func validar_restauracion(restantes: Dictionary) -> StringName:
	if restantes.size() != _maximos.size():
		return &"recursos_turno_guardados_invalidos"
	for clave in _maximos:
		if (
			not restantes.has(String(clave))
			or not _es_numero_entero(restantes[String(clave)])
			or restantes[String(clave)] < 0
			or restantes[String(clave)] > _maximos[clave]
		):
			return &"recursos_turno_guardados_invalidos"
	return &""


func restaurar(restantes: Dictionary) -> StringName:
	var motivo := validar_restauracion(restantes)
	if motivo != &"":
		return motivo
	for clave in _maximos:
		_restantes[clave] = int(restantes[String(clave)])
	return &""


func validar_consumo(clave: StringName, cantidad: int) -> StringName:
	if not _restantes.has(clave):
		return &"recurso_turno_no_soportado"
	if cantidad < 0:
		return &"coste_recurso_turno_invalido"
	if cantidad > _restantes[clave]:
		return &"recursos_turno_insuficientes"
	return &""


func consumir(clave: StringName, cantidad: int) -> bool:
	if validar_consumo(clave, cantidad) != &"":
		return false
	_restantes[clave] -= cantidad
	return true


func _es_numero_entero(valor: Variant) -> bool:
	return valor is int or (valor is float and is_equal_approx(valor, roundf(valor)))
