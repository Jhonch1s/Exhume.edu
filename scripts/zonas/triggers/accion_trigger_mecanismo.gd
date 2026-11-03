@tool
class_name AccionTriggerMecanismo
extends AccionTrigger

## ID de una puerta u otro receptor del contrato de mecanismos.
@export var id_receptor: StringName
@export var activar: bool = true


func validar_configuracion() -> String:
	return "Asigna el ID del receptor del mecanismo." if id_receptor == &"" else ""


func ejecutar(escenario: Node, trigger: TriggerMapa) -> StringName:
	var receptor: Interactuable = escenario.tablero.obtener_interactuable(id_receptor)
	if receptor == null:
		return &"receptor_mecanismo_inexistente"
	if not receptor.has_method(&"validar_cambio_mecanismo") or not receptor.has_method(&"aplicar_cambio_mecanismo"):
		return &"receptor_mecanismo_incompatible"
	var motivo: Variant = receptor.call(&"validar_cambio_mecanismo", trigger.id_trigger, activar)
	if not motivo is StringName:
		return &"contrato_receptor_mecanismo_invalido"
	if motivo != &"":
		return motivo
	var resultado: Variant = receptor.call(&"aplicar_cambio_mecanismo", trigger.id_trigger, activar)
	if not resultado is ResultadoAccion:
		return &"resultado_receptor_mecanismo_invalido"
	return &"" if resultado.exitosa else resultado.motivo
