class_name FondoInventarioDrop
extends ColorRect


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var panel := get_parent() as PanelInventarioEquipo
	if panel != null:
		return panel._can_drop_data(at_position, data)
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var panel := get_parent() as PanelInventarioEquipo
	if panel != null:
		panel._drop_data(at_position, data)
