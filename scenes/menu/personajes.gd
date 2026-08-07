extends Control


func _on_personaje_pressed() -> void:
	pass # Replace with function body.


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")
