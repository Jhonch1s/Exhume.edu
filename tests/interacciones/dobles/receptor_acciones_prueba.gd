extends RefCounted

var fue_examinado: bool = false


func validar_accion(contexto: ContextoAccion) -> StringName:
	if contexto.tipo != TiposInteraccion.TipoAccion.EXAMINAR:
		return &"accion_no_admitida"
	if contexto.objetivo != self:
		return &"objetivo_no_coincide"
	return &""


func resolver_accion(_contexto: ContextoAccion) -> ResultadoAccion:
	var valor_anterior := fue_examinado
	fue_examinado = true
	var cambios: Array[Dictionary] = [{
		&"propiedad": &"fue_examinado",
		&"valor_anterior": valor_anterior,
		&"valor_nuevo": fue_examinado,
	}]
	return ResultadoAccion.crear_exito(
		[&"examinar.objetivo_observado"],
		[],
		cambios
	)
