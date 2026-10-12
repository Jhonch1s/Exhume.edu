@tool
extends BTAction

## Comunica la intención; el ejecutor del turno aplica movimiento o combate.
@export var decision: StringName


func _tick(_delta: float) -> Status:
	blackboard.set_var(&"decision", decision)
	var traza: Array = blackboard.get_var(&"traza", [])
	traza.append("Elegida: %s" % get_task_name())
	blackboard.set_var(&"traza", traza)
	return SUCCESS
