@tool
extends BTCondition

## Lee una condición de la memoria compartida y registra su evaluación.
@export var variable: StringName


func _tick(_delta: float) -> Status:
	var se_cumple: bool = blackboard.get_var(variable, false)
	var traza: Array = blackboard.get_var(&"traza", [])
	traza.append("%s → %s" % [get_task_name(), "Sí" if se_cumple else "No"])
	blackboard.set_var(&"traza", traza)
	return SUCCESS if se_cumple else FAILURE
