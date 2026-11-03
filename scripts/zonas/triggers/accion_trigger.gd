@tool
class_name AccionTrigger
extends Resource


func validar_configuracion() -> String:
	return "La acción debe ser un tipo concreto de AccionTrigger."


func ejecutar(_escenario: Node, _trigger: TriggerMapa) -> StringName:
	return &"accion_trigger_no_implementada"
