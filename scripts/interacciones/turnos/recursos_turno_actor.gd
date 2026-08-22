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
